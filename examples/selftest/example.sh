#!/usr/bin/env bash
# about: ConsoleLibrary against a fake Zephyr shell process (no hardware, no build): waits, commands, errors
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
case "${1:-test}" in
  build) ;;
  run|test) robot --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" "$EX_DIR/selftest.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
