# shellcheck shell=bash disable=SC2015,SC2034  # d_* return 0; TOOL_* are read by boxtool.bash
# robot-box: tool part (hooks for lib/boxtool.bash). A pixi env with Robot Framework and the libraries for
# embedded tests, keyword libraries in robotlib/, and the links to the targets in other tool IDs:
# Renode (32_06_renode, its renode-test), Zephyr (32_03_zephyr, scripts/app and twister) and QEMU (Zephyr SDK).
TOOL_TITLE="32_30_robot_framework: Robot Framework $(sed -n 's/^robotframework = "==\(.*\)"/\1/p' "${BOXT_ROOT:?}/pixi.toml" | head -1) for embedded tests (Zephyr, Renode, QEMU, serial)"
TOOL_INSTALL_WHAT="nothing more (examples build the Zephyr images they need)"
TOOL_HELP_USE="  robot [args]            Robot Framework (robotlib/ on the path, output in the log dir unless -d)
  pabot [args]            the same, suites (or tests with --testlevelsplit) in parallel processes
  renode <file.robot> [args]  Renode's renode-test (Renode keywords) with this env's Robot Framework
  zephyr <command> [args] 32_03_zephyr scripts/app (build, example, ztest, twister, debug, ...)
  twister [args]          Zephyr twister with renode-test on PATH, so 'harness: robot' tests run in Renode
  lint [paths]            robocop check (default: examples, templates, robotlib)
  format [--check] [paths]  robocop format (--check: only report)
  libdoc <lib> <out>      keyword docs (html) of a library or resource: libdoc ConsoleLibrary out.html"
hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$BOXT_NAME robot tests/                                  every suite in a folder
  ./$BOXT_NAME renode my.robot --variable ELF:@build/zephyr/zephyr.elf   a Zephyr image in Renode
  ./$BOXT_NAME zephyr example shell qemu_cortex_m3          build a Zephyr example (32_03_zephyr)
  ./$BOXT_NAME twister -p riscv32_virtual -T examples/zephyr_twister_robot/app   harness: robot via Renode
  ./$BOXT_NAME robot -v PORT:/dev/ttyACM0 templates/serial_hw_test/__name__.robot   a real board on a UART
tool environment
  BOX_RENODE / RBOX_RENODE_DIR   32_06_renode ID / its Renode folder (default: the sibling ID, install/renode)
  BOX_ZEPHYR                     32_03_zephyr ID (default: the sibling ID)
  RBOX_RESULTS                   where renode writes its results (default: the log dir; the renode-test
                                 shim used by twister: the current folder)
EOF
}
# shellcheck source-path=SCRIPTDIR source=boxtool.bash
. "$BOXT_ROOT/lib/boxtool.bash"

