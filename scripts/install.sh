#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="/root/.openclaw/workspace/.venvs/camoufox"
PYTHON_BIN="$VENV_DIR/bin/python"
PIP_BIN="$VENV_DIR/bin/pip"
VISIT_SCRIPT="$BASE_DIR/scripts/visit.py"
PACKAGE_NAME="camoufox"

log() { printf '[camoufox] %s\n' "$*"; }
fail() { printf '[camoufox] ERROR: %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "python3 not found"

if [ ! -d "$VENV_DIR" ]; then
  log "creating shared venv: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  log "shared venv already exists: $VENV_DIR"
fi

log "upgrading pip"
"$PIP_BIN" install --upgrade pip >/dev/null

log "installing $PACKAGE_NAME"
"$PIP_BIN" install --upgrade "$PACKAGE_NAME" >/dev/null

[ -x "$PYTHON_BIN" ] || fail "python not found in venv: $PYTHON_BIN"
[ -f "$VISIT_SCRIPT" ] || fail "visit script not found: $VISIT_SCRIPT"

log "fetching browser assets"
"$PYTHON_BIN" -m camoufox fetch >/tmp/camoufox-fetch.log 2>&1 || fail "camoufox fetch failed"

log "running smoke test"
"$PYTHON_BIN" "$VISIT_SCRIPT" "https://example.com" --mode title --headless --json >/tmp/camoufox-smoke.json || fail "smoke test failed"

log "install complete"
