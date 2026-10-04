# CS-02 — Viva Preparation

Every example below is taken from work actually performed and evidenced in this project.
Where something was **not** done, that is stated plainly rather than glossed.

---

### 1. Why did you choose Juice Shop?

**Short:** It is a real, complete application that is intentionally insecure, so
defects are genuine application defects rather than contrived lab setups.

**Detailed:** Juice Shop is a full e-commerce-style app — authentication, basket,
checkout, admin, REST API — written in TypeScript/Express with an Angular frontend. That
matters because you can assess real authorization logic across real endpoints instead of
proving a single technique in isolation. It is also the reference target for OWASP
training, so findings map cleanly onto the OWASP Top 10 for the report.

**Project example:** WEB-VUL-006 exists only because the app has real roles
(`admin`, `customer`, `deluxe`) and real routes — I registered a `customer`, then got
`200` from `/api/Users` listing all 24 accounts including 5 administrators.

---

### 2. What is OWASP, and what is the Top 10?

**Short:** OWASP is a non-profit that publishes free application-security standards; the
Top 10 is its awareness list of the most significant web application risk categories.

**Detailed:** The Top 10 is a **risk category** list, not a checklist that guarantees
coverage. Categories are broad (e.g. A01 Broken Access Control covers missing function-level
authorization, BOLA, and privilege escalation). My findings map across several:
A01 (004, 005, 006), A02/A07 (007), A03 (009), A05 (003, 004, 010).

**Project example:** I could not reproduce XSS even though it is a Top 10 category, and I
did **not** claim it. Reporting only what I could prove is more credible than filling a
category checklist.

---

### 3. What did reconnaissance identify?

**Short:** Ports, technologies and unauthenticated exposure.

**Detailed:** Port scan found the target on 3000 (loopback), plus unrelated services
(Apache :80, MySQL :3306/33060, CUPS :631). Tech fingerprinting identified Juice Shop
20.2.0, Express 4.22.2, Node v22.23.3, an Angular SPA and SQLite via Sequelize.
Recon also found `X-Powered-By` absent but `robots.txt` advertising `/ftp`.

**Project example:** `/robots.txt` said `Disallow: /ftp` while `/ftp` was publicly
readable — a 403-vs-200 mismatch I recorded in evidence.

---

### 4. Why were no scanners used?

**Short:** nmap, Nikto, ZAP, WhatWeb and Nuclei are not installed, and `sudo` requires a
password, so I could not install them non-interactively.

**Detailed:** This is a stated limitation, not a shortcut. I used raw `connect_ex()`
socket calls and direct `curl` requests instead, and recorded the tooling gap in the
evidence rather than implying a scanner had run. Because of that, no scanner severity is
quoted anywhere in the report — every risk score is my own reasoning from observed
behaviour.

**Project example:** `evidence/recon/RECON-001-port-scan.txt` explicitly states "nmap not
available; sudo requires a password" before listing results.

---

### 5. How was application mapping performed?

**Short:** From the running app's own route registrations plus live HTTP probing of
every discovered endpoint.

**Detailed:** I extracted `app.use`/`app.get` mounts from `server.ts` to build the route
list, then probed each with `curl` to record the real status code. I also read
`swagger.yml` for the B2B API. Importantly I registered a test account and obtained a
`customer` token, because several endpoints behave differently once authenticated.

**Project example:** `/rest/user/register` returned `500 Unexpected path`; the real
registration endpoint is `POST /api/Users`, which returned `201` and created user id 25.

---

### 6. What were the top findings, and why those severities?

**Short:** Broken function-level authorization, password hash in the JWT, unauthenticated
key exposure, and SQLi in search — all High. Reasoning follows.

**Detailed:**
- **WEB-VUL-007 (High):** Impact 5 because `md5("admin123")` equals the disclosed hash, so
  the **plaintext password** is recovered in one operation — not merely a hash leak.
- **WEB-VUL-006 (High, not Critical):** any customer lists all 24 users incl. admins, but
  `PATCH` is not routed, so I could not demonstrate privilege escalation. Rating reflects
  proven read access only.
- **WEB-VUL-009 (High):** Exposure 5 (fully public) and exploitability 5, proven by
  boolean differential — `' OR '1'='1` → 46 rows vs 3 for `apple`.
- **WEB-VUL-010 (Medium):** ACAO `*`, but `Access-Control-Allow-Credentials` is absent, so
  the browser does not attach cookies; impact is capped at cross-origin reads of
  already-public data.

---

### 7. How were findings validated?

**Short:** Each has a controlled test producing an unambiguous result, and the evidence is
regenerable by a script.

**Detailed:** SQLi used a boolean differential (tautology vs contradiction) rather than
relying on an error message. Access control used a three-token matrix — no token, customer
token, admin token — so the authorization gap is isolated from authentication. XSS was
attempted and **failed to reproduce**, so it was not reported.

