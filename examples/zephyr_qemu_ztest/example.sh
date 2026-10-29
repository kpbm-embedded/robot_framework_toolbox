#!/usr/bin/env bash
# about: 32_03_zephyr's ztest-basic and ztest-fff images on qemu, their ztest results checked from Robot
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
BOARD=${BOARD:-qemu_cortex_m3}
[ -x "${ZEPHYR_ID:-}/scripts/app" ] || { echo "skip: 32_03_zephyr not found (BOX_ZEPHYR)"; exit 3; }
case "${1:-test}" in
  build) for e in ztest-basic ztest-fff; do "$ZEPHYR_ID/scripts/app" example "$e" "$BOARD"; done ;;
  run|test) robot --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" -v "BOARD:$BOARD" "$EX_DIR/ztest.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
