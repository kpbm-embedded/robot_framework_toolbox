#!/usr/bin/env bash
# about: Zephyr shell example built for riscv32_virtual and tested in Renode (virtual time, Renode keywords)
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
[ -x "${ZEPHYR_ID:-}/scripts/app" ] || { echo "skip: 32_03_zephyr not found (BOX_ZEPHYR)"; exit 3; }
[ -x "${RENODE_DIR:-}/renode-test" ] || { echo "skip: Renode not found (BOX_RENODE)"; exit 3; }
ELF="$("$ZEPHYR_ID/scripts/app" where | awk '$1=="output"{print $2}')/examples/shell/riscv32_virtual/zephyr/zephyr.elf"
case "${1:-test}" in
  build) "$ZEPHYR_ID/scripts/app" example shell riscv32_virtual ;;
  run|test)
    [ -f "$ELF" ] || "$ZEPHYR_ID/scripts/app" example shell riscv32_virtual >/dev/null
    RBOX_RESULTS="$EX_OUT" "$ROBOT_BOX_ROOT/robot-box" renode "$EX_DIR/shell.robot" \
      --variable "ELF:$ELF" --variable "ZEPHYR_BASE:$ZEPHYR_ID/toolchain/zephyr/ws/zephyr" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
