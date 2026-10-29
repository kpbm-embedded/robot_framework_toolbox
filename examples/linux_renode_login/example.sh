#!/usr/bin/env bash
# about: embedded Linux in Renode (Zynq-7000 buildroot, cached): boot, log in on the UART, run commands (~20 s)
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
[ -x "${RENODE_DIR:-}/renode-test" ] || { echo "skip: Renode not found (BOX_RENODE)"; exit 3; }
DEMOS="$RENODE_ID/cache/downloads"   # images cached by 32_06_renode (./renode-box install)
case "${1:-test}" in
  build) ;;
  run|test) RBOX_RESULTS="$EX_OUT" "$ROBOT_BOX_ROOT/robot-box" renode "$EX_DIR/linux.robot" \
              --variable "DEMOS:$DEMOS" --variable "RESC:$RENODE_ID/examples/linux_k210_zynq/zynq_linux.resc" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
