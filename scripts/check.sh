#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="/root/.openclaw/workspace/.venvs/camoufox"
PYTHON_BIN="$VENV_DIR/bin/python"
VISIT_SCRIPT="$BASE_DIR/scripts/visit.py"
RUN_SMOKE="${RUN_SMOKE:-1}"

log() { printf '[camoufox] %s\n' "$*"; }
fail() { printf '[camoufox] ERROR: %s\n' "$*" >&2; exit 1; }

[ -x "$PYTHON_BIN" ] || fail "python not found in shared venv: $PYTHON_BIN"
[ -f "$VISIT_SCRIPT" ] || fail "visit script not found: $VISIT_SCRIPT"
[ -f "$BASE_DIR/SKILL.md" ] || fail "missing SKILL.md"
[ -f "$BASE_DIR/README.md" ] || fail "missing README.md"
[ -f "$BASE_DIR/scripts/install.sh" ] || fail "missing scripts/install.sh"
[ -f "$BASE_DIR/scripts/check.sh" ] || fail "missing scripts/check.sh"

log "checking camoufox import"
"$PYTHON_BIN" -c 'import camoufox' >/dev/null

if [ "$RUN_SMOKE" = "1" ]; then
  log "running smoke test"
  "$PYTHON_BIN" "$VISIT_SCRIPT" "https://example.com" --mode title --headless --json >/tmp/camoufox-check-smoke.json || fail "smoke test failed"
  log "smoke test: OK"
fi

log "check complete"
