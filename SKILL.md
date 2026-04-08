---
name: camoufox
description: Camoufox anti-detect browser workflow for hard targets that resist normal fetching or standard browser automation. Use when a site has strong anti-bot or fingerprint defenses, when a Firefox-based stealth engine is specifically useful, or when the user explicitly asks to try Camoufox.
---

# Camoufox

Use this skill only for hard targets.

## When to use
Use this skill when:
- a user explicitly says “try Camoufox”
- a target site is strongly anti-bot or anti-automation
- current browser layers are failing and a stealthier Firefox-based engine is worth testing
- the task benefits from browser rendering plus stealth

## Quick start
```bash
bash scripts/install.sh
/root/.openclaw/workspace/.venvs/camoufox/bin/python scripts/visit.py "https://example.com" --mode title --headless --json
/root/.openclaw/workspace/.venvs/camoufox/bin/python scripts/visit.py "https://example.com" --mode full --headless --json
```

## Workflow
1. Confirm lighter tools have already failed or are inappropriate.
2. Define the hard target and failure mode.
3. Use `scripts/visit.py` for the smallest useful trial.
4. Escalate to text, screenshot, or full mode only if needed.

## Notes
- Do not use Camoufox as the default browsing path.
- `scripts/visit.py` is the unified entrypoint for this skill.
- Use `--wait-selector`, `--proxy`, `--cookies`, or `--cookie-file` when a protected site needs more control.
- Keep detailed human-facing usage in `README.md`.
