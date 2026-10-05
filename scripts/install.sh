#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${CAMOUFOX_VENV_DIR:-/root/.openclaw/workspace/.venvs/camoufox}"
PYTHON_BIN="$VENV_DIR/bin/python"
PIP_BIN="$VENV_DIR/bin/pip"
VISIT_SCRIPT="$BASE_DIR/scripts/visit.py"
CACHE_BASE="${XDG_CACHE_HOME:-${HOME:-/root}/.cache}"
CACHE_DIR="$CACHE_BASE/camoufox"
VENV_BACKUP="$VENV_DIR-0.4.11-backup"
CACHE_BACKUP="$CACHE_BASE/camoufox-135.0.1-beta.24-backup"
PACKAGE_SPEC="camoufox==0.5.6"
BROWSER_SPEC="official/stable/152.0.4-beta.29-1bea4b55"
EXPECTED_WRAPPER="0.5.6"
EXPECTED_BROWSER="152.0.4-beta.29"
EXPECTED_BROWSER_SHA256="1bea4b55a51c88e82dc7d426d9c75093d942d2afc8c911cb8fc78ebf723d686c"

log() { printf '[camoufox] %s\n' "$*"; }
fail() { printf '[camoufox] ERROR: %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "python3 not found"

CURRENT_WRAPPER=""
if [ -x "$PYTHON_BIN" ]; then
  CURRENT_WRAPPER="$($PYTHON_BIN -c 'import importlib.metadata; print(importlib.metadata.version("camoufox"))' 2>/dev/null || true)"
fi

if [ -n "$CURRENT_WRAPPER" ] && [ "$CURRENT_WRAPPER" != "$EXPECTED_WRAPPER" ]; then
  [ "$CURRENT_WRAPPER" = "0.4.11" ] || fail "unsupported existing wrapper: $CURRENT_WRAPPER"
  [ ! -e "$VENV_BACKUP" ] || fail "venv backup already exists: $VENV_BACKUP"
  [ ! -e "$CACHE_BACKUP" ] || fail "browser backup already exists: $CACHE_BACKUP"
  if [ -e "$CACHE_DIR" ]; then
    [ -f "$CACHE_DIR/version.json" ] || fail "unrecognized legacy cache: $CACHE_DIR"
    LEGACY_BROWSER="$(python3 - "$CACHE_DIR/version.json" <<'PY'
import json
import sys

version = json.load(open(sys.argv[1], encoding="utf-8"))
print(f"{version['version']}-{version['release']}")
PY
)"
    [ "$LEGACY_BROWSER" = "135.0.1-beta.24" ] || fail "unexpected legacy browser: $LEGACY_BROWSER"
  fi

  log "preserving rollback venv: $VENV_BACKUP"
  mv "$VENV_DIR" "$VENV_BACKUP"
  if [ -e "$CACHE_DIR" ]; then
    log "preserving rollback browser: $CACHE_BACKUP"
    mv "$CACHE_DIR" "$CACHE_BACKUP"
  fi
fi

if [ ! -d "$VENV_DIR" ]; then
  log "creating shared venv: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  log "shared venv already exists: $VENV_DIR"
fi

log "installing $PACKAGE_SPEC"
"$PIP_BIN" install --upgrade "$PACKAGE_SPEC" >/dev/null

[ -x "$PYTHON_BIN" ] || fail "python not found in venv: $PYTHON_BIN"
[ -f "$VISIT_SCRIPT" ] || fail "visit script not found: $VISIT_SCRIPT"

log "fetching pinned browser assets"
"$PYTHON_BIN" -m camoufox fetch "$BROWSER_SPEC" || fail "camoufox fetch failed"
"$PYTHON_BIN" -m camoufox set "$BROWSER_SPEC" || fail "camoufox pin failed"

log "verifying pinned versions"
"$PYTHON_BIN" - "$EXPECTED_WRAPPER" "$EXPECTED_BROWSER" "$EXPECTED_BROWSER_SHA256" <<'PY' || fail "version verification failed"
import importlib.metadata
import json
import sys

from camoufox.pkgman import camoufox_path, installed_verstr

expected_wrapper, expected_browser, expected_sha256 = sys.argv[1:]
actual_wrapper = importlib.metadata.version("camoufox")
browser_path = camoufox_path(download_if_missing=False)
actual_browser = installed_verstr()
actual_sha256 = json.loads((browser_path / "version.json").read_text())["sha256"]
if (actual_wrapper, actual_browser, actual_sha256) != (
    expected_wrapper,
    expected_browser,
    expected_sha256,
):
    raise SystemExit(
        f"expected {expected_wrapper}/{expected_browser}/{expected_sha256}; "
        f"got {actual_wrapper}/{actual_browser}/{actual_sha256}"
    )
PY

log "running smoke test"
"$PYTHON_BIN" "$VISIT_SCRIPT" "https://example.com" --mode title --headless --json >/tmp/camoufox-smoke.json || fail "smoke test failed"

log "install complete"
