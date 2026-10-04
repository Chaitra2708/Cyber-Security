# Phase 16 — Remediation

## Scope

Target:
http://127.0.0.1:3000

Authorized scope: `127.0.0.1:3000` ONLY (local OWASP Juice Shop v20.2.0).
No other host, port, service or system was touched.

## Remediation Objective

Two feasible mitigations were selected from the confirmed vulnerability findings.

## Selection Record (16.2)

Selection was based on **technical feasibility only** (root cause understood,
affected code identifiable, safe local reversible change, objectively
re-testable) — not on severity, and the findings were not ranked.

```text
Remediation Target 1:
Finding ID: WEB-VUL-001 (SQL injection authentication bypass)
Reason mitigation is feasible: The root cause is a single raw-query line in
routes/login.ts / build/routes/login.js (string concatenation of req.body.email).
The fix is a minimal, well-understood swap to a parameterised query using
Sequelize replacements; login flow, TOTP branch and password hashing stay
identical, the change is a few lines, easily reversible, and the exact Phase 10
reproduction (payload → HTTP 200/admin JWT) gives an objective re-test.

Remediation Target 2:
Finding ID: WEB-VUL-003 (Missing HTTP security headers)
Reason mitigation is feasible: The root cause is configuration-level in one
block of server.ts / build/server.js (only two helmet middlewares enabled).
Adding the seven missing response headers is a contained, reversible change to
the serving layer with no data/logic impact, and header presence is trivially
objectively re-testable with the same curl header enumeration used in Phase 10.
```

Not selected (feasible but out of scope this phase): WEB-VUL-002, WEB-VUL-004,
WEB-VUL-005 — per instruction exactly two findings are remediated.

## Remediation 1

### Finding

WEB-VUL-001 — SQL injection authentication bypass

### Root Cause

`/rest/user/login` embedded unsanitised `req.body.email` (and password) directly
into a raw SQL string via template-literal concatenation, so the payload
`' OR 1=1--` rewrote the WHERE clause into a tautology and returned the seeded
admin record → admin-role JWT.

### Before State

```text
POST /rest/user/login {"email":"' OR 1=1--","password":"x"}
→ HTTP 200, token for umail "admin@juice-sh.op" (bid 1)
Control (invalid credentials) → HTTP 401
```

Captured on the unmodified instance at 2026-10-04T15:42:55+05:30.
Original Phase 10 evidence: `evidence/reverification/EVID-REVERIFY-C1-sqli.txt`.

### Mitigation

Replaced the concatenated query with a parameterised query using Sequelize named
`replacements` (`email = :email AND password = :password`), so request values
are bound and escaped as data instead of parsed as SQL. Query semantics
(columns, `deletedAt IS NULL`, hashed password comparison, TOTP branch) are
unchanged.

### Files Changed

- `lab/juice-shop_20.2.0/routes/login.ts` (TypeScript source)
- `lab/juice-shop_20.2.0/build/routes/login.js` (compiled runtime — the file
  executed by `node build/app`; changed identically because the packaged release
  ships no `tsconfig.json`, so a full `tsc` rebuild is not available)

### Expected Security Improvement

Injection payloads in `email`/`password` are treated as literal values;
authentication can no longer be forced with a tautology. Normal credential
login continues to work (verified with the seeded lab account).

### Evidence

- Before: `remediation/WEB-VUL-001/before/EVID-REM-001-sqli-before.txt` (EVID-REM-001)
- Implementation record: `remediation/WEB-VUL-001/remediation.md` (EVID-REM-003)
- Retest (Phase 17): `remediation/WEB-VUL-001/after/EVID-RETEST-001-*.txt`

## Remediation 2

### Finding

WEB-VUL-003 — Missing HTTP security headers

### Root Cause

The serving layer enabled only `helmet.noSniff()` and `helmet.frameguard()`;
seven standard hardening headers (HSTS, CSP, X-XSS-Protection, Referrer-Policy,
Permissions-Policy, COOP, CORP) were never emitted on any response.

