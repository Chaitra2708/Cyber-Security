# CS-02 — Re-testing

**Baseline (vulnerable):** `lab/juice-shop_20.2.0` → `http://127.0.0.1:3000`
**Remediation instance:** `lab/juice-shop_20.2.0-remediated` → `http://127.0.0.1:3001`

Both instances run simultaneously. The **same HTTP request** was replayed against each,
so every comparison below is a live side-by-side result rather than a recollection.

---

## RETEST-001 — WEB-VUL-010 Wildcard CORS

**Initial result:** VULNERABLE. `OPTIONS /rest/user/login` with
`Origin: https://evil.example` returned `Access-Control-Allow-Origin: *`, advertising
`GET,HEAD,PUT,PATCH,POST,DELETE` and `authorization`.

**Remediation implemented:** REMED-001 in `build/server.js` (and mirrored in
`server.ts`). CORS changed from the wildcard `cors()` to an allow-list array
`[http://127.0.0.1:<port>, http://localhost:<port>]`.

> **Implementation note — this fix failed twice before it was correct, and the re-test
> caught both.** This is recorded deliberately because it is the substantive finding of
> the re-testing exercise:
>
> 1. `cors({ origin: 'http://127.0.0.1:3001' })` returned `204` and the header stopped
>    being `*` — but cors@2.8.6 `configureOrigin()` takes the `isString` branch and echoes
>    the value **without checking the request's Origin**. The attacker origin still
>    received an `Access-Control-Allow-Origin` header, so the fix was cosmetic.
> 2. `cors({ origin: (origin, cb) => cb(null, allowed) })` correctly omitted the header
>    for the attacker, but cors's `middlewareWrapper` calls `next()` when the callback
>    yields a falsy value, so the `OPTIONS` request fell through to Juice Shop's
>    `unexpectedRequest` handler and returned **500 "Unexpected path"** instead of 204 —
>    a behavioural regression.
> 3. The correct form for cors@2.8.6 is an **array/regexp**, which `isOriginAllowed()`
>    validates while still letting the preflight terminate with 204.
>
> The behaviour above was established by reading `node_modules/cors/lib/index.js`, not by
> guessing at the package semantics.

**Re-test method:** identical `OPTIONS` preflight, identical `Origin` header, replayed
against both instances.

**Re-test result:**

| | Baseline :3000 | Remediated :3001 |
|---|---|---|
| Status | 204 | **204** |
| `Access-Control-Allow-Origin` | `*` | **absent** |
| Allow-Methods / Allow-Headers | advertised | advertised |

Control (no regression): `OPTIONS` with `Origin: http://127.0.0.1:3001` → 204 **and**
`Access-Control-Allow-Origin: http://127.0.0.1:3001`, so legitimate same-origin use is
unaffected.

**Final status: REMEDIATED — RETESTED**

---

## RETEST-002 — WEB-VUL-008 Unauthenticated encryption key exposure

**Initial result:** VULNERABLE. With no token, `/encryptionkeys/` listed
`premium.key` and `jwt.pub`; `jwt.pub` returned 248 bytes containing PEM key material.

**Remediation implemented:** REMED-002 in `build/server.js` (and mirrored in
`server.ts`). The two `/encryptionkeys` routes were removed by commenting them out.
`routes/keyServer.ts` was deliberately left in place so the change stays minimal and
reversible; only the anonymous web route is gone, and the application still reads key
material from the filesystem.

**Re-test method:** identical unauthenticated `GET` for each key path on both instances.

**Re-test result (after closeout repair REMED-002b):**

| Path | Baseline :3000 | Remediated :3001 |
|---|---|---|
| `/encryptionkeys/` | **200**, 7 911 B directory listing | **404** `Not Found` |
| `/encryptionkeys/premium.key` | **200**, 49 B key material | **404** `Not Found` |
| `/encryptionkeys/jwt.pub` | **200**, 248 B `BEGIN RSA PUBLIC KEY` | **404** `Not Found` |

PEM key-block count: **1 on :3000, 0 on :3001**.

> **A defect in the first remediation, found during closeout and repaired.**
> Deleting the two routes did stop the key disclosure — the vulnerability was genuinely
> fixed — but the paths then answered **HTTP 200** with the SPA shell. Cause:
> `serveAngularClient()` (`build/routes/angular.js`) sends `index.html` for every URL
> that does not begin with `/api` or `/rest`, so the removed route fell through to it.
> A status-code-only re-test would therefore have wrongly reported this as *still
> vulnerable*. The repair (REMED-002b) adds an explicit `404` handler for
> `/encryptionkeys` and `/encryptionkeys/:file`, so the fall-through no longer occurs and
> the finding is now demonstrated by status code **and** by response content.
> `jwt.pub` is an RSA **public** key (the JWT verification key), so grepping for
> `PRIVATE KEY` returns 0 on both instances and would prove nothing.

**Final status: REMEDIATED — RETESTED**

---

## Regression testing

Performed against the remediated instance after both fixes:

| Check | Result |
|---|---|
| Application starts | Yes, ready in ~4 s, `Server listening on port 3001` |
| Root page loads | `200`, `<title>OWASP Juice Shop</title>` |
| Frontend assets | `main.js` 200, `styles.css` 200 |
| SPA renders in browser | 234 KB DOM, 93 product tiles, toolbar present, 10 product images, 365 KB screenshot |
| Search API | `200`, returns real seeded product data |
| Authentication | `POST /rest/user/login` with valid admin credentials → `200` |
| Unrelated file route | `/ftp/legal.md` → `200` (allow-list route untouched) |
| Unauthenticated admin API | `/api/Users` → `401` (unchanged) |
| Untouched finding still open | `/metrics` → `200` (WEB-VUL-004 correctly still open) |
| Vulnerable baseline | Still running unmodified on :3000, MD5s unchanged |

No regression was introduced, including after the REMED-002b repair (all application
paths above re-verified `200`/`401` as expected).

---

## Findings not re-tested

WEB-VUL-001, 002 and 003 were re-tested and confirmed remediated in an earlier phase.
WEB-VUL-004, 005, 006, 007 and 009 were **not remediated** and are **not claimed as
fixed**. Their status is recorded as *Still open — remediation recommended*.

| ID | Status after this phase |
|---|---|
| WEB-VUL-001 | Remediated (verified earlier) |
| WEB-VUL-002 | Remediated (verified earlier) |
| WEB-VUL-003 | Remediated (verified earlier) |
| WEB-VUL-004 | **Still open** |
| WEB-VUL-005 | **Still open** |
| WEB-VUL-006 | **Still open** |
| WEB-VUL-007 | **Still open** |
| WEB-VUL-008 | **Remediated — retested in this phase** |
| WEB-VUL-009 | **Still open** |
| WEB-VUL-010 | **Remediated — retested in this phase** |