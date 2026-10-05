#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${CAMOUFOX_VENV_DIR:-/root/.openclaw/workspace/.venvs/camoufox}"
PYTHON_BIN="$VENV_DIR/bin/python"
VISIT_SCRIPT="$BASE_DIR/scripts/visit.py"
RUN_SMOKE="${RUN_SMOKE:-1}"
EXPECTED_WRAPPER="0.5.6"
EXPECTED_BROWSER="152.0.4-beta.29"
EXPECTED_BROWSER_SHA256="1bea4b55a51c88e82dc7d426d9c75093d942d2afc8c911cb8fc78ebf723d686c"

log() { printf '[camoufox] %s\n' "$*"; }
fail() { printf '[camoufox] ERROR: %s\n' "$*" >&2; exit 1; }

[ -x "$PYTHON_BIN" ] || fail "python not found in shared venv: $PYTHON_BIN"
[ -f "$VISIT_SCRIPT" ] || fail "visit script not found: $VISIT_SCRIPT"
[ -f "$BASE_DIR/SKILL.md" ] || fail "missing SKILL.md"
[ -f "$BASE_DIR/README.md" ] || fail "missing README.md"
[ -f "$BASE_DIR/scripts/install.sh" ] || fail "missing scripts/install.sh"
[ -f "$BASE_DIR/scripts/check.sh" ] || fail "missing scripts/check.sh"

log "checking pinned versions"
"$PYTHON_BIN" - "$EXPECTED_WRAPPER" "$EXPECTED_BROWSER" "$EXPECTED_BROWSER_SHA256" <<'PY' || fail "version check failed"
import importlib.metadata
import json
import sys

from camoufox.pkgman import camoufox_path, installed_verstr

expected_wrapper, expected_browser, expected_sha256 = sys.argv[1:]
browser_path = camoufox_path(download_if_missing=False)
actual = (
    importlib.metadata.version("camoufox"),
    installed_verstr(),
    json.loads((browser_path / "version.json").read_text())["sha256"],
)
expected = (expected_wrapper, expected_browser, expected_sha256)
if actual != expected:
    raise SystemExit(f"expected {expected}; got {actual}")
PY

if [ "$RUN_SMOKE" = "1" ]; then
  log "running smoke test"
  "$PYTHON_BIN" "$VISIT_SCRIPT" "https://example.com" --mode title --headless --json >/tmp/camoufox-check-smoke.json || fail "smoke test failed"
  log "smoke test: OK"

  log "running Firefox download-event test"
  PORT_FILE="$(mktemp)"
  RSS_RESULT="$(mktemp)"
  RSS_SERVER_PID=""
  cleanup() {
    if [ -n "$RSS_SERVER_PID" ] && kill -0 "$RSS_SERVER_PID" 2>/dev/null; then
      kill "$RSS_SERVER_PID" 2>/dev/null || true
      wait "$RSS_SERVER_PID" 2>/dev/null || true
    fi
    rm -f "$PORT_FILE" "$RSS_RESULT"
  }
  trap cleanup EXIT
  "$PYTHON_BIN" - "$PORT_FILE" <<'PY' &
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

body = b'<?xml version="1.0"?><rss version="2.0"><channel><title>Probe Feed</title></channel></rss>'

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/rss+xml; charset=utf-8")
        self.send_header("Content-Disposition", 'attachment; filename="probe.rss"')
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        self.wfile.flush()

    def log_message(self, format, *args):
        pass

server = HTTPServer(("127.0.0.1", 0), Handler)
Path(sys.argv[1]).write_text(str(server.server_port), encoding="ascii")
server.handle_request()
server.server_close()
PY
  RSS_SERVER_PID=$!
  for _ in $(seq 1 100); do
    [ -s "$PORT_FILE" ] && break
    sleep 0.05
  done
  [ -s "$PORT_FILE" ] || fail "download-event test server failed to start"
  "$PYTHON_BIN" "$VISIT_SCRIPT" "http://127.0.0.1:$(cat "$PORT_FILE")/feed.rss" \
    --mode text --headless --wait-ms 0 --json >"$RSS_RESULT" || fail "download-event visit failed"
  wait "$RSS_SERVER_PID" || fail "download-event test server failed"
  RSS_SERVER_PID=""
  "$PYTHON_BIN" - "$RSS_RESULT" <<'PY' || fail "download-event result check failed"
import json
import sys

result = json.load(open(sys.argv[1], encoding="utf-8"))
assert result["ok"] is True, result
assert result["download"] is not None, result
assert result["download"]["suggested_filename"] == "probe.rss", result
assert result["download"]["size"] == len(result["text"].encode("utf-8")), result
assert "Probe Feed" in result["text"], result
PY
  log "Firefox download-event test: OK"
fi

log "check complete"
