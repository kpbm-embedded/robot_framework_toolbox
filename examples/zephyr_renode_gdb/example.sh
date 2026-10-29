#!/usr/bin/env bash
# about: debugger: Renode's GDB server on a Zephyr image, driven by the Zephyr SDK gdb from a Robot test
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
[ -x "${ZEPHYR_ID:-}/scripts/app" ] || { echo "skip: 32_03_zephyr not found (BOX_ZEPHYR)"; exit 3; }
[ -x "${RENODE_DIR:-}/renode-test" ] || { echo "skip: Renode not found (BOX_RENODE)"; exit 3; }
OUTZ=$("$ZEPHYR_ID/scripts/app" where | awk '$1=="output"{print $2}')
ELF="$OUTZ/examples/ztest-basic/riscv32_virtual/zephyr/zephyr.elf"
GDB="$ZEPHYR_ID/toolchain/zephyr/sdk/zephyr-sdk/gnu/riscv64-zephyr-elf/bin/riscv64-zephyr-elf-gdb"
case "${1:-test}" in
  build) "$ZEPHYR_ID/scripts/app" example ztest-basic riscv32_virtual ;;
  run|test)
    [ -f "$ELF" ] || "$ZEPHYR_ID/scripts/app" example ztest-basic riscv32_virtual >/dev/null
    RBOX_RESULTS="$EX_OUT" "$ROBOT_BOX_ROOT/robot-box" renode "$EX_DIR/gdb.robot" \
      --variable "ELF:$ELF" --variable "GDB:$GDB" --variable "ZEPHYR_BASE:$ZEPHYR_ID/toolchain/zephyr/ws/zephyr" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
