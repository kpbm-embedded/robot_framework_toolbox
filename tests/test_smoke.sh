#!/usr/bin/env bash
# Smoke test of the robot-box launcher: help, where, status, usage errors (exit 2), dry runs of the tool
# commands, and, when the env is installed, doctor, lint, a template round trip and the host-only examples.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
rb="$here/robot-box"
pass=0 fail=0
t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $name"; fi; }
t help "$rb" help
t where "$rb" where
t status "$rb" status
t unknown-exits-2 bash -c '"$1" no-such-command; [ $? -eq 2 ]' _ "$rb"
t renode-no-args-exits-2 bash -c '"$1" renode; [ $? -eq 2 ]' _ "$rb"
t libdoc-no-args-exits-2 bash -c '"$1" libdoc; [ $? -eq 2 ]' _ "$rb"
t where-extra-arg-exits-2 bash -c '"$1" where x; [ $? -eq 2 ]' _ "$rb"
t dry-robot bash -c '"$1" --dry-run robot x.robot | grep -q -- "--pythonpath"' _ "$rb"
t dry-renode bash -c '"$1" --dry-run renode x.robot | grep -q renode-test' _ "$rb"
t dry-new bash -c '"$1" --dry-run new zephyr_qemu_test probe --dir /nonexistent | grep -q copy' _ "$rb"
t shim-executable test -x "$here/lib/shims/renode-test"
if [ -x "$here/.pixi/envs/default/bin/python" ]; then
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/rbox-smoke.XXXXXX")
  t doctor "$rb" doctor
  t lint "$rb" lint
  t format-check "$rb" format --check
  t new-keyword-library "$rb" new keyword_library kl --dir "$tmp"
  t template-runs "$rb" robot -d "$tmp/out" "$tmp/kl/kl.robot"
  t examples-host "$rb" examples test selftest serial_pty data_driven pabot_parallel
  # a failing test must fail the run (exit 1), not pass silently
  printf '*** Test Cases ***\nMust Fail\n    Fail    on purpose\n' >"$tmp/fail.robot"
  t failing-test-fails bash -c '"$1" robot -d "$2/out2" "$2/fail.robot"; [ $? -eq 1 ]' _ "$rb" "$tmp"
  echo "smoke: temp files in $tmp"
fi
echo "smoke: $pass ok, $fail failed"
[ "$fail" -eq 0 ]
