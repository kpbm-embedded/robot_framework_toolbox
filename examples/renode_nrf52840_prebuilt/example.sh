#!/usr/bin/env bash
# about: a prebuilt Zephyr shell (Antmicro image cached by 32_06_renode) on Renode's nRF52840, offline, no build
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
[ -x "${RENODE_DIR:-}/renode-test" ] || { echo "skip: Renode not found (BOX_RENODE)"; exit 3; }
DEMOS="$RENODE_ID/cache/downloads"   # images cached by 32_06_renode (./renode-box install)
ELF="$DEMOS/zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681"
[ -f "$ELF" ] || { echo "skip: $ELF not cached (32_06_renode: ./renode-box install)"; exit 3; }
case "${1:-test}" in
  build) ;;
  run|test) RBOX_RESULTS="$EX_OUT" "$ROBOT_BOX_ROOT/robot-box" renode "$EX_DIR/nrf52840.robot" --variable "ELF:$ELF" \
              --variable "REPL:$RENODE_ID/examples/nrf52840_nicenano/nicenano.repl" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