**Project example:** `evidence/findings/V-006-validation.txt` shows
`no token → 401`, `customer → 200 + 24 records`, `admin → 200`. That single table is what
proves it is an authorization bug, not an authentication bug.

---

### 8. Which two findings were remediated, and what exactly changed?

**Short:** WEB-VUL-010 (CORS) and WEB-VUL-008 (encryption keys).

**Detailed:**
- **REMED-002 / WEB-VUL-008:** commented out the two `/encryptionkeys` routes in
  `build/server.js` and `server.ts` in a *copy* of the install.
- **REMED-001 / WEB-VUL-010:** replaced wildcard `cors()` with an **allow-list array** of
  the app's own origins.

**Project example:** The vulnerable baseline `lab/juice-shop_20.2.0` is still running on
:3000 and is verified byte-for-byte against the original distribution archive (apart from a
documented loopback-only bind for lab isolation) — while fixes live only in
`lab/juice-shop_20.2.0-remediated` on :3001.

---

### 9. How was remediation verified?

**Short:** The identical HTTP request was replayed against both running instances.

**Detailed:** Having two live instances is the key design decision — it gives a genuine
side-by-side result instead of "before" remembered from an earlier session. I ran
`node --check`, restarted, and confirmed readiness before testing.

**Project example:** `evidence/remediation/REMED-after.txt` shows the same preflight
returning `Access-Control-Allow-Origin: *` on :3000 and **no ACAO header at all** on :3001.

---

### 10. What went wrong during remediation?

**Short:** REMED-001 was wrong twice before it was correct, and the re-test caught it.

**Detailed:** First attempt passed `origin` as a **string**; cors@2.8.6's `configureOrigin`
takes the `isString` branch and echoes it **without checking** the request's `Origin`, so
the attacker origin still received the header — cosmetic only. Second attempt passed a
**function**; a falsy callback makes cors call `next()`, so the preflight fell through to
Juice Shop's `unexpectedRequest` handler and returned **500 instead of 204**, a regression.
Only an **array** is validated by `isOriginAllowed()` while still terminating the
preflight. I read `node_modules/cors/lib/index.js` rather than guessing.

**Project example:** `evidence/remediation/REMED-cors-analysis.txt` documents the three
semantics. Had I stopped at "the header is no longer `*`", I would have reported a false
success.

---

### 11. Why is WEB-VUL-008 "fixed" if it still returns HTTP 200?

**Short:** Because the fix was verified by comparing **content**, not status code.

**Detailed:** With the route removed, Express falls through to the SPA catch-all and
serves `index.html`. A status-only check would have wrongly said "still vulnerable". The
baseline returns 248 bytes containing `BEGIN RSA PUBLIC KEY` (the JWT verification key —
note it is a *public* key, so grepping for `PRIVATE KEY` would give 0 on both); the remediated instance
returns the Juice Shop HTML shell and no key material.

**Project example:** The grep for PEM key material matches on :3000 and not on :3001 —
that is the actual evidence. Returning a clean 404 is noted as a follow-up improvement.

---

### 12. What remained unresolved?

**Short:** Five findings: WEB-VUL-004, 005, 006, 007, 009.

**Detailed:** 004 (metrics/version disclosure) and 005 (unauthenticated feedback) are
Medium and Low. 006, 007 and 009 are High and left open deliberately: 007 needs a JWT
claim change plus a password-hash migration, and 009 requires rewriting a
challenge-relevant query path — both higher regression risk than the two selected. I
documented them as recommendations rather than claiming partial fixes.

**Project example:** `docs/remediation.md` §4 lists each as "Recommended — not
implemented", and the report's summary table marks all five "Still open".

---

### 13. What was your individual contribution?

**Short:** The whole lab bring-up, the five new findings, both remediations and the
re-testing.

**Detailed:** (1) Diagnosed that the workspace root was a partial source dump, not a
runnable app, and located the real install; (2) diagnosed the 404 as a stale baked path
in a long-running process rather than a missing build, and fixed it by restarting;
(3) repaired three real defects in the lab scripts — a health check that matched the 404
error page, a `pgrep` matcher that would SIGTERM unrelated shells, and a wrong Node
binary report; (4) found and validated WEB-VUL-006–010; (5) built the two-instance
baseline/remediation model and re-tested both fixes; (6) corrected five pre-existing
broken evidence citations.

**Project example:** The script guard originally printed "ALREADY RUNNING" for a broken
app because it grepped for "OWASP Juice Shop", which also appears in Express's 404 page.
I replaced it with an HTTP-200 + `<app-root>` check and proved it with a planted
directory-listing server (`evidence/logs/guard-negative-test.txt`).