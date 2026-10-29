#!/usr/bin/env bash
# Dry runs: every command that changes something prints what it would do and changes nothing.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
rb="$here/robot-box"
pass=0 fail=0
t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $name"; fi; }
before=$(find "$here" -path "$here/.pixi" -prune -o -path "$here/cache" -prune -o -type f -newer "$here/pixi.toml" -print | sort | md5sum)
t bootstrap "$rb" --dry-run bootstrap
t install "$rb" --dry-run install
t clean-all "$rb" --dry-run clean --all
t examples-test "$rb" --dry-run examples test
t robot "$rb" --dry-run robot examples/selftest/selftest.robot
t pabot "$rb" --dry-run pabot examples/pabot_parallel/suites
t renode "$rb" --dry-run renode examples/zephyr_renode_shell/shell.robot
t zephyr "$rb" --dry-run zephyr where
t twister "$rb" --dry-run twister -p riscv32_virtual -T examples/zephyr_twister_robot/app
t lint "$rb" --dry-run lint
t format "$rb" --dry-run format
t new "$rb" --dry-run new serial_hw_test probe
after=$(find "$here" -path "$here/.pixi" -prune -o -path "$here/cache" -prune -o -type f -newer "$here/pixi.toml" -print | sort | md5sum)
t nothing-changed test "$before" = "$after"
echo "dry run: $pass ok, $fail failed"
[ "$fail" -eq 0 ]
