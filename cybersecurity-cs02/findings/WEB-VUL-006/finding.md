# WEB-VUL-006 — Broken Function-Level Authorization on the user directory API

## 1. Finding ID
WEB-VUL-006

## 2. Title
A `customer`-role account can read the full admin-only user directory

## 3. Affected Component
OWASP Juice Shop user REST API (`/api/Users`, `/api/Users/:id`), SQLite application
database (`Users` table)

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/api/Users`
`GET http://127.0.0.1:3000/api/Users/1` (administrator record)

## 5. HTTP Method
GET

## 6. Security Category
Broken Access Control — missing function-level authorization (OWASP API1:2023
Broken Object Level Authorization / A01:2021)

## 7. Description
The user-management API is protected by an authentication check only. Once a caller
holds *any* valid JWT, including one issued to a freshly self-registered account with
the `customer` role, the full user directory is returned. There is no role check
restricting the endpoint to `admin`. An anonymous caller is correctly rejected with
401, so the flaw is an authorization failure behind the authentication boundary rather
than an unauthenticated exposure.

## 8. Technical Details
Three requests to the same endpoint, differing only in the bearer token:

| Token | Result |
|---|---|
| none | `401` |
| `customer` role | **`200` + the entire user directory** |
| `admin` role | `200` + the entire user directory |

The customer response discloses for every account: `id`, `email`, `role`,
`profileImage`, `lastLoginIp`, `isActive`, `deluxeToken`, and timestamps. This yields a
complete list of administrator accounts and their email addresses, which is the
credential-targeting step for credential-stuffing and phishing.

The same caller can also fetch any individual record via `/api/Users/:id`, including
`/api/Users/1` (the administrator).

Note on scope: the `password` attribute is stripped from the `/api/Users` responses, so
this finding exposes the user directory and role map, not password hashes. The password
hash leak is tracked separately as WEB-VUL-007.

Write access was probed and is **not** reachable: `PATCH /api/Users/1` and
`PATCH /api/Users/25` (self-escalation to `role: admin`) both return
`500 Unexpected path`, so privilege escalation was not demonstrated. This finding is
therefore classified as unauthorized **read** access.

## 9. Reproduction
1. Register a new account: `POST /api/Users` with a fresh email address → `201`,
   the account is created with `role: customer`.
2. Log in as that account: `POST /rest/user/login` → keep the returned `token`.
3. `GET /api/Users` with `Authorization: Bearer <customer token>` → `200`.
4. Observe the whole directory (24 seeded accounts; 25 with the test account)
   including `admin@juice-sh.op`, `bjoern@juice-sh.op` and
   `support@juice-sh.op`, each with `role: admin`.
5. Control: repeat with no header → `401`.

## 10. Observed Behaviour
```
no token       -> HTTP 401
customer token -> HTTP 200   (full user directory)
admin token    -> HTTP 200   (full user directory)
```

## 11. Potential Impact
Any registered customer — the lowest privilege tier, obtainable in seconds by anyone
who can reach the registration form — can enumerate every account in the system with
its role. This gives an attacker an exact target list of administrator accounts for
credential stuffing, targeted phishing, or password-spraying, and maps the internal
role structure. Combined with WEB-VUL-007 (password hashes recoverable from a token),
the exposure becomes a direct path to account takeover of any of the 24 accounts.

## 12. Severity
High

## 13. Severity Justification
- Reachable by the lowest-privilege authenticated user, so the barrier to entry is
  registration alone
- Discloses the complete account and role directory of the system
- Directly enables credential attacks against named administrator accounts
- No rate limiting or additional privilege is needed to enumerate all records
- Not rated Critical because the endpoint is read-only: write access and role
  escalation were tested and did not succeed

## 14. Recommendation
Enforce role-based authorization on the user-management routes, not just
authentication. Reject any caller whose token role is not `admin` (or `accounting` for
the accounting-scoped fields) before the handler runs, and scope `/api/Users/:id`
reads so a caller may only ever retrieve their own record. Remove `email`, `role`,
`lastLoginIp`, `deluxeToken` and `isActive` from any non-admin projection. Re-test the
three-token matrix above; the customer row must return `403`.

## 15. Remediation Status
Not Remediated

## 16. Retest Status
Re-tested — STILL OPEN (re-validated 2026-10-04 against the live baseline, port 3000)

The three-token authorization matrix was re-run against the running application:

| Token | `GET /api/Users` |
|---|---|
| none | HTTP 401 |
| `customer` role | **HTTP 200 — 25 user records returned** |
| `admin` role | HTTP 200 |

The disclosed directory still contains every administrator address and role, which is
exactly the credential target list an attacker needs. No remediation was applied, so no
"fixed" claim is made.

Evidence: `evidence/findings/V-006-validation.txt` (regenerable with
`bash scripts/capture-verification-evidence.sh`). The test customer account is created by
that script through the same unauthenticated `POST /api/Users` path that forms part of the
attack, so the finding remains reproducible after a database reset.

## 17. Evidence IDs
- `evidence/findings/V-006-validation.txt` (reproduced against the running lab)
- Regenerate with `bash scripts/capture-verification-evidence.sh`