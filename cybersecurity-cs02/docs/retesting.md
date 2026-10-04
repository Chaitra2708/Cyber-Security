# Phase 17 — Retesting

## Scope

Target:
http://127.0.0.1:3000

Authorized scope: `127.0.0.1:3000` ONLY (local OWASP Juice Shop v20.2.0).
No other host, port, service or system was tested.

## Retesting Objective

Verify whether the two remediated findings remain reproducible after mitigation.

## Instance Verification (17.1)

- `GET http://127.0.0.1:3000/` → HTTP 200 (OWASP Juice Shop)
- Running process: `node build/app`, **pid 6690, started 2026-10-04 15:50:27 +05:30**
  — started *after* both mitigations were written (15:44–15:50), so the active
  process serves the mitigated code, not an old build or different port.
- Proof the remediated code is the code being served:
  `build/routes/login.js` contains the `replacements` parameterisation,
  `build/server.js` contains the CSP middleware — and the live responses below
  show exactly those changes (401 on payloads, new headers emitted).
- Port 3000 only; no other port/host touched.

## Finding 1

### Finding ID

WEB-VUL-001 — SQL injection authentication bypass

### Before Remediation

`POST /rest/user/login` with `{"email":"' OR 1=1--","password":"x"}` returned
**HTTP 200** with an authentication token for the seeded admin
(`umail: admin@juice-sh.op`, bid 1). The second Phase 10 payload
`' OR '1'='1' --` also returned HTTP 200. Invalid credentials returned HTTP 401.

### Before Evidence

- `remediation/WEB-VUL-001/before/EVID-REM-001-sqli-before.txt` (EVID-REM-001, captured 2026-10-04T15:42:55+05:30 on the unmodified instance)
- Original Phase 10 evidence: `evidence/reverification/EVID-REVERIFY-C1-sqli.txt`
- Historical: `evidence/requests/WEB-VUL-001-request.txt`, `evidence/responses/WEB-VUL-001-response.txt`

### Retest Procedure

Identical to Phase 10 — no new exploit invented. Against the running mitigated
instance: (1) control with invalid credentials, (2) control with legitimate
seeded credentials, (3) payload `' OR 1=1--`, (4) payload `' OR '1'='1' --`,
all as `POST /rest/user/login` via `curl`, tokens redacted.

### After Remediation

- Control (invalid credentials): **HTTP 401** — same secure baseline as before.
- Control (legitimate seeded login): **HTTP 200** with token — functionality intact.
- Payload `' OR 1=1--`: **HTTP 401** `Invalid email or password.`
- Payload `' OR '1'='1' --`: **HTTP 401** `Invalid email or password.`

The injected SQL is now bound as an escaped literal value (Sequelize named
`replacements`), so neither tautology matches any user and no token is issued.

### After Evidence

`remediation/WEB-VUL-001/after/EVID-RETEST-001-sqli-retest.txt` (EVID-RETEST-001,
captured 2026-10-04T15:55:24+05:30)

### Result

**FIXED**

## Finding 2

### Finding ID

WEB-VUL-003 — Missing HTTP security headers

### Before Remediation