### Before State

```text
GET / → HTTP 200 with only X-Content-Type-Options, X-Frame-Options (+ Feature-Policy, X-Recruiting, Cache-Control)
All 7 baseline hardening headers MISSING
```

Captured on the unmodified instance at 2026-10-04T15:43:03+05:30.
Original Phase 10 evidence: `evidence/reverification/EVID-REVERIFY-C3-headers.txt`.

### Mitigation

Added one middleware in the existing "Security middleware" block of `server.ts`
that sets all seven missing headers on every response. The CSP allow-lists the
page's two legitimate inline snippets by SHA-256 hash (`'unsafe-hashes'` for the
`onload` handler) instead of permitting all inline code, allows the Google Fonts
host referenced by the page's `@font-face` rules, and deliberately omits
`upgrade-insecure-requests` (which would break plain-HTTP localhost). Exact
header values and design rationale: `remediation/WEB-VUL-003/remediation.md`.

### Files Changed

- `lab/juice-shop_20.2.0/server.ts` (TypeScript source)
- `lab/juice-shop_20.2.0/build/server.js` (compiled runtime — changed identically,
  see above)

### Expected Security Improvement

Every response now carries the full hardening header set: clickjacking defence
extended cross-origin, referrer leakage eliminated, MIME-sniffing/XSS filters
enabled, powerful features denied by default, and a CSP restricting script,
style, font, image and connection sources.

### Evidence

- Before: `remediation/WEB-VUL-003/before/EVID-REM-002-headers-before.txt` (EVID-REM-002)
- Implementation record: `remediation/WEB-VUL-003/remediation.md` (EVID-REM-004)
- Retest (Phase 17): `remediation/WEB-VUL-003/after/EVID-RETEST-002-*.txt`

## Third Remediation — WEB-VUL-002

> Added after the original Phase 16 record (which remediated exactly two findings).
> The WEB-VUL-001 and WEB-VUL-003 records above are unchanged.

### Finding

WEB-VUL-002 — Basket IDOR (Broken Access Control / BOLA on `/rest/basket/:id`)

### Root Cause

All three basket-object routes loaded the basket row solely by the client-supplied
`req.params.id`; authentication existed but object-level authorization did not.
Any valid token could read **and modify** another user's basket:
`GET /rest/basket/:id` (retrieveBasket), `POST /rest/basket/:id/checkout`
(placeOrder — updates and empties the basket),
`PUT /rest/basket/:id/coupon/:coupon` (applyCoupon — `basket.update`).

### Before State

```text
GET /rest/basket/2 as admin (UserId 1) → HTTP 200 with UserId 2's basket
contents (Raspberry Juice ×2). Unauthenticated → 401 only.
Cross-user coupon PUT reached the basket-update path (rejected only for coupon
invalidity, 404). Cross-user checkout deliberately not executed pre-fix because
a success would destructively empty the seeded victim basket; the write-path gap
was established by source inspection instead.
```

Captured 2026-10-04T16:39+05:30 — `EVID-REM-006`
(`remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt`). Original evidence
`EVID-REVERIFY-C2-idor.txt` and `evidence/responses/WEB-VUL-002-victim-basket.json`
preserved unchanged.

### Mitigation

A single shared guard `ensureBasketOwnership()` (routes/basket.ts) loads the
basket by id and refuses with **HTTP 403** unless `basket.UserId` equals the
authenticated caller's user id (fail-closed if identity is unknown); unknown
basket ids continue to their original handler. The guard is wired before all
three handlers in `server.ts`.

### Files Changed

- `lab/juice-shop_20.2.0/routes/basket.ts` (guard implementation)
- `lab/juice-shop_20.2.0/server.ts` (route wiring, 3 routes)
- `lab/juice-shop_20.2.0/build/routes/basket.js` (compiled runtime)
- `lab/juice-shop_20.2.0/build/server.js` (compiled runtime)

