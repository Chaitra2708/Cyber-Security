# CS-02 — Final Remediation Register

**Frozen at closeout, 2026-10-04.** Two columns are kept deliberately separate:
**Recommended Remediation** is the guidance produced by the assessment;
**Actually Implemented** records only changes that exist in the running remediation
build and were re-tested. No open finding is presented as fixed.

| Finding | Original Result | Recommended Remediation | Actually Implemented | Retest Result | Final Status | Evidence |
|---|---|---|---|---|---|---|
| WEB-VUL-001 | SQLi login payloads returned 200 + admin JWT | Parameterised query | **YES** — Sequelize named `replacements` in `build/routes/login.js` | All 6 payloads → 401; valid login → 200 | **REMEDIATED / RE-TESTED** | `V-001-validation.txt`, `EVID-RETEST-001` |
| WEB-VUL-002 | Cross-user basket read → 200 with victim contents | Object-level ownership check | **YES** — shared ownership guard on read+write basket routes | Cross-user read/write → 403; own flow unchanged | **REMEDIATED / RE-TESTED** | `V-002-validation.txt`, `EVID-RETEST-004` |
| WEB-VUL-003 | 7/9 hardening headers missing | Standard hardening header set | **YES** — header middleware incl. hash-based CSP | 9/9 headers present; `X-Powered-By` absent | **REMEDIATED / RE-TESTED** | `V-003-validation.txt`, `EVID-RETEST-002/003` |
| WEB-VUL-004 | `/metrics`, `/rest/admin/application-version`, `/robots.txt` → 200 anonymously | Auth-gate `/metrics`; restrict version endpoint | **NO — not implemented** | Re-tested: all three still 200 → **still open** | **OPEN / REMEDIATION RECOMMENDED** | `V-004-validation.txt` |
| WEB-VUL-005 | `/api/Feedbacks` → 200 with UserId + masked emails | Require authentication on `/api/Feedbacks` | **NO — not implemented** | Re-tested: still 200 → **still open** | **OPEN / REMEDIATION RECOMMENDED** | `V-005-validation.txt` |
| WEB-VUL-006 | `customer` token → 200 + all 24 user records incl. admins | Enforce `admin` role; scope `/api/Users/:id` to self | **NO — not implemented** | Not re-tested (no change made) | **OPEN / REMEDIATION RECOMMENDED** | `V-006-validation.txt` |
| WEB-VUL-007 | JWT payload exposes MD5 password hash, role, `totpSecret` | Strip secrets from claims; bcrypt/Argon2id | **NO — not implemented** | Not re-tested (no change made) | **OPEN / REMEDIATION RECOMMENDED** | `V-007-validation.txt` |
| WEB-VUL-008 | `premium.key` 49 B + `jwt.pub` 248 B key material served anonymously | Remove the anonymous `/encryptionkeys` routes | **YES** — REMED-002 removed both routes; REMED-002b added an explicit 404 handler | All three paths → **404 `Not Found`**; PEM key blocks 1 → 0 | **REMEDIATED / RE-TESTED** | `REMED-before.txt`, `REMED-after.txt` |
| WEB-VUL-009 | `' OR '1'='1` → 46 rows vs 3 for `apple`; `SQLITE_ERROR` leak | Parameterise search query; suppress driver errors | **NO — not implemented** | Not re-tested (no change made) | **OPEN / REMEDIATION RECOMMENDED** | `V-009-validation.txt` |
| WEB-VUL-010 | `Access-Control-Allow-Origin: *` for any origin | CORS allow-list of trusted origins | **YES** — REMED-001 allow-list **array** of own origins | 204 with **no** ACAO for attacker origin; own-origin control still allowed | **REMEDIATED / RE-TESTED** | `REMED-before.txt`, `REMED-after.txt`, `REMED-cors-analysis.txt` |

**Totals: 5 REMEDIATED and RE-TESTED · 5 OPEN with recommendations only.**

## Why the five open findings were not remediated

Not for lack of effort, but because each carries a regression or blast-radius cost
higher than the two selected remediations, and the project deliberately avoids claiming
an unverified fix:

| Finding | Why not remediated now |
|---|---|
| WEB-VUL-004 | Low blast radius but touches telemetry that several challenges depend on; safe to schedule after the P1 items. |
| WEB-VUL-005 | Small change, but the same `/api/*` surface is shared, so the fix must be coordinated with 004 and 006 to avoid an inconsistent boundary. |
| WEB-VUL-006 | Requires an **authorization middleware change** on user routes. Mis-scoping it would break legitimate admin flows, and role logic is referenced by several other guards. Highest regression risk of the five. |
| WEB-VUL-007 | Two coupled changes: JWT claim reduction **and** a password-hash migration (MD5 → bcrypt/Argon2id) with re-seed. Doing only the first leaves hashes exposed elsewhere; doing only the second does not fix the token. Needs a migration plan. |
| WEB-VUL-009 | The injection sits in a challenge-relevant query path. Fixing it disables a Juice Shop challenge and alters result semantics, so it needs an explicit decision about challenge preservation. |

## Remediation changes actually made (complete list)

| ID | File | Change |
|---|---|---|
| REMED-001 | `build/server.js`, `server.ts` | Wildcard `cors()` → allow-list array of the app's own origins |
| REMED-002 | `build/server.js`, `server.ts` | Removed the two `/encryptionkeys` routes |
| REMED-002b | `build/server.js` | Added an explicit `404` handler so the SPA catch-all no longer answers 200 |

All three are confined to `lab/juice-shop_20.2.0-remediated`. The vulnerable baseline
`lab/juice-shop_20.2.0` is verified byte-for-byte against the original distribution
archive (`server.ts` MD5 `ba10fa21169fa8baf09f08730515d109`, plus a documented
loopback-only bind for laboratory isolation) and is still running on :3000. During
the final audit, six baseline files that had earlier been edited with remediation
code were restored from that archive; see
`evidence/remediation/REMED-baseline-integrity.txt`.