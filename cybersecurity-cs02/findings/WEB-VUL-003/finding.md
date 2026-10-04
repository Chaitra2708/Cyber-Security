# WEB-VUL-003 — Missing HTTP security headers

## 1. Finding ID
WEB-VUL-003

## 2. Title
Missing security HTTP response headers

## 3. Affected Component
OWASP Juice Shop serving layer (`GET /` homepage) — HTTP response headers

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/`
(and by extension all responses from the application)

## 5. HTTP Method
GET

## 6. Security Category
Security Misconfiguration

## 7. Description
The application does not set a standard set of HTTP security headers. Missing
headers weaken browser-side protections against clickjacking, content-type
sniffing, cross-site scripting defence nigation and information leakage via
referrer. The server response contains only three security-related headers.

## 8. Technical Details
**Observed headers on `GET /`:**
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Feature-Policy: payment 'self'
X-Recruiting: /#/jobs
Accept-Ranges: bytes
Cache-Control: public, max-age=0
...
```

**Non-standard control:** `Strict-Transport-Security`, `Content-Security-Policy`,
`X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy`,
`Cross-Origin-Opener-Policy`, and `Cross-Origin-Resource-Policy` are absent.

**Evidence IDs:**
- Historical: `evidence/responses/WEB-VUL-003-validation.txt`, `evidence/scanner-results/RECON-002-response-headers.txt`
- Current-instance validation: `EVID-REVERIFY-C3-headers.txt`

## 9. Reproduction
1. Open `http://127.0.0.1:3000`.
2. Open the browser dev tools Network tab and load the page (or issue `curl -D - http://127.0.0.1:3000/`).
3. Inspect the response headers.
4. Compare with a hardened baseline where `Strict-Transport-Security`,
   `Content-Security-Policy`, `Referrer-Policy`, `Permissions-Policy`,
   `Cross-Origin-Opener-Policy`, and `Cross-Origin-Resource-Policy` are present.
5. Observation: only `X-Content-Type-Options`, `X-Frame-Options`, and `Cache-Control`
   are present.

## 10. Observed Behaviour
Only three hardening headers are emitted. The application does not set the wider
set conventionally expected of a security-hardened web application, and adds an
`Access-Control-Allow-Origin: *` wildcard.

## 11. Potential Impact
The observed behaviour may weaken browser-side defences (clickjacking, MIME-sniffing,
referrer leakage). Impact in the laboratory is limited to the isolated app; in a
deployed system it increases the likelihood and severity of client-side attacks.

## 12. Severity
Medium

## 13. Severity Justification
- The missing security headers are situational: they reduce defence-in-depth rather than
  directly exposing data
- The header set is partially present, so the issue is a hardening gap rather than total
  absence
- The control (`Access-Control-Allow-Origin: *`) adds another low-severity weakness on
  top of the missing headers

## 14. Recommendation
Add a standardised security header set to every HTTP response, for example:
`Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options: nosniff`,
`X-Frame-Options: SAMEORIGIN`, `Referrer-Policy`, `Permissions-Policy`,
`Cross-Origin-Opener-Policy`, and `Cross-Origin-Resource-Policy`. Prefer a
well-audited HTTP header library (helmet) rather than hand-rolled headers, then
verify each header renders in a real browser/network inspector.

## 15. Remediation Status
Remediated (Phase 16, 2026-10-04) — hardening header middleware added in
`server.ts` + `build/server.js`; see `remediation/WEB-VUL-003/remediation.md` and
`docs/remediation.md`. Evidence: `EVID-REM-002` (before), `EVID-REM-004` (implementation).

## 16. Retest Status
Fixed (Phase 17, 2026-10-04T15:55:45+05:30) — same Phase 10 header enumeration re-run
against the mitigated instance: all 10 baseline headers PRESENT, headless-Chrome
verification shows 0 console/CSP violations with the application fully rendered.
Evidence: `EVID-RETEST-002` (`remediation/WEB-VUL-003/after/EVID-RETEST-002-headers-retest.txt`)

## 17. Evidence IDs
- `evidence/responses/WEB-VUL-003-validation.txt` (historical header capture)
- `EVID-REVERIFY-C3-headers.txt` (current-instance re-verification)
- `EVID-REM-002` (Phase 16 before-state), `EVID-REM-004` (Phase 16 remediation record)
- `EVID-RETEST-002` (Phase 17 retest — FIXED)
