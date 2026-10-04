# WEB-VUL-004 — Sensitive information disclosure

## 1. Finding ID
WEB-VUL-004

## 2. Title
Unauthenticated exposure of deployment/internal information

## 3. Affected Component
OWASP Juice Shop serving layer, three public endpoints:
`/metrics`, `/rest/admin/application-version`, `/robots.txt`

## 4. URL / Endpoint
- `GET http://127.0.0.1:3000/metrics`
- `GET http://127.0.0.1:3000/rest/admin/application-version`
- `GET http://127.0.0.1:3000/robots.txt`

## 5. HTTP Method
GET (unauthenticated)

## 6. Security Category
Security Misconfiguration / Sensitive Information Exposure

## 7. Description
Three unauthenticated endpoints return information that should not be public:
Prometheus-style telemetry, the deployed application version, and a robots.txt
directing crawlers to the `/ftp` directory. None of these should be reachable without
an authenticated session.

## 8. Technical Details
**Observed responses (all unauthenticated, HTTP 200):**

| Endpoint | Observed |
|---|---|
| `/metrics` | `HTTP 200`, 25,640 bytes of telemetry (`# HELP juiceshop_llm_input_tokens_total ...`) |
| `/rest/admin/application-version` | `HTTP 200`, `{"version":"20.2.0"}` |
| `/robots.txt` | `HTTP 200`, `User-agent: *\nDisallow: /ftp` |

**Evidence IDs:**
- Historical: `evidence/responses/WEB-VUL-004-metrics.txt`, `evidence/responses/WEB-VUL-004-version.txt`, `evidence/findings/WEB-VUL-004-validation.txt`
- Current-instance validation: `EVID-REVERIFY-C4-disclosure.txt`

## 9. Reproduction
1. Open `http://127.0.0.1:3000`.
2. Issue `GET /metrics` (requires no login) and observe 25 KB of internal telemetry.
3. Issue `GET /rest/admin/application-version` — observe the app version string.
4. Issue `GET /robots.txt` — observe the `/ftp` path hint.
5. Comparison: these values are deployment internals that should require authentication.

## 10. Observed Behaviour
Three public paths return internal information without any authentication. The
application version is trivially discoverable, and the `/ftp` hint reveals an
application sub-path that may contain additional content.

## 11. Potential Impact
The observed behaviour may expose deployment details (server telemetry, exact
application version, internal directory structure) to unauthenticated visitors.
Consequence: information for fingerprinting, mapping and planning further (potentially
targeted) attacks against the lab application is readily obtainable by any visitor.

## 12. Severity
Medium

## 13. Severity Justification
- The disclosed data is reconnaissance-oriented, not directly exploitable data (no
  credentials, tokens or personal records)
- No special authentication is required to obtain it
- The disclosure is read-only and confined to the lab; impact grows only if combined with
  other findings

## 14. Recommendation
Require authentication for `/metrics` (or disable the endpoint), remove the
`/rest/admin/application-version` endpoint (or restrict it to authorised admin sessions),
and review the intended purpose of `/ftp` and `robots.txt` so no unintended paths are
advertised. Re-run the same three requests after the change and confirm HTTP 401/403 or
removal.

## 15. Remediation Status
Not Remediated

## 16. Retest Status
Re-tested — STILL OPEN (confirmed 2026-10-04, independent re-verification)

Re-run against the live lab after a full application restart. All three endpoints
still answered HTTP 200 with no token: `/metrics`, `/rest/admin/application-version`
and `/robots.txt`. The Prometheus endpoint continues to serve telemetry and the
version endpoint continues to disclose the deployed release. No remediation is in
place, so the finding remains open.

## 17. Evidence IDs
- `evidence/responses/WEB-VUL-004-metrics.txt`, `evidence/responses/WEB-VUL-004-version.txt`
- `EVID-REVERIFY-C4-disclosure.txt`
- `evidence/findings/V-004-validation.txt` (independent re-test, 2026-10-04)
