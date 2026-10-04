# WEB-VUL-001 — SQL Injection authentication bypass

## 1. Finding ID
WEB-VUL-001

## 2. Title
SQL Injection in the login endpoint bypasses authentication

## 3. Affected Component
OWASP Juice Shop login API (`/rest/user/login`), backend Node.js/Express layer

## 4. URL / Endpoint
`POST http://127.0.0.1:3000/rest/user/login`

## 5. HTTP Method
POST

## 6. Security Category
Authentication — Injection / Broken Authentication

## 7. Description
The login endpoint accepts the user-supplied email and password and embeds them in a
database query without server-side sanitisation. Providing a specially crafted email
value causes the underlying SQL statement to be modified so that the authentication
check succeeds without a valid password, issuing an administrator-role session token.

## 8. Technical Details
The login handler builds a SQL query from the request body's `email` field. The
`email` parameter is interpreted as SQL, so the payload `' OR 1=1--` rewrites the
WHERE clause to a tautology and dumps the first matching record (the seeded admin
account). The backend then signs a JWT for that record with `"role":"admin"`.

**Observed request:** `POST /rest/user/login` with:
```json
{"email":"' OR 1=1--","password":"x"}
```

**Observed response** (JWT payload redacted for safety):
```json
{"authentication":{"token":"[REDACTED-JWT]","bid":1,"umail":"admin@juice-sh.op","role":"admin",...}}
HTTP 200
```

**Evidence IDs:**
- Historical: `evidence/requests/WEB-VUL-001-request.txt`, `evidence/responses/WEB-VUL-001-response.txt`
- Current-instance validation: `EVID-REVERIFY-C1-sqli.txt`

## 9. Reproduction
1. Open `http://127.0.0.1:3000` ( authorised lab ).
2. Open the browser dev console or use `curl`.
3. Send `POST http://127.0.0.1:3000/rest/user/login` with the JSON body:
   ```json
   {"email":"' OR 1=1--","password":"x"}
   ```
4. Observe the HTTP status (`200`) and the JWT payload containing an admin account and
   `"role":"admin"`.
5. Comparison: with invalid credentials the application correctly returns `401`

## 10. Observed Behaviour
With the payload above the server returns HTTP 200 and an active admin-role JWT. The
control request (invalid credentials) correctly returned 401.

## 11. Potential Impact
The observed behaviour may allow an unauthenticated attacker to obtain an administrator
session token without credentials. Consequence: full administrative access to the
vulnerable training application, its data and functions in the laboratory.

## 12. Severity
High

## 13. Severity Justification
- Authentication bypass (no credentials required)
- Authentication state is impersonated as administrator rather than as a random user
- Attacker needs only HTTP access to the authorised lab port; no special rights
- Impact is confined to the isolated lab, but the logical consequence is privilege
  escalation to admin of the web application itself

## 14. Recommendation
Implement parameterised queries / prepared statements for the login check, so the email
is always treated as data and never as SQL. Add server-side authentication outcome
verification (e.g. a successful login must be re-checked against the returned record
fields).

## 15. Remediation Status
Remediated (Phase 16, 2026-10-04) — parameterised query in `routes/login.ts` +
`build/routes/login.js`; see `remediation/WEB-VUL-001/remediation.md` and
`docs/remediation.md`. Evidence: `EVID-REM-001` (before), `EVID-REM-003` (implementation).

## 16. Retest Status
Fixed (Phase 17, 2026-10-04T15:55:24+05:30) — same Phase 10 procedure re-run against
the mitigated instance: both payloads (`' OR 1=1--` and `' OR '1'='1' --`) now return
HTTP 401; legitimate seeded login still returns HTTP 200.
Evidence: `EVID-RETEST-001` (`remediation/WEB-VUL-001/after/EVID-RETEST-001-sqli-retest.txt`)

## 17. Evidence IDs
- `evidence/requests/WEB-VUL-001-request.txt` (historical request)
- `evidence/responses/WEB-VUL-001-response.txt` (historical response, token redacted)
- `EVID-REVERIFY-C1-sqli.txt` (current-instance re-verification)
- `EVID-REM-001` (Phase 16 before-state), `EVID-REM-003` (Phase 16 remediation record)
- `EVID-RETEST-001` (Phase 17 retest — FIXED)
