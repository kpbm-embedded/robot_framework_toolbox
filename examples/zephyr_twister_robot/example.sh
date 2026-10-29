#!/usr/bin/env bash
# about: Zephyr's own test runner: twister with 'harness: robot' builds app/ and runs its .robot in Renode
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
[ -x "${ZEPHYR_ID:-}/scripts/app" ] || { echo "skip: 32_03_zephyr not found (BOX_ZEPHYR)"; exit 3; }
[ -x "${RENODE_DIR:-}/renode-test" ] || { echo "skip: Renode not found (BOX_RENODE)"; exit 3; }
case "${1:-test}" in
  build) "$ROBOT_BOX_ROOT/robot-box" zephyr twister -p riscv32_virtual -T "$EX_DIR/app" --build-only ;;
  run|test) "$ROBOT_BOX_ROOT/robot-box" zephyr twister -p riscv32_virtual -T "$EX_DIR/app" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
