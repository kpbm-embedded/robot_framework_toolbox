# 32_30_robot_framework notes

## 2026-10-29
- Created the ID (`box new tool 32_embedded robot_framework`); launcher renamed to `robot-box` (template stubs to the
  Trash, logged). pixi bootstrap copied from `32_06_renode/renode-box`; `lib/boxtool.bash` is the shared copy.
- Robot Framework 7.5 for everything except Renode: Renode 1.17's `retry_and_timeout_listener` (priority `None`) and
  `robot_output_formatter` (v2 arguments) fail under RF 7 with errors in the log, so retries/timeouts silently stop.
  `renode` runs in a second pixi env (`renode`) with RF 6.1, the version in renode/tests/requirements.txt.
- Renode details: `Wait For Line On Uart` returns a dict over the remote protocol (`Line`, `Groups`, `Timestamp`);
  `renode-test` resets the emulation between tests ("There are no testers available" after a Suite Setup boot).
  Renode's stock `nrf52840.repl` gives no UART output for Antmicro's prebuilt shell: 32_06's `nicenano.repl` works.
- Zephyr: twister's `harness: robot` calls `renode-test` from PATH with KEYWORDS/ELF/RESC/UART: `lib/shims/renode-test`
  maps it to `./robot-box renode` with results in the build folder. `$BOX_ZEPHYR` names `toolchain/zephyr` inside the
  ID, so the launcher looks for `scripts/app` up to two folders above it.
- ConsoleLibrary: `Run Shell Command` first drains pending output; without that a prompt still in the buffer ended the
  wait early and every answer lagged by one command (seen on qemu, not on the fake device).
- fake_device `--pty`: SIGTERM handler so the link is removed; a stale link pointing at a dead pty raced the new one.
- Results: doctor 17 ok + 1 warn (no board); examples 11/11; templates 7/7 run + 3/3 `--dryrun` (hardware);
  smoke 18/18; dry run 13/13; robocop lint 0 issues, format clean.
