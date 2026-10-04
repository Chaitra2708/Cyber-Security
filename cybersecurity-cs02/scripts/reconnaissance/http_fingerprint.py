#!/usr/bin/env python3
"""
CS-02 Lab Reconnaissance - HTTP & Technology Fingerprinter
==========================================================

Authorized use ONLY against the local OWASP Juice Shop laboratory target.

Performs technology identification (Phase 2 / report sections 3.5 + 4.2):
  - HTTP response headers (Server, X-Powered-By, etc.)
  - Security header presence/absence inventory
  - HTML <meta> generator / asset fingerprints
  - Technology guesses (Express, Angular, etc.)
  - Cookie attributes (HttpOnly / Secure / SameSite)

Usage:
    python3 http_fingerprint.py <url> [--json <outfile>]
"""

import argparse
import json
import re
import ssl
import sys
import urllib.error
import urllib.request
from datetime import datetime

# Security headers we expect a hardened web app to send (OWASP ASVS / Cheat Sheet).
SECURITY_HEADERS = [
    "Strict-Transport-Security",
    "Content-Security-Policy",
    "X-Content-Type-Options",
    "X-Frame-Options",
    "X-XSS-Protection",
    "Referrer-Policy",
    "Permissions-Policy",
    "Cross-Origin-Opener-Policy",
    "Cross-Origin-Resource-Policy",
    "Cache-Control",
]

UA = "CS02-Lab-Recon/1.0"


def fetch(url, method="GET"):
    """Fetch a URL, returning (status, headers_dict, body_text, error)."""
    req = urllib.request.Request(url, method=method, headers={"User-Agent": UA})
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE  # lab self-signed certs are expected
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as resp:
            body = resp.read(65536).decode("utf-8", "replace")
            return resp.status, dict(resp.headers), body, None
    except urllib.error.HTTPError as exc:
        body = ""
        try:
            body = exc.read(65536).decode("utf-8", "replace")
        except Exception:
            pass
        return exc.code, dict(exc.headers or {}), body, None
    except Exception as exc:  # noqa: BLE001
        return None, {}, "", str(exc)


def analyze(url):
    out = {"url": url, "fetched_at": datetime.now().isoformat(timespec="seconds")}

    status, headers, body, err = fetch(url)
    if err:
        out["error"] = err
        return out

    out["status"] = status
    low_headers = {k.lower(): v for k, v in headers.items()}

    # --- Server / technology disclosure headers -------------------------
    out["server"] = headers.get("Server") or headers.get("server")
    out["x_powered_by"] = headers.get("X-Powered-By") or headers.get("x-powered-by")

    # --- Security header inventory --------------------------------------
    present, missing = [], []
    for h in SECURITY_HEADERS:
        if h.lower() in low_headers:
            present.append({"header": h, "value": low_headers[h.lower()]})
        else:
            missing.append(h)
    out["security_headers_present"] = present
    out["security_headers_missing"] = missing

    # --- Cookie attributes ----------------------------------------------
    set_cookies = headers.get("Set-Cookie") or headers.get("set-cookie") or ""
    # urllib joins multiple Set-Cookie; also capture via .get_all below.
    try:
        raw_cookies = headers.get_all("Set-Cookie") or []
    except AttributeError:
        raw_cookies = [set_cookies] if set_cookies else []
    cookies = []
    for c in raw_cookies:
        name = c.split("=", 1)[0].strip()
        cookies.append({
            "name": name,
            "httponly": "httponly" in c.lower(),
            "secure": "secure" in c.lower(),
            "samesite": next(
                (p.split("=", 1)[1].strip() for p in c.split(";")
                 if p.strip().lower().startswith("samesite=")),
                None,
            ),
        })
    out["cookies"] = cookies

    # --- HTML body fingerprints -----------------------------------------
    out["html_fingerprints"] = {
        "title": (re.search(r"<title[^>]*>(.*?)</title>", body, re.I | re.S).group(1).strip()
                  if re.search(r"<title[^>]*>(.*?)</title>", body, re.I | re.S) else None),
        "generator_meta": (re.search(r'<meta[^>]+name=["\']generator["\'][^>]+content=["\']([^"\']+)',
                                     body, re.I).group(1)
                           if re.search(r'<meta[^>]+name=["\']generator["\']', body, re.I) else None),
        "angular_hint": ("ng-version" in body) or ("main.js" in body),
        "has_form": "<form" in body.lower(),
        "body_len": len(body),
    }

    # --- Technology guesses ---------------------------------------------
    tech = []
    srv = (out["server"] or "").lower()
    xpb = (out["x_powered_by"] or "").lower()
    if "express" in xpb or "x-powered-by" in low_headers and "express" in xpb:
        tech.append("Express.js (from X-Powered-By)")
    if "node" in xpb:
        tech.append("Node.js (from X-Powered-By)")
    if srv:
        tech.append(f"Web server banner: {out['server']}")
    if out["html_fingerprints"]["angular_hint"]:
        tech.append("Angular SPA (from bundled main.js / ng-version)")
    if "juice" in body.lower() or "juice-shop" in body.lower():
        tech.append("OWASP Juice Shop (application branding in HTML)")
    out["technology_guesses"] = tech

    return out


def main():
    ap = argparse.ArgumentParser(description="CS-02 authorized lab HTTP fingerprinter")
    ap.add_argument("url", help="URL to fingerprint (lab only)")
    ap.add_argument("--json", help="Write JSON results to this file")
    args = ap.parse_args()

    result = analyze(args.url)

    if "error" in result:
        print(f"[!] Fetch error: {result['error']}")
        sys.exit(1)

    print("=" * 64)
    print(f"URL        : {result['url']}")
    print(f"Status     : {result['status']}")
    print(f"Server     : {result['server']}")
    print(f"X-Powered  : {result['x_powered_by']}")
    print("=" * 64)
    print("\n[Security headers PRESENT]")
    if result["security_headers_present"]:
        for h in result["security_headers_present"]:
            print(f"  + {h['header']}: {h['value'][:70]}")
    else:
        print("  (none)")
    print("\n[Security headers MISSING]")
    for h in result["security_headers_missing"]:
        print(f"  - {h}")
    print("\n[Cookies]")
    if result["cookies"]:
        for c in result["cookies"]:
            print(f"  {c['name']}: HttpOnly={c['httponly']} Secure={c['secure']} "
                  f"SameSite={c['samesite']}")
    else:
        print("  (no Set-Cookie on this response)")
    print("\n[Technology guesses]")
    for t in result["technology_guesses"]:
        print(f"  * {t}")

    if args.json:
        with open(args.json, "w") as fh:
            json.dump(result, fh, indent=2)
        print(f"\n[+] JSON written to {args.json}")


if __name__ == "__main__":
    main()
