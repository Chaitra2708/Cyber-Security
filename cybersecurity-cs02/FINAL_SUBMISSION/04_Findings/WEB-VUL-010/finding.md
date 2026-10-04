# WEB-VUL-010 — Wildcard CORS policy with full method and header allowance

## 1. Finding ID
WEB-VUL-010

## 2. Title
API returns `Access-Control-Allow-Origin: *` for every origin with no allow-list

## 3. Affected Component
OWASP Juice Shop CORS handling (Helmet/CORS middleware configured in `server.ts`),
applied to all `/rest/*` and `/api/*` responses

## 4. URL / Endpoint
`OPTIONS http://127.0.0.1:3000/rest/user/login`
`GET http://127.0.0.1:3000/` (and every API response)

## 5. HTTP Method
OPTIONS (preflight), and any subsequent cross-origin request

## 6. Security Category
Security Misconfiguration — permissive cross-origin policy (A05:2021)

## 7. Description
Every response carries `Access-Control-Allow-Origin: *` regardless of the requesting
`Origin`, and the preflight response additionally advertises the full set of write
methods and reflects `authorization` and `content-type` as permitted request headers.
There is no origin allow-list, so any website a user or administrator visits can issue
cross-origin requests to the API from the victim's browser and read the responses.

The application is unusually well hardened at the browser layer — a strict
Content-Security-Policy, `X-Frame-Options: SAMEORIGIN`, `Cross-Origin-Opener-Policy` and
`Cross-Origin-Resource-Policy: same-origin` are all present (WEB-VUL-003 remediated) —
which makes the wildcard CORS the one remaining gap that defeats that browser-side
defence. Note that `Access-Control-Allow-Credentials` is **not** set, so the browser
will not attach cookies; the exposure is therefore limited to responses that do not
require ambient cookie credentials, and the practical impact is correspondingly
bounded. It is reported as a real misconfiguration rather than a demonstrated
high-severity breach.

## 8. Technical Details
Preflight from an attacker-controlled origin:
```
OPTIONS /rest/user/login
  Origin: https://evil.example
  Access-Control-Request-Method: POST
  Access-Control-Request-Headers: authorization,content-type

HTTP/1.1 204 No Content
  Access-Control-Allow-Origin: *
  Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
  Access-Control-Allow-Headers: authorization,content-type
```

Simple GET with an attacker origin:
```
GET /rest/products/search?q=a
  Origin: https://evil.example

  Access-Control-Allow-Origin: *
```

The origin is reflected as `*` rather than echoed, so responses are readable by any
site. The advertised method list includes `PUT`, `PATCH` and `DELETE`, and the header
list includes `authorization`.

## 9. Reproduction
1. Send `OPTIONS /rest/user/login` with
   `Origin: https://evil.example`,
   `Access-Control-Request-Method: POST`,
   `Access-Control-Request-Headers: authorization,content-type`.
2. Observe `Access-Control-Allow-Origin: *`, the full write-method list, and the
   reflected `authorization` header.
3. Repeat with any other arbitrary origin; the value is unchanged.

## 10. Observed Behaviour
The same wildcard is returned for every origin tested, with no allow-list in effect.

## 11. Potential Impact
Any origin can read unauthenticated API responses cross-site, which widens the reach of
the disclosures in WEB-VUL-004, WEB-VUL-005 and WEB-VUL-008: a user only has to visit
an attacker page for that content to be harvested from their browser. Combined with any
future script-execution flaw on the site, the permissive CORS would let injected code
read API responses from the authenticated origin. Because credentials are not
allow-listed, this does not by itself permit authenticated cross-origin reads, which
is the main reason it is rated Medium.

## 12. Severity
Medium

## 13. Severity Justification
- Affects every response on the API, so it amplifies the reach of other findings
- Enables cross-origin harvesting of the application data that is already public
- `Access-Control-Allow-Credentials` is absent, so ambient cookie credentials are not
  attached and authenticated cross-origin reads are not achievable from this alone
- The strict CSP and same-origin resource policy already in place reduce the practical
  exploitation path
- Rated Medium because it is a genuine configuration weakness with a bounded, rather
  than direct credential-compromising, impact

## 14. Recommendation
Replace the wildcard with an explicit allow-list of trusted origins and reflect only an
origin that appears in that list. Do not combine a wildcard origin with credentialed
requests. If the SPA is served from the same origin — as it is here, since
`http://127.0.0.1:3000` serves both the UI and the API — no cross-origin access is
required at all, so the policy can be removed entirely. Re-test the preflight in
section 9 and confirm an unlisted origin receives no `Access-Control-Allow-Origin`.

## 15. Remediation Status
**Remediation implemented (2026-10-04)** — REMED-001. CORS changed from the wildcard
`cors()` to an allow-list array of the application's own origins, in
`build/server.js` and `server.ts`, in a separate remediation copy
(`lab/juice-shop_20.2.0-remediated`, port 3001). The vulnerable baseline
(`lab/juice-shop_20.2.0`, port 3000) was left unmodified and still runs.

## 16. Retest Status
**RETESTED — REMEDIATED** (2026-10-04)

The same `OPTIONS` preflight with `Origin: https://evil.example` was replayed against
both instances. Baseline returned `Access-Control-Allow-Origin: *`; the remediated
instance returns HTTP 204 with **no** `Access-Control-Allow-Origin` header. A control
request with the legitimate own origin still receives the header, confirming no
functional regression.

The fix required three attempts before being correct — a string `origin` is echoed
without validation, and a callback returning falsy breaks the preflight status. The
working form is an allow-list array. See `docs/retesting.md` for the detail.

## 17. Evidence IDs
- `evidence/findings/V-010-validation.txt` (preflight and simple-request headers)
- `evidence/remediation/REMED-before.txt` (vulnerable baseline)
- `evidence/remediation/REMED-after.txt` (remediated instance, side-by-side)
- `evidence/screenshots/REMED-001-after-remediated-ui.png` (UI renders after remediation)
- Regenerate with `bash scripts/capture-verification-evidence.sh`