sibling_id() { # ENV_VAR FOLDER MARKER -> another tool ID: the variable's folder or one above it that holds
  # MARKER (BOX_ZEPHYR names toolchain/zephyr inside the ID), else ../FOLDER (or nothing)
  local d=${!1:-} i
  for i in 1 2 3; do
    [ -n "$d" ] && [ -e "$d/$3" ] && { (cd -P "$d" && pwd -P); return 0; }
    d=${d%/*}
  done
  if [ -e "$ROOT/../$2/$3" ]; then (cd -P "$ROOT/../$2" && pwd -P); fi
}
RENODE_ID=$(sibling_id BOX_RENODE 32_06_renode renode-box)
ZEPHYR_ID=$(sibling_id BOX_ZEPHYR 32_03_zephyr scripts/app)
RENODE_DIR=${RBOX_RENODE_DIR:-${RENODE_ID:+$RENODE_ID/install/renode}}
ROBOTLIB="$ROOT/robotlib"

hook_env() {
  PATH="$ROOT/lib/shims:$PATH"   # renode-test (for twister) -> ./robot-box renode
  [ -n "$RENODE_DIR" ] && [ -d "$RENODE_DIR" ] && PATH="$PATH:$RENODE_DIR"
  export PATH RENODE_DIR ZEPHYR_ID RENODE_ID ROBOTLIB
  export ROBOT_BOX_ROOT="$ROOT" ROBOT_BOX_EXAMPLES="$ROOT/examples"
  # Renode keeps its config and file cache under the user config dir: keep both in this folder
  export XDG_CONFIG_HOME="$ROOT/cache/xdg-config" XDG_CACHE_HOME="$ROOT/cache/xdg-cache"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" 2>/dev/null || true
}

RENODE_ENV="$ROOT/.pixi/envs/renode"   # Robot Framework 6.1 for Renode's renode-test (see pixi.toml)
hook_bootstrap() {
  cachedir_tag "$ROOT/cache"
  run timeout "$NET_TIMEOUT" "$PIXI" install --manifest-path "$MANIFEST" --locked -e renode
}

# update --check: the exact PyPI pins of pixi.toml against PyPI's newest release (pins change deliberately:
# edit pixi.toml, then ./robot-box update --env)
hook_update_check() {
  local name ver latest
  sed -n 's/^\([A-Za-z0-9_.-]*\) = "==\([^"*]*\)"$/\1 \2/p' "$MANIFEST" | sort -u | while read -r name ver; do
    if [ "$DRY" = 1 ]; then printf '+ curl https://pypi.org/pypi/%s/json\n' "$name"; continue; fi
    latest=$(curl -fsS --connect-timeout 20 --max-time 60 "https://pypi.org/pypi/$name/json" 2>/dev/null \
      | python3 -c 'import json, sys; print(json.load(sys.stdin)["info"]["version"])' 2>/dev/null) || true
    printf '  %-30s pinned %-10s latest %s\n' "$name" "$ver" "${latest:-? (offline)}"
  done
}

hook_status() {
  printf '  %-22s %s\n' renode "${RENODE_DIR:-not found} ($(renode_version))" zephyr "${ZEPHYR_ID:-not found}"
}

renode_version() { [ -x "$RENODE_DIR/renode" ] && "$RENODE_DIR/renode" --version 2>/dev/null | head -1 || echo "missing"; }

hook_doctor() {
  local v m
  v=$(python -c 'import robot; print(robot.__version__)' 2>/dev/null) && d_ok "robotframework $v" || d_fail "robotframework missing in the pixi env"
  for m in pabot SerialLibrary SSHLibrary pexpect serial RetryFailed; do
    python -c "import $m" 2>/dev/null && d_ok "python module $m" || d_fail "python module $m missing"
  done
  v=$(robocop --version 2>/dev/null | head -1) && d_ok "robocop $v" || d_fail "robocop missing"
  python -c "import sys; sys.path.insert(0, '$ROBOTLIB'); import ConsoleLibrary" 2>/dev/null \
    && d_ok "robotlib/ConsoleLibrary importable" || d_fail "robotlib/ConsoleLibrary does not import"
  v=$("$RENODE_ENV/bin/python" -c 'import robot; print(robot.__version__)' 2>/dev/null) \
    && d_ok "renode env: robotframework $v (Renode 1.17 wants 6.1)" || d_fail "renode env missing (./$NAME bootstrap)"
  if [ -x "$RENODE_DIR/renode-test" ]; then d_ok "renode: $(renode_version) ($RENODE_DIR)"
  else d_warn "Renode not found (BOX_RENODE / RBOX_RENODE_DIR; install 32_06_renode): renode and the Renode examples skip"; fi
  if [ -x "$ZEPHYR_ID/scripts/app" ]; then d_ok "zephyr: $ZEPHYR_ID/scripts/app"
  else d_warn "32_03_zephyr not found (BOX_ZEPHYR): zephyr, twister and the Zephyr examples skip"; fi
  local n; n=$(find /dev -maxdepth 1 \( -name 'ttyACM*' -o -name 'ttyUSB*' \) 2>/dev/null | wc -l)
  if [ "$n" -gt 0 ]; then d_ok "$n serial port(s) attached (serial_hw_test template)"
  else d_warn "no /dev/ttyACM* or /dev/ttyUSB*: hardware tests need a board (examples use a pty instead)"; fi
}

hook_native_bins() {
  echo "robot @robot"
  echo "pabot @pabot"
  echo "robocop @run robocop"
  echo "libdoc @libdoc"
  echo "renode-test @renode"
}

need_renode() { [ -x "$RENODE_DIR/renode-test" ] || not_applicable "Renode not found: set BOX_RENODE or RBOX_RENODE_DIR (32_06_renode: ./renode-box install)"; }
need_zephyr() { [ -x "$ZEPHYR_ID/scripts/app" ] || not_applicable "32_03_zephyr not found: set BOX_ZEPHYR"; }

abs_args() { # ARGS... -> ABS_ARGS: existing relative paths made absolute (the runners change folder)
  local a; ABS_ARGS=()
  for a in "$@"; do
    if [ -e "$a" ] && [ "${a#/}" = "$a" ]; then ABS_ARGS+=("$PWD/$a"); else ABS_ARGS+=("$a"); fi
  done
}

tool_cmd_robot() {
  activate
  local out="$LOG_DIR/robot"
  [ "$DRY" = 1 ] || mkdir -p "$out"
  # ours first: a -d/--outputdir or --pythonpath given on the command line still wins or adds
  run robot --pythonpath "$ROBOTLIB" --outputdir "$out" "$@"
}
tool_cmd_pabot() {
  activate
  local out="$LOG_DIR/pabot"
  [ "$DRY" = 1 ] || mkdir -p "$out"
  run pabot --processes "$(default_jobs)" --pythonpath "$ROBOTLIB" --outputdir "$out" "$@"
}
tool_cmd_renode() {
  [ $# -ge 1 ] || usage_error "usage: ./$NAME renode <file.robot> [renode-test args]"
  activate
  need_renode
  local results=${RBOX_RESULTS:-$LOG_DIR/renode}
  abs_args "$@"
  if [ "$DRY" = 1 ]; then printf '+ (cd %s && renode-test' "$results"; printf ' %q' "${ABS_ARGS[@]}"; echo ')'; return 0; fi
  [ -x "$RENODE_ENV/bin/python3" ] || die "renode env missing: run ./$NAME bootstrap"
  PATH="$RENODE_ENV/bin:$PATH"   # renode-test runs python3 from PATH: Robot Framework 6.1
  mkdir -p "$results" "$ROOT/cache/renode-config"
  # renode-test writes robot_output.xml, log.html and snapshots to the cwd and to -r
  cd "$results"
  exec "$RENODE_DIR/renode-test" --renode-config "$ROOT/cache/renode-config/config" -r "$results" \
    --variable "ROBOTLIB:$ROBOTLIB" "${ABS_ARGS[@]}"
}
tool_cmd_zephyr() {
  need_zephyr
  activate   # renode-test shim on PATH; scripts/app puts Zephyr's own venv in front
  [ "$DRY" = 1 ] && { printf '+ %s/scripts/app' "$ZEPHYR_ID"; printf ' %q' "$@"; echo; return 0; }
  exec "$ZEPHYR_ID/scripts/app" "$@"
}
tool_cmd_twister() { tool_cmd_zephyr twister "$@"; }
lint_paths() { [ $# -gt 0 ] && printf '%s\n' "$@" || printf '%s\n' "$ROOT/examples" "$ROOT/templates" "$ROBOTLIB"; }
tool_cmd_lint() {
  activate
  local p=(); mapfile -t p < <(lint_paths "$@")
  run robocop check --config "$ROOT/config/robocop.toml" "${p[@]}"
}
tool_cmd_format() {
  local check=()
  [ "${1:-}" = --check ] && { check=(--check --diff); shift; }
  activate
  local p=(); mapfile -t p < <(lint_paths "$@")
  run robocop format --config "$ROOT/config/robocop.toml" "${check[@]+"${check[@]}"}" "${p[@]}"
}
tool_cmd_libdoc() {
  [ $# -ge 2 ] || usage_error "usage: ./$NAME libdoc <library|resource> <out.html>"
  activate
  run python -m robot.libdoc --pythonpath "$ROBOTLIB" "$@"
}

boxt_main "$@"
