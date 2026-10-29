#!/usr/bin/env bash
# about: a "board" on a serial port: SerialLibrary and ConsoleLibrary on a pty served by the fake device
# Usage (via ./robot-box examples): build | run | test   (a real board: robot -v PORT:/dev/ttyACM0 serial.robot)
set -euo pipefail
case "${1:-test}" in
  build) ;;
  run|test) robot --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" -v "PORT:$EX_OUT/ttyFAKE0" "$EX_DIR/serial.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
