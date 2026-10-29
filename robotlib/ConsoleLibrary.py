"""Text consoles for Robot Framework: a process on a pty (QEMU running Zephyr, a host tool) or a serial port.

One API for every target, so the same test runs against ``scripts/app run shell qemu_cortex_m3`` and a board
on ``/dev/ttyACM0``::

    Library    ConsoleLibrary    timeout=20
    Start Console    qemu-system-arm    -M    lm3s6965evb    -nographic    -kernel    zephyr.elf
    Open Serial Console    /dev/ttyACM0    115200    alias=board
    Wait For Line    Booting Zephyr OS
    ${out}=    Run Shell Command    kernel version
    Should Not See    FATAL ERROR    for=2s

Every console keeps a transcript; it goes to the log when the console is closed.
"""
import os
import re
import signal
import time

import pexpect
import pexpect.fdpexpect
from robot.api import logger
from robot.api.deco import keyword, library
from robot.utils import timestr_to_secs

__version__ = "1.0.0"


class _Console:
    def __init__(self, child, name, serial_port=None):
        self.child = child
        self.name = name
        self.serial_port = serial_port   # pyserial object, closed with the console
        self.transcript = []

    def read_log(self):
        text = (self.child.before or "") + (self.child.after if isinstance(self.child.after, str) else "")
        self.transcript.append(text)
        return text


