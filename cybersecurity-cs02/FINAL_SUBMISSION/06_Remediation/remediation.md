# CS-02 — Security Remediation

**Project:** Web Application Security Assessment of OWASP Juice Shop
**Baseline:** `lab/juice-shop_20.2.0` — running on `http://127.0.0.1:3000`, **unmodified**
**Remediation copy:** `lab/juice-shop_20.2.0-remediated` — running on `http://127.0.0.1:3001`

---

## 1. Baseline preservation model

```
JUICE SHOP VULNERABLE BASELINE
lab/juice-shop_20.2.0          port 3000   ORIGINAL / UNMODIFIED
   |
   +---- copy taken (tar, node_modules symlinked)
   |
REMEDIATION BRANCH
lab/juice-shop_20.2.0-remediated   port 3001   FIX 1 + FIX 2
   |
   +---- retested here, AFTER evidence captured here
```

Both instances run simultaneously so the **same** HTTP test can be replayed against the
vulnerable baseline and the remediated build, giving a genuine before/after comparison
rather than a recollection of an earlier state.

Baseline integrity fingerprint. The baseline is verified against the **original
downloaded distribution** (`lab/juice-shop-20.2.0_node22_linux_x64.tgz`, MD5
`b9c1827299595e264e0bd7a9ccb470a7`, matching its `lab/juice.tgz.md5` sidecar), not
against a value recorded earlier in the project. Full-tree `diff -rq` shows exactly
one intentional difference — a loopback-only bind added for laboratory isolation.

| File | MD5 (baseline) |
|---|---|
| `lab/juice-shop_20.2.0/server.ts` | `ba10fa21169fa8baf09f08730515d109` |
| `lab/juice-shop_20.2.0/build/server.js` | `54bd707f205eda1eafc22f3cb4bf196c` |
| `lab/juice-shop_20.2.0/build/routes/login.js` | `6b533c7686bab55c0c8bef99b1769305` |
| `lab/juice-shop_20.2.0/build/routes/basket.js` | `0acc51ba34f81d70c07e2da437a0cf93` |

> **Defect found and repaired during the final audit.** Six baseline files had
> earlier been edited with remediation code, so the "unmodified baseline" did not
> actually reproduce WEB-VUL-001, WEB-VUL-002 or WEB-VUL-003. Those files were
> restored byte-for-byte from the verified archive and only the loopback bind was
> re-applied. See `evidence/remediation/REMED-baseline-integrity.txt`. No finding was
> added, removed or altered by that repair.

---

## 2. Selection criteria applied

A finding was eligible only if it was (a) actually identified with existing evidence,
(b) had a clear remediation path, (c) could be changed safely in the local project,
(d) was re-testable, and (e) could not destroy the application. Before editing, both
targets were confirmed to be **independent of every Juice Shop challenge**
(`grep -i encryptionkeys|cors data/static/challenges.yml` → no matches), so neither fix
removes a challenge or breaks challenge logic.

---

## 3. Selected remediations

### REMED-001 — WEB-VUL-010 Wildcard CORS

**Finding:** WEB-VUL-010 — `Access-Control-Allow-Origin: *` returned for every origin.

**Reason:** Highest confidence fix-to-risk ratio in the assessment. It is a single
configuration block, it cannot alter business logic, and the before/after test is a
single header on a request that already exists. Fails closed rather than open, so a
mistake cannot silently re-open the vulnerability.

**Planned change:** replace `cors()` with an explicit **allow-list array** in
`build/server.js` (mirrored in `server.ts`), permitting only the application's own
origin (loopback host and `localhost` on the port the server binds to). Unlisted origins
receive no `Access-Control-Allow-Origin`.

> **Implementation note — two wrong attempts before the correct one.**
> `cors({ origin: '<string>' })` does **not** validate the request's `Origin`; cors@2.8.6's
> `configureOrigin()` takes the `isString` branch and echoes the value for every request,
> so the fix was cosmetic. `cors({ origin: fn })` correctly omitted the header, but a
> falsy callback makes `middlewareWrapper` call `next()`, so the `OPTIONS` preflight fell
> through to Juice Shop's `unexpectedRequest` handler and returned **500** instead of 204 —
> a regression. Only an **array** is validated by `isOriginAllowed()` while still
> terminating the preflight with 204. Established by reading
> `node_modules/cors/lib/index.js`; recorded in
> `evidence/remediation/REMED-cors-analysis.txt`.

**Expected result:** preflight from an attacker origin returns 204 with **no**
`Access-Control-Allow-Origin`; same-origin requests are unaffected.

**Risk to application behaviour:** none expected — the Angular SPA is served from the
same origin as the API, so it makes no cross-origin requests.

---

### REMED-002 — WEB-VUL-008 Unauthenticated encryption key exposure

**Finding:** WEB-VUL-008 — `/encryptionkeys/` and `/encryptionkeys/:file` served
`premium.key` and `jwt.pub` to anonymous clients.

**Reason:** P1 finding, fully unauthenticated, and the cheapest point at which to break
the cross-finding attack chain described in `docs/risk-analysis.md` §4. Removing an
unintended route cannot regress application behaviour, because no application feature
depends on exposing key files over HTTP.

**Planned change:** remove the two `/encryptionkeys` static routes from `server.ts` (the
directory-listing route and the `serveKeyFiles()` route), leaving `routes/keyServer.ts`
in place unused so the change is minimal and reversible.

**Expected result:** `/encryptionkeys/`, `/encryptionkeys/premium.key` and
`/encryptionkeys/jwt.pub` return `404`; no key material is reachable without
authentication.

**Closeout addendum (REMED-002b):** deleting the two routes alone did **not** produce a
404. `serveAngularClient()` (`build/routes/angular.js`) serves `index.html` for every URL
that does not begin with `/api` or `/rest`, so the removed route fell through and the
paths answered **HTTP 200** with the SPA shell. The key was no longer disclosed, so the
vulnerability was genuinely fixed, but a status-code-only re-test could not demonstrate
that. An explicit `404` handler was therefore added for `/encryptionkeys` and
`/encryptionkeys/:file`. Final re-test: **404 `Not Found`**, PEM key blocks 1 → 0, no
regression.

**Correction to the implementation note above:** the fix was applied to `build/server.js`
(the runtime artefact) and mirrored in `server.ts`. This packaged distribution ships no
`tsconfig.json`, so `npm run build:server` (`tsc`) cannot run and the TypeScript source
was not recompiled.

**Risk to application behaviour:** none — premium content decryption uses the key from
the filesystem, not over HTTP.

---

## 4. Recommended controls that were NOT implemented

These are **recommendations only**. They are deliberately *not* claimed as fixed, and
`findings/` still records them as open.

| Finding | Recommended control | Status |
|---|---|---|
| WEB-VUL-006 | Enforce `admin` role on `/api/Users`, scope `/api/Users/:id` to self | **Recommended — not implemented** |
| WEB-VUL-007 | Strip `password`/`totpSecret` from JWT claims; move to bcrypt/Argon2id | **Recommended — not implemented** |
| WEB-VUL-009 | Parameterise the product-search query; suppress driver errors | **Recommended — not implemented** |
| WEB-VUL-004 | Authenticate `/metrics`; gate `/rest/admin/application-version` | **Recommended — not implemented** |
| WEB-VUL-005 | Require authentication on `/api/Feedbacks` | **Recommended — not implemented** |

WEB-VUL-009 was considered for implementation because it is P1 and unauthenticated, but
its remediation requires rewriting the Sequelize query in a challenge-relevant code path
with a higher regression risk than the two selected. It is therefore left as a
recommendation and remains open.