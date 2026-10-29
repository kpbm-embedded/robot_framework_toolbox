#!/usr/bin/env bash
# about: pabot: four suites, each with its own fake board, run in parallel processes; one merged report
# Usage (via ./robot-box examples): build | run | test
set -euo pipefail
case "${1:-test}" in
  build) ;;
  run|test) pabot --processes 4 --pythonpath "$ROBOTLIB" --outputdir "$EX_OUT" "$EX_DIR/suites" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
