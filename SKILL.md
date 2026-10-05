---
name: "camoufox"
description: "Use Camoufox for hard targets resisting normal fetching or browser automation; pinned 0.5.6 assets, downloads, proxy, cookies and screenshots."
homepage: https://github.com/longlannet/camoufox
metadata:
  {
    "openclaw":
      {
        "emoji": "🦊",
        "requires":
          {
            "bins": ["python3"],
            "scripts": ["scripts/visit.py"],
          },
        "install":
          [
            {
              "id": "pip-camoufox",
              "kind": "python",
              "package": "camoufox==0.5.6",
              "bins": ["python3"],
              "label": "Install camoufox (python)",
            },
          ],
      },
  }
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
- The installer pins wrapper `0.5.6` and browser `152.0.4-beta.29`.
- Firefox download navigations, including RSS feeds, are returned as structured download results.
- Use `--wait-selector`, `--proxy`, `--cookies`, or `--cookie-file` when a protected site needs more control.
- Keep detailed human-facing usage in `README.md`.

## Runtime version boundary

The install/check baseline is wrapper `0.5.6` and browser `152.0.4-beta.29`. The existing shared wrapper, matching browser version/hash metadata, and a real headless visit to `https://example.com` were verified during synchronization; no downgrade, download, or browser replacement was performed. The installer rejects existing wrappers other than its expected version or the explicitly supported `0.4.11` migration before changing files. Run `RUN_SMOKE=0 bash scripts/check.sh` for the exact metadata check without a browsing request; a successful version check does not prove arbitrary target-site access. Keep newer runtimes instead of downgrading them merely to satisfy an older skill pin.

Camoufox keeps the existing shared venv. Its default screenshot path is also under the OpenClaw workspace; pass `--output` for an explicitly chosen platform/task output path.

## OpenClaw execution

`{baseDir}` denotes this skill directory; substitute its resolved path before executing a shell command. Relative `scripts/` commands assume this directory as the working directory. Use the OpenClaw execution tool for the bundled scripts. Source synchronization does not install dependencies or copy credentials. Keep existing local configuration and environments unchanged; installation, browser downloads and paid API tests require separate authorization.
The `/root/.openclaw/workspace/.venvs/` runtime is intentionally shared; do not relocate or copy it during skill synchronization.
