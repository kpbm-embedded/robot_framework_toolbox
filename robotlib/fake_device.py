"""A stand-in for a Zephyr board's shell, for tests that need no hardware.

    python fake_device.py                 the shell on stdin/stdout (Start Console)
    python fake_device.py --pty LINK      the shell on a new pseudo terminal, symlinked at LINK (a "serial port")

Commands: ``version``, ``demo hello [name]``, ``demo uptime``, ``led on|off``, ``led state``, ``crash``,
``echo <text>``, ``exit``. The prompt is ``uart:~$ `` (no line end), like Zephyr's.
"""
import argparse
import os
import signal
import sys
import time
import tty

BANNER = "*** Booting Zephyr OS build v4.4.2 (fake_device) ***"
PROMPT = "uart:~$ "


def answer(line, state):
    words = line.split()
    if not words:
        return ""
    if words == ["version"]:
        return "Zephyr version 4.4.2"
    if words[:2] == ["demo", "hello"]:
        return f"hello {words[2] if len(words) > 2 else 'world'}"
    if words == ["demo", "uptime"]:
        return f"uptime {int((time.monotonic() - state['t0']) * 1000)} ms"
    if words[:1] == ["led"] and words[1:] in (["on"], ["off"]):
        state["led"] = words[1]
        return f"led {words[1]}"
    if words == ["led", "state"]:
        return f"led is {state['led']}"
    if words[:1] == ["echo"]:
        return line.split(" ", 1)[1] if " " in line else ""
    if words == ["crash"]:
        return ">>> ZEPHYR FATAL ERROR 0: CPU exception on CPU 0"
    return f"{words[0]}: command not found"


def serve(rd, wr):
    state = {"t0": time.monotonic(), "led": "off"}
    wr(f"{BANNER}\r\n{PROMPT}")
    buf = ""
    while True:
        ch = rd()
        if ch == "":
            return
        if ch in "\r\n":
            line, buf = buf.strip(), ""
            if line == "exit":
                wr("\r\nbye\r\n")
                return
            out = answer(line, state)
            wr("\r\n" + (out + "\r\n" if out else "") + PROMPT)
        else:
            buf += ch
            wr(ch)   # echo, as a real shell does


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--pty", metavar="LINK", help="serve on a new pty and symlink it at LINK")
    a = ap.parse_args()
    if not a.pty:
        def wr(s):
            sys.stdout.write(s)
            sys.stdout.flush()
        serve(lambda: sys.stdin.read(1), wr)
        return
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))   # Terminate Process: still remove the link
    master, slave = os.openpty()
    tty.setraw(slave)
    if os.path.lexists(a.pty):
        os.unlink(a.pty)   # our own symlink from an earlier run
    os.symlink(os.ttyname(slave), a.pty)
    print(f"fake_device on {os.ttyname(slave)} (link {a.pty})", flush=True)
    try:
        serve(lambda: os.read(master, 1).decode(errors="replace"), lambda s: os.write(master, s.encode()))
    finally:
        os.unlink(a.pty)


if __name__ == "__main__":
    main()
