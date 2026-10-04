# CS-02 — Viva Preparation

25 questions covering the specification's viva list. Every project-specific example
below is traceable to evidence in this project; nothing is invented. Where something
was **not** done, that is stated.

---

## Conceptual questions

### 1. What is web application security?
**Short:** Protecting web applications so that only intended users can do what they
should, and no one else.
**Detailed:** It spans authentication, authorization, input handling, data protection,
session management and configuration. The application logic runs on a remote server, so
the client is never trusted — every check must be enforced server-side.
**Project example:** WEB-VUL-006 — a `customer`-role token was enough to read the entire
user directory, because the server trusted the token's *validity* but never checked the
token's *role*.

### 2a. Why is OWASP relevant to this project?
**Short:** It supplies the shared vocabulary and methodology that makes the findings
defensible.
**Detailed:** OWASP's WSTG gives the testing phases (recon → mapping → testing), the Top 10
gives the risk categories, and Juice Shop is an official OWASP project, so the assessment
can be checked against a recognised framework rather than personal opinion.
**Project example:** Findings map to A01 (004, 005, 006), A02/A07 (007), A03 (009) and
A05 (003, 004, 010) — but XSS, also in the Top 10, is **absent** because I could not
reproduce it. Following the framework as a *map*, not a checklist, is what kept that
honest.

### 2b. Difference between network security and application security?
**Short:** Network security protects the transport and perimeter; application security
protects the logic and data inside the application.
**Detailed:** Firewalls, TLS and segmentation do not stop a valid user calling an
endpoint they should not reach. Application security is enforced in application code on
every request.
**Project example:** My lab binds to `127.0.0.1` with the LAN address unreachable — that is
*network* isolation, and it contains the assessment. But WEB-VUL-006 (a `customer`
reading the admin user directory) is reachable entirely over loopback, authenticated, and
therefore a pure *application* control failure that no firewall would prevent.

### 2c. What is input validation?
**Short:** Checking input against an expected format, type, length and range on the server.
**Detailed:** It is the first defence against injection. Client-side checks are for
usability only; the server must enforce them independently.
**Project example:** `/rest/products/search?q=` accepts `' OR '1'='1` and the database
evaluates it (WEB-VUL-009). Proper validation *and* parameter binding are both needed —
validating characters alone would not have been sufficient or correct.

### 2d. What is OWASP?
**Short:** A non-profit foundation that publishes free application-security standards.
**Detailed:** Its best-known output is the OWASP Top 10, a **risk-category** awareness
list, not a test checklist. Categories are broad — A01 Broken Access Control covers
missing function-level authorization, BOLA and privilege escalation. The OWASP WSTG
supplies the testing *phases* (recon → mapping → testing) used in this project.
**Project example:** My findings map across A01 (004, 005, 006), A02/A07 (007), A03
(009) and A05 (003, 004, 010). XSS is also a Top 10 category, but I could not reproduce
it — and I did **not** claim it.

### 3. Why was Juice Shop selected?
**Short:** It is a real, complete, deliberately vulnerable application.
**Detailed:** It is a full e-commerce-style app with authentication, roles, baskets and a
REST API, so authorization logic can be assessed across real endpoints instead of
proving one technique in isolation. It is also the reference OWASP training target, so
findings map cleanly to the Top 10.
**Project example:** Real roles (`admin`, `customer`, `deluxe`) and real routes are why
WEB-VUL-006 is a genuine finding rather than a contrived one.

### 4. What is authentication?
**Short:** Proving who the user is.
**Detailed:** Usually credentials checked server-side and a session artefact issued.
Authentication is necessary but not sufficient — it establishes identity, not permission.
**Project example:** `POST /rest/user/login` correctly rejected all six SQL injection
payloads with 401, so authentication *itself* held; the defects lay after it.

