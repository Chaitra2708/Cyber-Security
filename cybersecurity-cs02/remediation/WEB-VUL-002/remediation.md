# Remediation Record — WEB-VUL-002 (Third Remediation)

**Finding:** WEB-VUL-002 — Broken Access Control / IDOR on `/rest/basket/:id`
**Application:** http://127.0.0.1:3000 (OWASP Juice Shop v20.2.0, local lab)
**Remediation implemented:** 2026-10-04T16:40+05:30
**Remediation Status:** Remediated — **Retest: FIXED** (EVID-RETEST-004)

> Previous two remediation records (WEB-VUL-001, WEB-VUL-003) were not altered.

## Root Cause

All three basket-object routes load the basket row **solely by the client-supplied
`req.params.id`**, with no check that the basket belongs to the authenticated
caller. Authentication (`isAuthorized()`) exists, object-level authorization does not:

| Route | Handler | Missing check |
|---|---|---|
| `GET /rest/basket/:id` | `retrieveBasket()` (routes/basket.ts) | `basket.UserId === authenticatedUserId` before returning contents |
| `POST /rest/basket/:id/checkout` | `placeOrder()` (routes/order.ts) | ownership before updating/emptying the basket |
| `PUT /rest/basket/:id/coupon/:coupon` | `applyCoupon()` (routes/coupon.ts) | ownership before `basket.update({ coupon })` |

Why insecure: any valid token can enumerate basket IDs and read (and, via the
write paths, modify) other users' baskets — Broken Object Level Authorization.

## File(s) Changed

Source + compiled runtime changed identically (release package has no
`tsconfig.json`, so no `tsc` rebuild is possible):

1. `lab/juice-shop_20.2.0/routes/basket.ts` — new exported guard `ensureBasketOwnership()`
2. `lab/juice-shop_20.2.0/build/routes/basket.js` — compiled equivalent (executed)
3. `lab/juice-shop_20.2.0/server.ts` — guard wired into the three routes
4. `lab/juice-shop_20.2.0/build/server.js` — compiled equivalent (executed)

## Code / Configuration Change

New guard (single shared implementation), inserted as middleware before each of
the three handlers:

```ts
export function ensureBasketOwnership () {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id
      const basket = await BasketModel.findByPk(id)
      if (basket == null) {
        next() // unknown basket ids keep their original handler behaviour
        return
      }
      const user = security.authenticatedUsers.from(req)
      if (!user?.data?.id || basket.UserId !== user.data.id) {
        res.status(403).json({ status: 'error', message: 'Forbidden: this basket does not belong to the authenticated user' })
        return
      }
      next()
    } catch (error) {
      next(error)
    }
  }
}
```

Wiring (server.ts, compiled build/server.js identically):

```ts
app.get('/rest/basket/:id', ensureBasketOwnership(), utils.asyncHandler(retrieveBasket()))
app.post('/rest/basket/:id/checkout', ensureBasketOwnership(), placeOrder())
app.put('/rest/basket/:id/coupon/:coupon', ensureBasketOwnership(), utils.asyncHandler(applyCoupon()))
```

## Security Control Added

Object-level authorization (ownership enforcement) on every basket-object
request, fail-closed: if the authenticated identity is unknown, the request is
refused. This is exactly the finding's recommendation
(`basket.UserId === authenticatedUserId`).

## Why This Mitigates the Finding

The requested id is no longer trusted: the guard loads the row and compares its
`UserId` with the authenticated caller before any handler can read, update, or
empty it. Cross-user requests never reach the vulnerable handlers.

## Expected Secure Behavior

```text
cross-user basket read      → 403 (was 200 + victim contents)
cross-user coupon PUT       → 403 (was: update path reached)
cross-user checkout         → 403 (blocked before any basket mutation)
own basket read/checkout    → unchanged (200)
unknown basket id           → unchanged original response (no data disclosed)
unauthenticated             → unchanged 401
```

## Original Behavior (before state)

```text
GET /rest/basket/2 as admin (UserId 1) → HTTP 200 with UserId 2's basket
+ products (Raspberry Juice ×2); unauthenticated → 401 only.
Coupon PUT on basket 2 → processed by the update path, rejected only with
404 "Invalid coupon" (no authorization). Cross-user checkout deliberately not
executed pre-fix (would destructively empty the seeded victim basket); write-path
gap established by source inspection.
```

Before-evidence: `remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt`
(captured 2026-10-04T16:39+05:30), plus original evidence
`evidence/reverification/EVID-REVERIFY-C2-idor.txt` and
`evidence/responses/WEB-VUL-002-victim-basket.json` (both preserved unchanged).

## Validation (tests + functionality, 2.5)

- `node --check` on both compiled files: OK
- Application restarts; `scripts/check-lab.sh` → LAB STATUS: PASS
- **Full legitimate flow verified live**: new lab account → register (201) →
  login (200) → add item to own basket (200, appears in `GET /rest/basket/<own>`)
  → checkout own basket (200, order confirmation returned)
- Own-basket read/coupon, unknown-id behaviour, unauthenticated 401: all unchanged
- Other two mitigations still active (SQLi → 401, CSP present)
- Test suites (Node v22.23.3, same commands as Task 1):
  - `basket.test.js`: 22 tests, 13 pass, **9 fail** — every failure is a
    cross-user-basket or forged-JWT-acceptance assertion (the fixed vulnerability)
    or a test incidentally operating on another user's basket
    (EVID-TEST-006)
  - Server unit suite: 415 tests, 410 pass, 3 fail — the same 3
    environment/package failures as before the fix; **no change**
    (EVID-TEST-007 vs EVID-TEST-001b)
  - Full API suite: 537 tests, 476 pass, 49 fail (EVID-TEST-008) vs
    486 pass / 38 fail before this fix (EVID-TEST-003). Name-level diff: new
    failures = 9 basket tests (attributable to the guard, intended) + 1 external
    GitHub fetch (`fetch failed` — network flake, unrelated). No other behavioural
    difference.
- **No test was modified, disabled, deleted, or reworded.**

## Evidence

- Before: `remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt` (EVID-REM-006)
- This implementation record: `remediation/WEB-VUL-002/remediation.md` (EVID-REM-007)
- Retest: `remediation/WEB-VUL-002/after/EVID-RETEST-004-idor-retest.txt` (EVID-RETEST-004) — **FIXED**
- Tests: `evidence/phase18-test-suite/EVID-TEST-006/007/008-*`

## Limitations

- The fix intentionally fails 9 upstream basket tests that assert the
  cross-user behaviour being removed (including "GET existing basket of another
  user" and "GET basket should accept forged JWTs"); tests were left untouched.
- `/api/BasketItems` already had its own basket-id check
  (routes/basketItems.ts, pre-existing) and was not modified.
- Admin cross-basket access is now also denied — Juice Shop has no legitimate
  admin basket-management flow, so no functionality is lost in this application;
  a production system would instead use explicit, audited role-based access.
- The training challenge `basketAccessChallenge` still evaluates its condition
  (unchanged), but the underlying data access it rewarded now returns 403.