`GET /` emitted only `X-Content-Type-Options: nosniff` and
`X-Frame-Options: SAMEORIGIN` (plus `Feature-Policy`, `X-Recruiting`,
`Cache-Control`). Seven baseline hardening headers were absent:
`Strict-Transport-Security`, `Content-Security-Policy`, `X-XSS-Protection`,
`Referrer-Policy`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`,
`Cross-Origin-Resource-Policy`.

### Before Evidence

- `remediation/WEB-VUL-003/before/EVID-REM-002-headers-before.txt` (EVID-REM-002, captured 2026-10-04T15:43:03+05:30 on the unmodified instance)
- Original Phase 10 evidence: `evidence/reverification/EVID-REVERIFY-C3-headers.txt`
- Historical: `evidence/responses/WEB-VUL-003-validation.txt`, `evidence/scanner-results/RECON-002-response-headers.txt`

### Retest Procedure

Identical to Phase 10 — `curl -D -` on `GET /` and enumeration of the same
10-header baseline list, plus a headless-Chrome load of the page (isolated
profile, 8 s virtual time) to confirm the new CSP does not break the app.

### After Remediation

- All 10 baseline headers **PRESENT**, including the 7 previously missing
  (`Content-Security-Policy`, `Strict-Transport-Security`,
  `Referrer-Policy: no-referrer`, `X-XSS-Protection: 1; mode=block`,
  `Permissions-Policy: camera=(), microphone=(), geolocation=()`,
  `Cross-Origin-Opener-Policy: same-origin`,
  `Cross-Origin-Resource-Policy: same-origin`).
- Browser verification: **0 console messages** (no CSP violations, no errors),
  `styles.css` link switched to `media="all"` (the hash-allow-listed inline
  handler executed), product grid rendered — application functionality intact.

### After Evidence

- `remediation/WEB-VUL-003/after/EVID-RETEST-002-headers-retest.txt` (EVID-RETEST-002, captured 2026-10-04T15:55:45+05:30)
- `remediation/WEB-VUL-003/after/LAB-016-post-remediation.png` (headless-Chrome screenshot of the app rendering under the new CSP, 296 865 bytes)

### Result

**FIXED**

## WEB-VUL-002 — Third Remediated Finding

> Retest performed 2026-10-04 after the WEB-VUL-002 mitigation; the two earlier
> retests above are unchanged.

### Finding ID

WEB-VUL-002 — Broken Access Control / IDOR on `/rest/basket/:id`

### Before

`GET /rest/basket/2` with an admin (UserId 1) bearer token returned **HTTP 200**
with `"UserId": 2` and the victim's products. Unauthenticated requests received
401. A cross-user coupon PUT reached the basket-update path (rejected only with
404 "Invalid coupon" — no authorization). Any authenticated principal could
enumerate and read other users' baskets.

### Before Evidence

- `remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt` (EVID-REM-006, captured 2026-10-04T16:39+05:30)
- Original Phase 10 evidence: `evidence/reverification/EVID-REVERIFY-C2-idor.txt`
- Historical: `evidence/responses/WEB-VUL-002-victim-basket.json`, `evidence/requests/WEB-VUL-002-request.txt`

### Retest Procedure

Identical to the original reproduction (finding.md §9) — no new exploit:
(1) unauthenticated control, (2) admin login, (3) `GET /rest/basket/2` as admin,
(4) `GET /rest/basket/1` (own) control, (5) unknown-id control, (6) cross-user
vs own coupon PUT, plus regression spot-checks of the other two remediations.

### After

- Cross-user read `GET /rest/basket/2`: **HTTP 403**
  `{"status":"error","message":"Forbidden: this basket does not belong to the authenticated user"}`
- Cross-user coupon PUT: **HTTP 403** (write path now authorized)
- Own basket read: **HTTP 200** with contents (unchanged)
- Own basket coupon with invalid coupon: **HTTP 404 "Invalid coupon"** (unchanged)
- Unknown basket id: **HTTP 200** empty (unchanged original behaviour)
- Unauthenticated: **HTTP 401** (unchanged)
- Legitimate end-to-end flow (register → login → add item → read own basket →
  checkout own basket): all successful, order confirmation issued
- Regression spot-checks: SQLi login payload → 401, CSP header present,
  legitimate login → 200

### After Evidence

`remediation/WEB-VUL-002/after/EVID-RETEST-004-idor-retest.txt` (EVID-RETEST-004,
captured 2026-10-04T16:46:17+05:30)

### Result

**FIXED**

---

## Before/After Summary

| Finding | Before | After | Retest Result |
|---|---|---|---|
| WEB-VUL-001 | SQLi payloads `' OR 1=1--` and `' OR '1'='1' --` returned HTTP 200 with an admin-role JWT (EVID-REM-001, EVID-REVERIFY-C1) | Both payloads return HTTP 401 `Invalid email or password.`; legitimate seeded login still HTTP 200 (EVID-RETEST-001) | FIXED |
| WEB-VUL-003 | 7 of 10 baseline hardening headers missing (EVID-REM-002, EVID-REVERIFY-C3) | All 10 baseline headers present; 0 browser/CSP violations; app fully rendered (EVID-RETEST-002) | FIXED |
| WEB-VUL-002 | Cross-user basket read returned HTTP 200 with victim contents; write paths unauthenticated at object level (EVID-REM-006, EVID-REVERIFY-C2) | Cross-user read and coupon write now HTTP 403; own-basket flow unchanged (EVID-RETEST-004) | FIXED |

Detailed per-item comparison:

| Item | Before Remediation | After Remediation |
|---|---|---|
| Finding | WEB-VUL-001 | WEB-VUL-001 |
| Test | POST /rest/user/login with `' OR 1=1--` (Phase 10 procedure) | Same |
| Observed behavior | HTTP 200 + admin token | HTTP 401 Invalid email or password. |
| Expected secure behavior | Payload rejected as invalid credentials | Same observed |
| Result | Vulnerable behavior reproduced | No longer reproducible |
| Evidence | EVID-REM-001 / EVID-REVERIFY-C1 | EVID-RETEST-001 |
| Finding | WEB-VUL-003 | WEB-VUL-003 |
| Test | Header enumeration of GET / (Phase 10 procedure) | Same + headless-Chrome load |
| Observed behavior | 7/10 baseline headers missing | 10/10 present; 0 console/CSP messages |
| Expected secure behavior | Full hardening header set, app still works | Same observed |
| Result | Vulnerable behavior reproduced | Expected secure behavior observed |
| Evidence | EVID-REM-002 / EVID-REVERIFY-C3 | EVID-RETEST-002 |

## Findings Updated (17.6)

- `findings/WEB-VUL-001/finding.md` → Remediation Status: **Remediated**; Retest Status: **Fixed**
- `findings/WEB-VUL-003/finding.md` → Remediation Status: **Remediated**; Retest Status: **Fixed**
- The other three findings (WEB-VUL-002, WEB-VUL-004, WEB-VUL-005) were **not**
  changed: still Not Remediated / Not Retested.

## Limitations

- Retest scope is exactly the two remediated findings, using the original
  Phase 10 procedures; no new exploits were developed.
- Evidence is from the authorized isolated loopback lab only; conclusions are
  about this local instance, not about Juice Shop deployments in general.
- The parameterised-query fix closes the login SQLi *for this endpoint*; a
  wider injection analysis of other endpoints was not part of this phase and is
  not claimed.
- The CSP is intentionally pragmatic: `style-src 'unsafe-inline'` plus two
  hash-allow-listed inline snippets remain, because that is the minimum for the
  application to run unmodified. It is verified working, not claimed maximally strict.
- HSTS is present but inert over plain-HTTP localhost (browser behavior by design).
- WEB-VUL-002, WEB-VUL-004 and WEB-VUL-005 remain unremediated/unretested by instruction.
- `build/server.js` differs from `build/server.js.orig` also by the pre-existing
  loopback-only listen binding from an earlier phase; it was left untouched.
