# WEB-VUL-002 — Broken Access Control / IDOR on shopping baskets

## 1. Finding ID
WEB-VUL-002

## 2. Title
Object-level access control gap on `/rest/basket/:id`

## 3. Affected Component
OWASP Juice Shop REST API (`/rest/basket/:id`), basket data of other authenticated
users

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/rest/basket/:id`

## 5. HTTP Method
GET

## 6. Security Category
Authorization — Broken Object Level Authorization (BOLA / IDOR); cross-user data access

## 7. Description
The basket endpoints return another user's shopping basket when the JSON data
contains the owner's user ID. The API authenticates the caller with any valid token,
but it does not verify that the requested basket belongs to that caller. Any
authenticated user (or an attacker who has stolen any user's token) can enumerate
basket IDs and read other users' contents.

## 8. Technical Details
A valid bearer JWT is accepted; no ownership check (`basket.UserId === request.user.id`)
is performed. The response embeds `UserId` and the basket's products, so a caller can
read the items of an unrelated account.

**Observed request:** `GET /rest/basket/2` with `Authorization: Bearer <admin JWT>`.
**Observed response** (first record redacted for privacy):
```json
{"status":"success","data":{"id":2,"coupon":null,"UserId":2,
  "Products":[{"id":4,"name":"Raspberry Juice (1000ml)",...}]}}
HTTP 200
```
(The admin is UserId 1, so the response discloses a basket owned by a different user,
UserId 2.)

**Evidence IDs:**
- Historical: `evidence/responses/WEB-VUL-002-victim-basket.json`, `evidence/requests/WEB-VUL-002-request.txt`
- Current-instance validation: `EVID-REVERIFY-C2-idor.txt`

## 9. Reproduction
1. Log in to `http://127.0.0.1:3000` (obtain any valid session token).
2. Request `GET http://127.0.0.1:3000/rest/basket/2` with the token as a Bearer header.
3. Observe HTTP 200 containing `"UserId": 2` and that user's basket items.
4. Comparison: the same account's own basket is a separate entity; no code-level ownership
   check is applied before the row is returned.

## 10. Observed Behaviour
A valid authenticated request returns another user's basket data with HTTP 200. Unauthenticated
requests receive 401, so the endpoint is protected against anonymous use, but not against
cross-user access by any authenticated principal.

## 11. Potential Impact
The observed behaviour may allow any authenticated account to read another user's basket
contents (product names, quantities, pricing). Consequence in the lab: disclosure of other
users' purchased items; in a real system this class of flaw (BOLA) typically underpins
account-takeover-grade data exposure and is a starting point for further abuse.

## 12. Severity
High

## 13. Severity Justification
- Authentication is required (any valid token), but authorisation (ownership) is not checked
- The vulnerable endpoint is directly reachable (no permission escalation to be gained first)
- Disclosure is of sensitive user-specific shopping data, which is generally considered
  confidential in a real application

## 14. Recommendation
Enforce object-level ownership on every `/rest/basket` read: reject a request unless
`basket.UserId === authenticatedUserId`. Validate that a basket exists before returning it.

## 15. Remediation Status
Remediated (third remediation, 2026-10-04) — shared ownership guard
`ensureBasketOwnership()` wired into `GET /rest/basket/:id`,
`POST /rest/basket/:id/checkout` and `PUT /rest/basket/:id/coupon/:coupon` in
`routes/basket.ts` + `server.ts` (and their compiled `build/` equivalents).
See `remediation/WEB-VUL-002/remediation.md` and `docs/remediation.md`.
Evidence: `EVID-REM-006` (before), `EVID-REM-007` (implementation).

## 16. Retest Status
Fixed (2026-10-04T16:46:17+05:30) — same reproduction as S9 re-run against the
mitigated instance: cross-user basket read now returns HTTP 403 (was 200 with
victim contents); cross-user coupon write returns HTTP 403; own-basket read,
full legitimate basket flow, and unknown-id behaviour unchanged.
Evidence: `EVID-RETEST-004` (`remediation/WEB-VUL-002/after/EVID-RETEST-004-idor-retest.txt`).

## 17. Evidence IDs
- `evidence/responses/WEB-VUL-002-victim-basket.json` (historical basket read)
- `EVID-REVERIFY-C2-idor.txt` (current-instance re-verification)
- `EVID-REM-006` (Phase 16/18 third-remediation before-state)
- `EVID-REM-007` (remediation implementation record)
- `EVID-RETEST-004` (retest — FIXED)
- `EVID-TEST-006`, `EVID-TEST-007`, `EVID-TEST-008` (test-suite validation)
