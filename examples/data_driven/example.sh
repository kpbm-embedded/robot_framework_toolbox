#!/usr/bin/env bash
# about: data-driven tests: one template keyword, a table of shell commands and expected replies (+ libdoc)
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
case "${1:-test}" in
  build) python -m robot.libdoc --pythonpath "$ROBOTLIB" ConsoleLibrary "$EX_OUT/ConsoleLibrary.html" ;;
  run|test)
    python -m robot.libdoc --pythonpath "$ROBOTLIB" ConsoleLibrary "$EX_OUT/ConsoleLibrary.html" >/dev/null
    robot --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" "$EX_DIR/commands.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