### 5. What is authorization?
**Short:** Deciding what an authenticated user may do.
**Detailed:** Enforced server-side per request, never inferred from the UI. Two levels:
function-level (may this role call this endpoint?) and object-level (may this user touch
*this* record?).
**Project example:** Authentication worked everywhere. Authorization failed twice —
object-level in WEB-VUL-002 (another user's basket) and function-level in WEB-VUL-006
(the admin-only user directory).

### 6. What is broken access control?
**Short:** A flaw where the app fails to enforce who may access what.
**Detailed:** Typically missing checks on the server. It is consistently the highest-
impact class of web vulnerability because it is directly exploitable and often leads to
data disclosure or full account takeover.
**Project example:** A `customer` account listing the entire user directory including every
administrators is broken function-level authorization — the single most actionable
finding in this project.

### 7. What is injection?
**Short:** Untrusted input being interpreted as code instead of data.
**Detailed:** Classic SQL injection occurs when input is concatenated into a query rather
than bound as a parameter, letting the attacker change the query's meaning.
**Project example:** `/rest/products/search?q=' OR '1'='1` returned **46 rows** against 3
for `apple`, and `' AND '1'='2` returned 0 — a boolean differential proving the database
evaluated the injected expression.

### 8. What is XSS?
**Short:** Injecting script so it executes in another user's browser.
**Detailed:** Reflected (from a request), stored (persisted and served later), or DOM
(client-side). Impact is session theft and actions-as-victim.
**Project example — honest:** I tested for it and **could not reproduce it**. Payloads were
not reflected on the endpoints tried, and the CSP restricts `script-src` without
`'unsafe-inline'`. I therefore did **not** report XSS. Reporting only what I could prove
is more credible than filling a category checklist.

### 9. What is session management?
**Short:** Maintaining authenticated state between requests, securely.
**Detailed:** Session tokens must be unpredictable, expire, be protected in storage and
in transit, and be invalidated on logout.
**Project example:** Juice Shop issues a JWT in the **response body** (no cookie, so no
cookie-flag surface). The flaw is the token's *content*: the payload carries the account
password hash and a `totpSecret` field, so any token holder recovers the credential —
and for TOTP accounts, could forge second-factor codes.

### 10. What is security misconfiguration?
**Short:** Insecure default or explicit settings rather than a code bug.
**Detailed:** Includes missing headers, permissive CORS, exposed debug/admin endpoints,
verbose errors and default credentials.
**Project example:** `Access-Control-Allow-Origin: *` (WEB-VUL-010), unauthenticated
`/metrics` (WEB-VUL-004), and `500 Error: SQLITE_ERROR: incomplete input` naming the
database engine (WEB-VUL-009).

### 11. What is a vulnerability?
**Short:** A weakness an attacker could exploit.
**Detailed:** Not just a theoretical bug — it needs a reachable path and a demonstrable
effect. A flaw nobody can reach is a code smell, not a finding.
**Project example:** WEB-VUL-001's login SQL injection *was* exploitable before
remediation and is now not — same code pattern, different status.

### 12. What is an exploit?
**Short:** Working code or technique that reliably triggers the vulnerability.
**Detailed:** Proof, not theory. It converts a claim into a verified fact.
**Project example:** My exploits are HTTP requests, not code:
`curl -X OPTIONS .../rest/user/login -H 'Origin: https://evil.example'` returned
`ACAO: *`, and `curl '/rest/products/search?q=' OR '1'='1'` returned the whole catalogue.

### 13. What is risk?
**Short:** Likelihood × impact of a vulnerability in this specific context.
**Detailed:** Severity alone is misleading. In this project I scored four factors —
likelihood, impact, exploitability, exposure — because a Critical-impact flaw hidden
behind authentication is less urgent than a Medium-impact flaw open to the internet.
**Project example:** WEB-VUL-007 is severity **Critical** (plaintext password recovery)
but overall risk **High**, because a token must first be obtained. WEB-VUL-010 is only
Medium by severity yet is fully public and unauthenticated. The two scales are
deliberately not merged.

---

## Process questions

### 14. How were findings identified?
**Short:** By probing the live application and reading its route registrations.
**Detailed:** I extracted route mounts from `server.ts`, probed each live with `curl`,
registered a customer account to observe authenticated behaviour, then read the relevant
handler source. Candidates became findings only when a controlled test produced a result.
**Project example:** The registration endpoint I guessed, `/rest/user/register`, returned
`500 Unexpected path`; the real one, `POST /api/Users`, returned `201` — so I mapped
routes from source rather than assuming.

### 15. What evidence supports the findings?
**Short:** Reproducible captured artifacts, indexed in a CSV register.
**Detailed:** 78 rows in `evidence/evidence-index.csv`, verified by a CSV-aware check:
every referenced path exists, no duplicate IDs, no ragged rows, no JWTs or passwords in
evidence. All findings can be regenerated with one command.
**Project example:** `bash scripts/capture-verification-evidence.sh` recreates
`V-001`…`V-010` against the running lab.

### 16. Why was each severity assigned?
**Short:** From the damage if exploited, weighed against how reachable it is.
**Detailed:** WEB-VUL-006 is High not Critical because write access is unrouted, so only
read access is proven. WEB-VUL-010 is Medium because `Access-Control-Allow-Credentials`
is absent, so cookies are never attached. WEB-VUL-007 is Critical because the leaked hash
is unsalted MD5, recoverable in one operation.
**Project example:** I refused to claim privilege escalation for WEB-VUL-006 because
`PATCH /api/Users/1` returned `500 Unexpected path` — the rating reflects proven scope.

### 17. Which findings were validated, and how?
**Short:** All ten, each with a controlled technique.
**Detailed:** Boolean-differential SQLi; a three-token authorization matrix; base64 JWT
decoding; content-level key inspection; header enumeration; CORS preflight.
**Project example:** WEB-VUL-006's evidence is a table — `no token → 401`,
`customer → 200 + every record`, `admin → 200` — which is precisely what separates an
authorization bug from an authentication bug.

### 18. Which findings were remediated?
**Short:** Five — WEB-VUL-001, 002, 003, 008, 010.
**Detailed:** Fixes were made **only** in a separate copy of the install
(`lab/juice-shop_20.2.0-remediated`, port 3001). The vulnerable baseline
(`lab/juice-shop_20.2.0`, port 3000) is verified byte-for-byte against the original
distribution archive (apart from a documented loopback-only bind) and still returns
`ACAO: *`.
**Project example:** Three changes exist in total — REMED-001 (CORS allow-list),
REMED-002 (removed `/encryptionkeys` routes), REMED-002b (explicit 404).

### 19. How was re-testing performed?
**Short:** The identical HTTP request replayed against both running instances.
**Detailed:** Having baseline and remediated live simultaneously gives a genuine
side-by-side result rather than a remembered "before". Then regression checks confirmed
no functional loss.
**Project example:** The same `OPTIONS` preflight returns `ACAO: *` on :3000 and **no ACAO
header at all** on :3001; the remediated instance still renders 93 product tiles and logs
in successfully.

### 19a. What remediation did you recommend for each finding?
**Short:** A specific control per finding, recorded whether or not it was implemented.
**Detailed:** `findings/REMEDIATION_REGISTER.md` separates the *recommended* control from
the *implemented* one, so a recommendation is never silently presented as a fix.
Parameterised queries for the two SQL injections; an ownership guard for baskets;
role-enforced authorization middleware on `/api/Users`; stripping the password hash and
`totpSecret` from the JWT plus migrating MD5 to bcrypt/Argon2id; authentication on
`/metrics` and `/api/Feedbacks`; a CORS allow-list; and removing the `/encryptionkeys`
routes.
**Project example:** WEB-VUL-007's recommendation is a coupled change — the JWT payload
must stop carrying the hash *and* stored hashes must be rehashed. Patching only one would
leave either the leak or the weak storage in place.

### 19b. How did you verify that remediation was successful?
**Short:** By re-running the identical reproduction and checking a functional control.
**Detailed:** Two things must both hold: the attack result must change (401 instead of
200, 403 instead of 200, 404 instead of a key file), and legitimate use must still work —
otherwise the "fix" would just be a broken application. Every re-test therefore pairs an
attack probe with a functional control.
**Project example:** WEB-VUL-001 re-test returns 401 for all five payloads *and* the
seeded legitimate login still returns HTTP 200 on :3001; WEB-VUL-002 returns 403 for
foreign baskets while the caller's own basket still reads normally.

### 20. What remains unresolved?
**Short:** Five findings — WEB-VUL-004, 005, 006, 007, 009.
**Detailed:** Each carries a documented reason. 007 needs a coupled JWT-claim change plus
a password-hash migration; 006 requires authorization middleware on user routes with the
highest regression risk; 009 sits in a challenge-relevant query path; 004 and 005 are
lower impact but share a boundary with 006.
**Project example:** I did not "fix" these to make the project look complete. Ten claimed
fixes without evidence would be less credible than five proven ones.

### 21. What was your individual contribution?
**Short:** Lab bring-up, the five new findings, both remediations, and the re-testing.
**Detailed:** (1) Diagnosed that the workspace root was a partial source dump, not a
runnable app, and located the real install. (2) Diagnosed the 404 as a stale baked path in
a long-running process, not a missing build. (3) Repaired three real defects in the lab
scripts. (4) Found and validated WEB-VUL-006–010. (5) Built the two-instance
baseline/remediation model. (6) Caught my own remediations being wrong and fixed them.
**Project example — the most instructive moment:** the health guard originally reported
"ALREADY RUNNING" for a broken app because it grepped for "OWASP Juice Shop", which also
appears in Express's 404 page. I replaced it with an HTTP-200 + `<app-root>` check and
proved it with a planted directory-listing server.

### 22. What would you change before deploying this to production?
**Short:** Almost everything the assessment left open, plus the architecture.
**Detailed:** The single highest-value change is WEB-VUL-007 — strip the password hash and
`totpSecret` from the JWT and migrate MD5 to bcrypt/Argon2id, because a token theft today
is direct credential compromise. Then WEB-VUL-006 (enforce roles) and WEB-VUL-009
(parameterise the query). I would also terminate TLS properly, since the current
`Strict-Transport-Security` header is sent over plain HTTP where it has no effect, and
replace the seeded default credentials (`admin@juice-sh.op` / `admin123`).
**Project example:** `md5("admin123")` equals the hash disclosed in the token — in
production that is the administrator's real password, recoverable in one hash operation.