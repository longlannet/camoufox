#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

from camoufox.sync_api import Camoufox


def parse_cookie_string(raw: str):
    cookies = []
    for part in raw.split(";"):
        item = part.strip()
        if not item or "=" not in item:
            continue
        name, value = item.split("=", 1)
        cookies.append({"name": name.strip(), "value": value.strip()})
    return cookies


def load_cookie_file(path: str):
    p = Path(path)
    text = p.read_text(encoding="utf-8").strip()
    if not text:
        return []
    if text.startswith("["):
        data = json.loads(text)
        if isinstance(data, list):
            return data
    return parse_cookie_string(text)


def normalize_cookies(cookies, target_url: str):
    from urllib.parse import urlparse

    host = urlparse(target_url).hostname or ""
    normalized = []
    for c in cookies:
        if not isinstance(c, dict):
            continue
        if "name" not in c or "value" not in c:
            continue
        item = dict(c)
        item.setdefault("domain", host)
        item.setdefault("path", "/")
        normalized.append(item)
    return normalized


def main() -> int:
    p = argparse.ArgumentParser(description="Minimal Camoufox visit helper")
    p.add_argument("url")
    p.add_argument("--mode", choices=["text", "title", "shot", "full"], default="full")
    p.add_argument("--headless", action="store_true", default=False)
    p.add_argument("--wait-ms", type=int, default=3000)
    p.add_argument("--timeout-ms", type=int, default=90000)
    p.add_argument("--wait-selector", default="")
    p.add_argument("--proxy", default="")
    p.add_argument("--cookies", default="")
    p.add_argument("--cookie-file", default="")
    p.add_argument("--output", default="")
    p.add_argument("--json", action="store_true", default=False)
    args = p.parse_args()

    out = {
        "ok": False,
        "url": args.url,
        "final_url": None,
        "title": None,
        "text": None,
        "screenshot": None,
        "wait_selector": args.wait_selector or None,
        "proxy": args.proxy or None,
        "cookies_loaded": 0,
        "error": None,
    }

    try:
        launch_kwargs = {"headless": args.headless}
        if args.proxy:
            launch_kwargs["proxy"] = args.proxy

        with Camoufox(**launch_kwargs) as browser:
            page = browser.new_page()

            cookie_items = []
            if args.cookie_file:
                cookie_items.extend(load_cookie_file(args.cookie_file))
            if args.cookies:
                cookie_items.extend(parse_cookie_string(args.cookies))
            if cookie_items:
                normalized = normalize_cookies(cookie_items, args.url)
                if normalized:
                    page.context.add_cookies(normalized)
                    out["cookies_loaded"] = len(normalized)

            page.goto(args.url, wait_until="domcontentloaded", timeout=args.timeout_ms)

            if args.wait_selector:
                page.locator(args.wait_selector).wait_for(timeout=args.timeout_ms)

            if args.wait_ms > 0:
                page.wait_for_timeout(args.wait_ms)

            out["final_url"] = page.url
            out["title"] = page.title()

            if args.mode in {"text", "full"}:
                body = page.locator("body").inner_text(timeout=10000)
                out["text"] = body[:8000]

            if args.mode in {"shot", "full"}:
                if args.output:
                    shot_path = Path(args.output)
                else:
                    shot_path = Path("/root/.openclaw/workspace/tmp/camoufox-shot.png")
                shot_path.parent.mkdir(parents=True, exist_ok=True)
                page.screenshot(path=str(shot_path), full_page=True)
                out["screenshot"] = str(shot_path)

            out["ok"] = True
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"

    if args.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        if out["ok"]:
            print(f"URL: {out['final_url']}")
            print(f"TITLE: {out['title']}")
            if out["wait_selector"]:
                print(f"WAIT_SELECTOR: {out['wait_selector']}")
            if out["proxy"]:
                print(f"PROXY: {out['proxy']}")
            if out["cookies_loaded"]:
                print(f"COOKIES_LOADED: {out['cookies_loaded']}")
            if out["text"]:
                print("TEXT:")
                print(out["text"])
            if out["screenshot"]:
                print(f"SCREENSHOT: {out['screenshot']}")
        else:
            print(f"ERROR: {out['error']}", file=sys.stderr)
            return 1

    return 0 if out["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
