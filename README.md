# 32_30_robot_framework - Robot Framework for embedded tests

Robot Framework 7.5 (https://robotframework.org/) with the libraries for testing firmware and boards, and the links
to the targets the other embedded tools provide: **Zephyr** (32_03_zephyr: build, qemu, ztest, twister), **Renode**
(32_06_renode: `renode-test` and its keywords), **QEMU** (Zephyr SDK) and **serial hardware** (pyserial,
SerialLibrary). Use it to write one kind of test that runs on the PC (fake device, qemu, Renode) and on a real board
(UART, SSH), and to run Zephyr's own `harness: robot` twister tests. Everything is pinned and kept inside this folder.

Status: **ready** (doctor 17 ok, 1 expected warning: no board attached; examples 11/11; templates 7 run + 3 dry-run;
smoke 18/18; dry run 13/13; lint and format clean, 2026-10-29). Nothing has run on real hardware yet. Launcher: `./robot-box`.

## What's included

| Component | Version | Notes |
|---|---|---|
| Robot Framework | 7.5 (2026-09-14) | default env; `robot`, `rebot`, `libdoc` |
| Robot Framework for Renode | 6.1 | own pixi env `renode`: Renode 1.17's listeners need 6.1 (`renode` command) |
| pabot | 5.2.2 | suites or tests in parallel processes |
| robocop | 9.1.2 | lint and format (`config/robocop.toml`) |
| SerialLibrary, pyserial | 0.4.3, 3.5 | UART / USB CDC / rfc2217 |
| SSHLibrary | 3.8.0 | embedded Linux boards over SSH |
| RetryFailed, pexpect | 0.2.0, 4.9.0 | retries; consoles on a pty |
| `robotlib/ConsoleLibrary.py` | 1.0.0 (this ID) | one console API for processes (qemu, host tools) and serial ports |
| `robotlib/zephyr.resource` | this ID | build a 32_03_zephyr example or source, boot it on qemu, shell and ztest checks |
| `robotlib/renode_zephyr.resource` | this ID | Zephyr image + Renode script + UART tester, shell checks |
| `robotlib/fake_device.py` | this ID | a Zephyr-like shell on stdin/stdout or a pty, for tests without hardware |
| pixi | 0.81.0 | sha256 pinned in `robot-box` |

Reached, not copied: Renode 1.17.0 (32_06_renode, `$BOX_RENODE`), Zephyr v4.4.2 + SDK 1.0.1 with qemu and gdb
(32_03_zephyr, `$BOX_ZEPHYR`). Without them the Renode/Zephyr commands and examples say so (exit 3).

## Quick start

```sh
cd "$BOX_ROBOT_FRAMEWORK"                  # or: cd $BOX/30_39_tools/32_embedded/32_30_robot_framework
./robot-box bootstrap && ./robot-box doctor   # first setup (downloads once), then health checks
./robot-box examples test                     # 11 examples (about 1 min with the Zephyr builds cached)
./robot-box new zephyr_qemu_test mytest --dir ~/work
./robot-box robot ~/work/mytest/mytest.robot  # a Zephyr shell on qemu, tested over the console
./robot-box robot -v PORT:/dev/ttyACM0 "$(./robot-box where | awk '/^  root/{print $2}')"/templates/serial_hw_test/__name__.robot
```

With the Box shell set up once (`box shell install --apply`), the `robot-box` shim works from any folder, and
`box test|doctor|status robot_framework` run this launcher. Standalone (`BOX_INTEGRATION=0`), output stays in this folder.

## Commands

Global option: `--dry-run` / `-n` prints what a command would do. Exit codes: 0 ok, 1 failure (a failed test
included), 2 usage error, 3 not applicable (for example Renode not installed). `help` lists everything.

| Command | What it does | Example |
|---|---|---|
| `bootstrap` | pinned pixi + both envs (default, renode) | `./robot-box bootstrap` |
| `install` | bootstrap (the examples build their Zephyr images when run) | `./robot-box install` |
| `update [--check\|--env]` | `--check`: PyPI pins vs newest; `--env`: re-solve (rewrites pixi.lock) | `./robot-box update` |
| `clean [--all] [--yes]` | move output (`--all`: also envs and caches) to the Trash; dry run unless `--yes` | `./robot-box clean` |
| `status`, `where`, `doctor` | versions, paths, health checks | `./robot-box doctor` |
| `shell`, `run <cmd>` | a shell / one command in the env | `./robot-box run rebot --help` |
| `robot [args]` | Robot Framework; `robotlib/` on the path, output in the log dir unless `-d` | `./robot-box robot tests/` |
| `pabot [args]` | the same in parallel (`--testlevelsplit` for tests) | `./robot-box pabot tests/` |
| `renode <file.robot> [args]` | Renode's `renode-test` (Renode keywords, `${RENODEKEYWORDS}`), RF 6.1 env | `./robot-box renode t.robot --variable ELF:@fw.elf` |
| `zephyr <cmd> [args]` | 32_03_zephyr `scripts/app` (`build`, `example`, `ztest`, `debug`, ...) | `./robot-box zephyr example shell qemu_cortex_m3` |
| `twister [args]` | Zephyr twister with `renode-test` on PATH: `harness: robot` runs in Renode | `./robot-box twister -p riscv32_virtual -T app/` |
| `lint [paths]`, `format [--check] [paths]` | robocop | `./robot-box lint` |
| `libdoc <lib> <out.html>` | keyword documentation | `./robot-box libdoc ConsoleLibrary cl.html` |
| `new <kind> <name> [--dir D]` | a test from `templates/` | `./robot-box new ssh_linux_test board` |
| `examples list\|run\|build\|test [ex...]` | the examples | `./robot-box examples test selftest` |
| `test [--all]` | `tests/test_smoke.sh` (`--all`: + dry-run test + examples) | `./robot-box test --all` |
| `native`, `relocate`, `pack` | PATH shims; after a move; tarball for another machine | `./robot-box native` |

## Examples

`./robot-box examples test [ex...]`; results (log.html, report.html) in `build/examples/<ex>/` of the output dir.

| Example | Target | What is checked |
|---|---|---|
| `selftest` | fake device (process) | ConsoleLibrary: banner, prompt, commands, state, timeouts, crash detection |
| `serial_pty` | fake device on a pty | SerialLibrary and ConsoleLibrary on a "serial port"; `-v PORT:/dev/ttyACM0` for a board |
| `data_driven` | fake device | a table of commands and expected replies (Test Template), ConsoleLibrary libdoc |
| `pabot_parallel` | 4 fake devices | four suites in parallel processes, one merged report |
| `zephyr_qemu_shell` | Zephyr `shell` on qemu_cortex_m3 | kernel/custom commands, uptime, no fatal error |
| `zephyr_qemu_ztest` | Zephyr `ztest-basic`, `ztest-fff` on qemu | ztest results as Robot tests (template table) |
| `zephyr_renode_shell` | Zephyr `shell` on Renode riscv32_virtual | Renode keywords, virtual time (uptime after `RunFor 2`) |
| `zephyr_renode_gdb` | Zephyr `ztest-basic` in Renode + SDK gdb | debugger: GDB server, breakpoint at `fifo_put`, read a variable, run to the end |
| `zephyr_twister_robot` | twister on riscv32_virtual | Zephyr's own runner with `harness: robot` (renode-test shim) |
| `renode_nrf52840_prebuilt` | prebuilt Zephyr shell on nRF52840 (32_06 cache) | a binary you did not build, offline |
| `linux_renode_login` | Zynq-7000 buildroot Linux in Renode (32_06 cache) | boot, log in on the UART, commands |

## Templates

`./robot-box new <kind> <name> [--dir D]`; each `.robot` file says how to run it in its `Documentation`.

| Kind | For |
|---|---|
| `zephyr_qemu_test` | a 32_03_zephyr example or your own Zephyr source on qemu |
| `zephyr_renode_test` | a Zephyr image + board script in Renode |
| `zephyr_twister_app` | a Zephyr app with `sample.yaml` (`harness: robot`) and its `.robot` for twister |
| `ztest_console` | a ztest image's summary as a Robot test (qemu or a board's UART) |
| `serial_hw_test` | a board on a UART, optional reset command |
| `hil_flash_test` | build, `west flash`, then UART checks (hardware in the loop) |
| `ssh_linux_test` | an embedded Linux board over SSH (key or `-v PASSWORD:` on the command line) |
| `renode_gdb_test` | gdb against Renode's GDB server from a test |
| `data_driven_test` | command/reply tables, fake device or a board |
| `keyword_library` | your own Python keyword library + tests |

