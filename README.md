# camoufox

Firefox-based stealth browser workflow for hard targets that resist normal fetching or standard browser automation.

## What it does

- visit harder targets with a stealthier Firefox-based engine
- fetch title or page text from guarded pages
- capture screenshots from protected or JS-heavy sites
- support proxy, cookies, selector waits, and structured JSON output

## Install

```bash
bash scripts/install.sh
```

## Validate

```bash
bash scripts/check.sh
```

## Quick commands

```bash
/root/.openclaw/workspace/.venvs/camoufox/bin/python \
  /root/.openclaw/workspace/skills/camoufox/scripts/visit.py \
  "https://example.com" --mode title --headless --json

/root/.openclaw/workspace/.venvs/camoufox/bin/python \
  /root/.openclaw/workspace/skills/camoufox/scripts/visit.py \
  "https://example.com" --mode full --headless --json
```

## Notes

- Use Camoufox only for hard targets; prefer lighter tools first.
- `scripts/visit.py` is the unified entrypoint for this skill.
- Re-run `scripts/install.sh` if package or browser assets are missing.
