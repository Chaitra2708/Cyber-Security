# Remediation Record — WEB-VUL-003 (Phase 16)

**Finding:** WEB-VUL-003 — Missing HTTP security headers
**Application:** http://127.0.0.1:3000 (OWASP Juice Shop v20.2.0, local lab)
**Remediation implemented:** 2026-10-04T15:44–15:50+05:30
**Remediation Status:** Remediated (retest: Phase 17)

## Root Cause

The serving layer only enabled two helmet middlewares, so responses carried
only `X-Content-Type-Options` (noSniff) and `X-Frame-Options` (frameguard).
Seven standard hardening headers were never set:

`Strict-Transport-Security`, `Content-Security-Policy`, `X-XSS-Protection`,
`Referrer-Policy`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`,
`Cross-Origin-Resource-Policy`

Relevant code (`server.ts`):

```ts
/* Security middleware */
app.use(helmet.noSniff())
app.use(helmet.frameguard())
// app.use(helmet.xssFilter()); // = no protection from persisted XSS via RESTful API
app.disable('x-powered-by')
```

## File(s) Changed

As with WEB-VUL-001, source and compiled runtime were changed identically:

1. `lab/juice-shop_20.2.0/server.ts` (source, "Security middleware" block)
2. `lab/juice-shop_20.2.0/build/server.js` (compiled — the file actually executed)

## Original Behavior

```text
GET http://127.0.0.1:3000/  →  HTTP 200 with only:
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
  Feature-Policy: payment 'self'
  (all 7 baseline hardening headers MISSING)
```

Before-evidence: `remediation/WEB-VUL-003/before/EVID-REM-002-headers-before.txt`
(captured 2026-10-04T15:43:03+05:30 on the unmodified instance), plus original
Phase 10 evidence `evidence/reverification/EVID-REVERIFY-C3-headers.txt`.

## Mitigation Implemented

Added one middleware in the existing "Security middleware" block that sets the
seven missing headers on every response:

```ts
app.use((req: Request, res: Response, next: NextFunction) => {
  res.setHeader('Referrer-Policy', 'no-referrer')
  res.setHeader('X-XSS-Protection', '1; mode=block')
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin')
  res.setHeader('Cross-Origin-Resource-Policy', 'same-origin')
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
  res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'sha256-2ADpmZIga9zdrCfzZ7IWyavasltpcKCkxomklfMTCG0=' 'unsafe-hashes' 'sha256-MhtPZXr7+LpJUY5qtMutB+qWfQtMaPccfe7QXtCcEYc='; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' ws://127.0.0.1:3000 wss://127.0.0.1:3000; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'")
  next()
})
```

The identical block was inserted into `build/server.js` after the `frameguard()`
call.

### CSP design notes (functionality preserved)

- The first, stricter draft (`script-src 'self'`) was browser-tested and found to
  block two legitimate inline pieces in the served `index.html`: the
  cookie-consent initializer and the `onload="this.media='all'"` handler on the
  `styles.css` link (which would have left the app unstyled).
- Rather than weaken the policy with `'unsafe-inline'`, those two exact
  snippets are allow-listed by SHA-256 hash (`'unsafe-hashes'` for the event
  handler). All other inline scripts remain blocked.
- `font-src` additionally allows `https://fonts.gstatic.com` because the page's
  `@font-face` declarations reference that host (blocked otherwise).
- No `upgrade-insecure-requests` (would break plain-HTTP localhost), no
  `payment` in Permissions-Policy (already covered by the existing
  Feature-Policy header, avoids a duplicate-feature browser warning).
- HSTS is set as best practice; browsers ignore it over plain HTTP, so it is
  inert for the localhost lab and only takes effect if served over HTTPS.

## Why This Mitigates the Finding

Every response now carries the complete hardening header set: clickjacking
defence is extended to cross-origin embedding (COOP/CORP + frame-ancestors),
MIME-sniffing and XSS filters are enabled, referrer leakage is eliminated,
powerful browser features are denied by default, and a CSP constrains the
sources of scripts/styles/connect targets that the browser will accept.

## Expected Secure Behavior

```text
GET /  →  all 7 baseline headers present + X-Content-Type-Options, X-Frame-Options
Browser loads the app with 0 CSP violations and full functionality
```

## Application Status After Change

- `node --check build/server.js` → syntax OK
- App started via `scripts/start-lab.sh` → `LAB STATUS: PASS`, HTTP 200 on `/`
- All 9 baseline headers present (see `remediation/safety-check-phase16.txt`)
- Headless Chrome (isolated profile): **0 console/CSP messages**,
  `styles.css` switched to `media="all"` (inline handler executed),
  product grid rendered → functionality preserved
- Legitimate login, product API, own-basket read, frontend bundle → HTTP 200