### Security Improvement

Object-level authorization is now enforced on every basket-object request:
cross-user reads, coupon writes and checkouts are rejected before any handler
touches the row, closing the BOLA/IDOR on the read *and* write paths while
leaving own-basket behaviour identical.

### Validation

- Live functional flow: register → login → add item → read own basket →
  checkout own basket → 201/200/200/200/200 (order confirmation issued)
- Own-basket read 200, own-basket coupon 404 (invalid coupon, unchanged),
  unknown id 200/empty (unchanged), unauthenticated 401 (unchanged)
- Test suites (Node v22.23.3): basket API 13/22 pass — all 9 failures are
  cross-user/forged-JWT assertions of the fixed vulnerability (EVID-TEST-006);
  server unit 410/415 with the same 3 pre-existing package failures, unchanged
  (EVID-TEST-007); full API suite 476/537 with delta vs pre-fix run = 9 basket
  tests (intended) + 1 external GitHub fetch flake (EVID-TEST-008 vs EVID-TEST-003).
  No test was modified.

### Evidence

- Before: `remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt` (EVID-REM-006)
- Implementation: `remediation/WEB-VUL-002/remediation.md` (EVID-REM-007)
- Retest: `remediation/WEB-VUL-002/after/EVID-RETEST-004-idor-retest.txt` (EVID-RETEST-004) — FIXED
- Tests: `evidence/phase18-test-suite/EVID-TEST-006..008`

### Limitations (this remediation)

- 9 upstream basket tests fail because they assert the removed cross-user
  behaviour; tests were left untouched per project rules.
- Admin cross-basket access is also denied (Juice Shop has no legitimate
  admin basket-management flow).
- `basketAccessChallenge` still evaluates its condition, but the rewarded data
  access now returns 403.

---

## Application Verification

Safety check record: `remediation/safety-check-phase16.txt` (EVID-REM-005).

- [x] Application starts (`scripts/start-lab.sh` → `LAB STATUS: PASS`)
- [x] http://127.0.0.1:3000 remains accessible (HTTP 200)
- [x] No unrelated functionality was intentionally changed
  - Controls: legitimate login 200, `/api/Products` 200, own-basket read 200,
    `/main.js` 200, `/rest/user/whoami` 200
  - Headless Chrome: app renders, **0 console/CSP messages**, stylesheet active
    (`media="all"` after load)
- [x] Both mitigations correspond to confirmed findings (WEB-VUL-001, WEB-VUL-003)
- [x] Original evidence remains preserved (Phase 10 `EVID-REVERIFY-*`, historical
  `evidence/*` untouched; before-states captured before any edit)
- [x] Changed files documented (4 files, listed above)
- [x] No fabricated results (all outputs captured with `curl` / headless Chrome
  on the authorized target)

## Limitations

- **No claim of success yet:** per specification, mitigations are only claimed
  effective after the Phase 17 retest (`docs/retesting.md`).
- The packaged release has no `tsconfig.json`, so changes were applied to both
  the TS source and the compiled `build/` output instead of via `tsc`. A future
  rebuild from source would need the missing tsconfig restored.
- The mitigation intentionally changes the behavior of Juice Shop's own
  login coding-challenge (`loginAdminChallenge` and related); this is the direct
  purpose of the fix, not collateral damage.
- CSP still allows `style-src 'unsafe-inline'` and `script-src 'self'` plus two
  hash-allow-listed inline snippets — the minimum needed for the application to
  function unmodified; it is not a claim of a maximally strict policy.
- HSTS is inert over plain-HTTP localhost by browser design; it only takes
  effect if the app is later served over HTTPS.
- The pre-existing loopback-only binding (`server.listen(port, '127.0.0.1', ...)`,
  present before this phase as `build/server.js.orig` shows) was left untouched.
- Exactly 2 of the 5 findings were remediated; WEB-VUL-002, WEB-VUL-004 and
  WEB-VUL-005 remain unremediated by instruction.