## Configuration and environment variables

| Variable | Default | Meaning |
|---|---|---|
| `BOX_RENODE`, `RBOX_RENODE_DIR` | sibling `32_06_renode`, its `install/renode` | Renode ID / Renode folder |
| `BOX_ZEPHYR` | sibling `32_03_zephyr` | Zephyr ID (the folder or a folder below it holding `scripts/app`) |
| `RBOX_RESULTS` | log dir (`renode`); cwd for the twister shim | where `renode-test` writes results |
| `BOXT_OUT` | `$BOX_OUT/<this ID path>`, standalone this folder | output base (`build/`, `log/`) |
| `NO_COLOR`, `BOX_INTEGRATION` | - | plain output; `0` = standalone |
| `ROBOTLIB`, `ZEPHYR_ID`, `RENODE_DIR` | set by the launcher | read by the tests (`%{ZEPHYR_ID}`) |

`config/robocop.toml`: lint/format rules. `pixi.toml` / `pixi.lock`: both envs.

## Where files go

| What | Where |
|---|---|
| pixi, envs, caches | `.bin/`, `.pixi/`, `cache/` (Renode config/cache in `cache/xdg-*`) |
| robot/pabot/renode output | `$BOXT_OUT/log/{robot,pabot,renode}` |
| example output | `$BOXT_OUT/build/examples/<ex>/` |
| Zephyr builds | 32_03_zephyr's output (`build/examples/<ex>/<board>`, `twister/`) |

## Limitations

- Renode tests run on Robot Framework 6.1 (Renode 1.17's runner and listeners); every other command uses 7.5.
  Write Renode suites so they work on both (no RF 7-only syntax such as `VAR`).
- `renode-test` resets the emulation between tests: boot in each test (or in `Test Setup`), not in `Suite Setup`.
- Hardware templates (`serial_hw_test`, `hil_flash_test`, `ssh_linux_test`) are checked with `--dryrun` only:
  no board was attached. Boards with a different shell prompt: `Library ConsoleLibrary prompt=...`.
- Windows: not supported (pixi env and pty use); use WSL.