@library(scope="SUITE", auto_keywords=False)
class ConsoleLibrary:
    """Consoles of processes (on a pty) and serial ports: wait for lines, write lines, run shell commands.

    ``timeout`` (default 10 s) is the default for every wait. ``line_end`` is sent after each written
    line (Zephyr shell: ``\\n``). ``char_delay`` pauses between characters, for UARTs without flow control.
    """

    def __init__(self, timeout="10s", line_end="\n", char_delay="0", prompt="uart:~$ "):
        self._timeout = timestr_to_secs(timeout)
        self._line_end = line_end.encode().decode("unicode_escape")
        self._char_delay = timestr_to_secs(char_delay)
        self._prompt = prompt
        self._consoles = {}
        self._current = None

    # ---------- opening and closing ----------
    @keyword
    def start_console(self, command, *args, alias=None, cwd=None, timeout=None):
        """Starts ``command`` with ``args`` on a pseudo terminal and makes it the current console.

        The process gets its own session, so `Stop Console` ends it with everything it started
        (``west build -t run`` -> ninja -> qemu). Returns the alias.
        """
        child = pexpect.spawn(command, list(args), cwd=cwd, encoding="utf-8", codec_errors="replace",
                              timeout=self._secs(timeout), echo=False, dimensions=(50, 250))
        return self._add(_Console(child, alias or os.path.basename(command)))

    @keyword
    def open_serial_console(self, port, baudrate=115200, alias=None, timeout=None):
        """Opens serial ``port`` (``/dev/ttyACM0``, a pty, ``rfc2217://host:port``) as the current console."""
        import serial   # pyserial: only needed for serial consoles

        ser = serial.serial_for_url(port, baudrate=int(baudrate), timeout=0)
        child = pexpect.fdpexpect.fdspawn(ser.fileno(), encoding="utf-8", codec_errors="replace",
                                          timeout=self._secs(timeout))
        return self._add(_Console(child, alias or port, serial_port=ser))

    @keyword
    def switch_console(self, alias):
        """Makes the console ``alias`` the current one."""
        if alias not in self._consoles:
            raise AssertionError(f"no console '{alias}' (have: {', '.join(self._consoles) or 'none'})")
        self._current = alias

    @keyword
    def stop_console(self, alias=None):
        """Ends the current (or the named) console: the process group is terminated, a serial port closed."""
        name = alias or self._current
        con = self._consoles.pop(name, None)
        if con is None:
            return
        try:   # what is left in the buffer goes to the transcript
            con.child.expect(pexpect.TIMEOUT, timeout=0.1)
        except (pexpect.EOF, OSError, ValueError):
            pass
        con.read_log()
        if con.serial_port is not None:
            con.serial_port.close()
        else:
            self._kill(con.child)
        logger.info(f"console {name} transcript:\n{''.join(con.transcript)}")
        if self._current == name:
            self._current = next(iter(self._consoles), None)

    @keyword
    def stop_all_consoles(self):
        """Ends every console (use it in Suite Teardown)."""
        for name in list(self._consoles):
            self.stop_console(name)

    # ---------- reading ----------
    @keyword
    def wait_for_line(self, text, timeout=None, regex=False):
        """Waits until ``text`` shows up on the current console and returns the whole line that has it.

        With ``regex=True`` ``text`` is a Python regular expression (matched inside a line).
        """
        con = self._con()
        pattern = re.compile(r"[^\r\n]*" + (text if _true(regex) else re.escape(text)) + r"[^\r\n]*")
        self._expect(con, pattern, timeout, f"line with '{text}'")
        return con.child.after.strip()

    @keyword
    def wait_for_prompt(self, prompt=None, timeout=None):
        """Waits for ``prompt`` (default: the library's ``prompt``) which has no line end after it."""
        con = self._con()
        self._expect(con, re.compile(re.escape(prompt or self._prompt)), timeout, f"prompt '{prompt or self._prompt}'")

    @keyword
    def should_not_see(self, text, duration="1s", regex=False):
        """Reads the console for ``duration`` and fails when ``text`` appears (a crash banner, an error)."""
        con = self._con()
        pattern = re.compile(text if _true(regex) else re.escape(text))
        try:
            con.child.expect(pattern, timeout=timestr_to_secs(duration))
        except pexpect.TIMEOUT:
            con.read_log()
            return
        except pexpect.EOF:
            con.read_log()
            return
        con.read_log()
        raise AssertionError(f"'{text}' appeared on {con.name}: {con.child.after!r}")

    @keyword
    def console_output(self):
        """Returns everything read from the current console so far."""
        return "".join(self._con().transcript)

    # ---------- writing ----------
    @keyword
    def write_line(self, text):
        """Writes ``text`` and the line end to the current console."""
        con = self._con()
        data = text + self._line_end
        if self._char_delay:
            for ch in data:
                con.child.send(ch)
                time.sleep(self._char_delay)
        else:
            con.child.send(data)

    @keyword
    def run_shell_command(self, command, prompt=None, timeout=None):
        """Writes ``command``, waits for the next prompt and returns the lines in between (no echo, no prompt).

        Made for the Zephyr shell (``uart:~$``); any prompt-based shell works with ``prompt=``.
        """
        con = self._con()
        prompt = prompt or self._prompt
        self._drain(con)   # a prompt still in the buffer would end the wait before the answer
        self.write_line(command)
        self._expect(con, re.compile(re.escape(prompt)), timeout, f"prompt after '{command}'")
        lines = [ln for ln in re.split(r"\r?\n", con.child.before.replace("\x1b[m", "")) if ln.strip()]
        lines = [_strip_ansi(ln).rstrip() for ln in lines]
        if lines and lines[0].rstrip().endswith(command):   # the shell's echo of the command
            lines = lines[1:]
        return "\n".join(lines)

    # ---------- helpers ----------
    def _add(self, con):
        if con.name in self._consoles:
            raise AssertionError(f"console '{con.name}' is already open: give another alias")
        self._consoles[con.name] = con
        self._current = con.name
        return con.name

    def _con(self):
        if self._current is None:
            raise AssertionError("no console open: Start Console or Open Serial Console first")
        return self._consoles[self._current]

    @staticmethod
    def _drain(con, quiet=0.05):
        """Reads whatever is pending until the console is quiet for ``quiet`` seconds."""
        while True:
            try:
                con.child.expect(r"[\s\S]+", timeout=quiet)
            except (pexpect.TIMEOUT, pexpect.EOF):
                return
            con.read_log()

    def _secs(self, timeout):
        return self._timeout if timeout in (None, "", "None") else timestr_to_secs(timeout)

    def _expect(self, con, pattern, timeout, what):
        t = self._secs(timeout)
        try:
            con.child.expect(pattern, timeout=t)
        except pexpect.TIMEOUT:
            con.read_log()
            raise AssertionError(f"{con.name}: no {what} within {t:g} s; last output:\n{_tail(con)}") from None
        except pexpect.EOF:
            con.read_log()
            raise AssertionError(f"{con.name}: ended before {what}; last output:\n{_tail(con)}") from None
        logger.debug(f"{con.name}: {con.read_log()!r}")

    @staticmethod
    def _kill(child):
        if not child.isalive():
            return
        for sig, wait in ((signal.SIGTERM, 3), (signal.SIGKILL, 2)):
            try:
                os.killpg(child.pid, sig)   # pexpect.spawn makes the child a session (and group) leader
            except ProcessLookupError:
                return
            end = time.time() + wait
            while child.isalive() and time.time() < end:
                time.sleep(0.05)
            if not child.isalive():
                break
        child.close(force=True)


def _true(value):
    return value is True or str(value).lower() in ("true", "yes", "1")


def _strip_ansi(text):
    return re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text)


def _tail(con, n=15):
    return "\n".join("".join(con.transcript).splitlines()[-n:])
