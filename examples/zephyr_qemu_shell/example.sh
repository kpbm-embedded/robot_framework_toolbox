#!/usr/bin/env bash
# about: Zephyr shell example of 32_03_zephyr built for qemu_cortex_m3 and tested through its console
# Usage (via ./robot-box examples): build | run | test   (BOARD=qemu_riscv32 for another qemu board)
set -euo pipefail
BOARD=${BOARD:-qemu_cortex_m3}
[ -x "${ZEPHYR_ID:-}/scripts/app" ] || { echo "skip: 32_03_zephyr not found (BOX_ZEPHYR)"; exit 3; }
case "${1:-test}" in
  build) "$ZEPHYR_ID/scripts/app" example shell "$BOARD" ;;
  run|test) robot --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" -v "BOARD:$BOARD" "$EX_DIR/shell.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
