# CS-02 — Risk Analysis

**Project:** Web Application Security Assessment of OWASP Juice Shop
**Target:** `http://127.0.0.1:3000` (loopback-only local laboratory)
**Assessment date:** 2026-10-04
**Scope:** all 10 findings in `findings/`, assessed against evidence captured from the live application

---

## 1. Method

Risk is assessed from four independent factors, each scored 1–5, rather than by
copying a scanner's severity label. No scanner severity is used anywhere in this
document, because no scanner was available in the laboratory environment (nmap, Nikto,
ZAP, WhatWeb and Nuclei are not installed and `sudo` requires a password). Every score
below is a reasoned judgement traceable to a specific evidence file.

| Factor | Question it answers | 1 | 5 |
|---|---|---|---|
| **Likelihood** | How likely is this to be exploited? | requires sustained, targeted effort | near-certain, occurs on first contact |
| **Impact** | How much damage if exploited? | negligible | full compromise of accounts/data/integrity |
| **Exploitability** | How hard is it technically? | deep multi-step, custom tooling | one unauthenticated `curl` |
| **Exposure** | How reachable is it? | internal, authenticated, narrow | fully public, unauthenticated |

**Overall risk** is not the arithmetic sum — it is the dominant combination. A finding
scoring 5 on both exploitability and exposure is High even at moderate impact, because
the attack is free and universal. Conversely a Critical impact with exposure 1 is
downgraded, because the attacker must first be inside.

**Priority mapping:** P1 = High/Critical → remediate first. P2 = Medium → remediate next.
P3 = Low / already remediated → monitor only.

**Status vocabulary** (used consistently throughout): `OPEN`, `REMEDIATION
RECOMMENDED`, `REMEDIATION IMPLEMENTED`, `RETESTED`, `STILL OPEN`, `CLOSED`.

---

## 2. Risk register summary

| ID | Vulnerability | L | I | E | X | Overall | Priority | Status |
|---|---|---|---|---|---|---|---|---|
| WEB-VUL-001 | SQL injection in login | 2 | 5 | 3 | 4 | Low (residual) | P3 | **Remediated** |
| WEB-VUL-002 | Broken object-level authorization (basket) | 2 | 3 | 3 | 3 | Low (residual) | P3 | **Remediated** |
| WEB-VUL-003 | Missing security headers | 2 | 3 | 2 | 3 | Low (residual) | P3 | **Remediated** |
| WEB-VUL-004 | Unauthenticated information disclosure | 4 | 2 | 5 | 5 | Medium | P2 | **Still open** |
| WEB-VUL-005 | Unauthenticated feedback exposure | 4 | 2 | 5 | 5 | Medium | P2 | **Still open** |
| WEB-VUL-006 | Broken function-level authorization (`/api/Users`) | 5 | 4 | 4 | 3 | **High** | **P1** | **Still open** |
| WEB-VUL-007 | Password hash embedded in JWT | 4 | 5 | 4 | 3 | **High** | **P1** | **Still open** |
| WEB-VUL-008 | Unauthenticated encryption key exposure | 5 | 4 | 5 | 5 | **High** | **P1** | **Remediated + re-tested** |
| WEB-VUL-009 | SQL injection in product search | 5 | 4 | 5 | 5 | **High** | **P1** | **Still open** |
| WEB-VUL-010 | Wildcard CORS | 3 | 2 | 5 | 5 | Medium | P2 | **Remediated + re-tested** |

> **Status column vs. the scores above.** The L/I/E/X scores are the **pre-remediation**
> risk of each finding, recorded as observed during the assessment. The Status column
> reflects the position **after** the remediation and re-testing phase
> (`findings/REMEDIATION_REGISTER.md`). WEB-VUL-008 and WEB-VUL-010 were remediated
> after this analysis was written, so their status is now *Remediated + re-tested* even
> though the scores that justified treating them as P1/P2 are unchanged — those scores
> are what determined the remediation priority in the first place. Residual risk after
> remediation is Low for both; it is recorded in `findings/WEB-VUL-008` and
> `WEB-VUL-010` rather than being back-filled into this table.

Machine-readable form: `findings/risk-register.csv`.

> **Severity ≠ overall risk — read both.** Severity (in `findings/`) measures the damage
> *if* a finding is exploited, in isolation. Overall risk (above) additionally weighs
> likelihood and exposure. The clearest case is **WEB-VUL-007**: its severity is
> **Critical** (plaintext password recovery), but its overall risk is rated **High**
> because it requires an attacker to first obtain a token, so likelihood is 4 and
> exposure 3 rather than 5. Conversely WEB-VUL-004 and 010 are only Medium by severity,
> but are fully public and trivially reachable. The two scales are deliberately not
> merged.

---

## 3. Per-finding analysis

### WEB-VUL-001 — SQL injection in login · Low (residual) · Remediated

**Affected component:** `POST /rest/user/login` (`routes/login.ts`)

**Reasoning.** This was the highest-impact finding in the original assessment because a
successful tautology issues an administrator token — Impact 5. On re-test
(`evidence/findings/V-001-validation.txt`) all six payloads returned `401 Invalid email
or password`, so the parameterised query is in place. The residual scores describe what
would remain *if the fix regressed*, not the current state; likelihood is 2 because it
would require an attacker to find a novel bypass in a parameterised statement.

**Security consequence if reintroduced:** complete authentication bypass and
administrator account takeover without any credential.

---

### WEB-VUL-002 — Broken object-level authorization on baskets · Low (residual) · Remediated

**Affected component:** `GET /rest/basket/:id`

**Reasoning.** Re-test (`evidence/findings/V-002-validation.txt`) shows foreign basket
IDs now return `403 Forbidden: this basket does not belong to the authenticated user`,
while the caller's own basket still returns `200`. Impact was scored 3 rather than higher
because basket contents are commercial data, not credentials. Residual likelihood 2.

**Security consequence if reintroduced:** cross-user disclosure of basket contents and
customer purchase behaviour by enumerating sequential integer IDs.

---

### WEB-VUL-003 — Missing HTTP security headers · Low (residual) · Remediated

**Affected component:** all HTTP responses

**Reasoning.** Re-test (`evidence/findings/V-003-validation.txt`) confirms
`Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`,
`Referrer-Policy`, `Strict-Transport-Security`, `Permissions-Policy`, `X-XSS-Protection`,
`Cross-Origin-Opener-Policy` and `Cross-Origin-Resource-Policy` are all present, and
`X-Powered-By` is absent. Impact is 3 because headers are defence-in-depth rather than a
primary control — notably, the CSP present is what prevented me from confirming any XSS
finding. Exploitability 2: headers require a secondary browser-side condition.

**Security consequence if reintroduced:** loss of clickjacking, sniffing and
content-injection protections, raising the severity of any future client-side flaw.

---

### WEB-VUL-004 — Unauthenticated information disclosure · Medium · P2 · Still open

**Affected components:** `/metrics`, `/rest/admin/application-version`, `/robots.txt`

**Reasoning.** Re-test (`evidence/findings/V-004-validation.txt`) shows all three still
return `200` with no token. Exposure 5 and exploitability 5 — a single unauthenticated
`curl` with no parameters, no tooling and no credentials. Impact is only **2** because
the disclosed data is Prometheus telemetry and a version string: it aids reconnaissance
and version-targeted exploit selection but does not itself grant access. This is the
clearest case where a scanner would overstate: the finding is real and worth fixing, but
it is not a high-severity compromise.

**Security consequence:** an attacker learns the exact deployed release and runtime
internals, and can select matching public exploits — most valuable when chained with
WEB-VUL-010, which lets any website read these responses cross-site.

---

### WEB-VUL-005 — Unauthenticated feedback exposure · Medium · P2 · Still open

**Affected component:** `GET /api/Feedbacks`

**Reasoning.** Re-test (`evidence/findings/V-005-validation.txt`) shows `200` with
`UserId`, masked email addresses and ratings, no token required. Same exposure and
exploitability profile as WEB-VUL-004. Impact 2: emails are partially masked and the data
is user-generated text, not credentials. Noted as an access-control *inconsistency*: the
same `/api/*` surface returns `401` for `/api/Users`, so the boundary is not applied
uniformly.

**Security consequence:** anonymous harvesting of user content and account identifiers;
usable for profiling and as a phishing pretext, not for direct account takeover.

---

### WEB-VUL-006 — Broken function-level authorization on `/api/Users` · **High** · **P1** · Still open

**Affected component:** `GET /api/Users`, `GET /api/Users/:id`

**Reasoning.** The decisive test was a three-token matrix
(`evidence/findings/V-006-validation.txt`):

| Token | Result |
|---|---|
| none | `401` |
| `customer` | **`200` + the entire user directory** |
| `admin` | `200` + the entire user directory |

Likelihood 5 and exploitability 4 because the *only* precondition is registering an
account, which the application offers openly — I obtained a `customer` token in two
unauthenticated requests. Impact 4: every administrator address and the full role map
are disclosed, which is the reconnaissance step that makes credential stuffing and
targeted phishing precise rather than blind. Exposure is 3, not 5, because
authentication is required.

**Explicitly not rated Critical:** write access was tested and is not routed
(`PATCH /api/Users/1` → `500 Unexpected path`), so no privilege escalation was
demonstrated. This is unauthorized **read** access only, and the rating reflects the
proven scope.

**Security consequence:** a complete, role-annotated target list of all accounts handed
to the lowest-privilege registered user, enabling targeted credential attacks against
named administrators.

---

### WEB-VUL-007 — Password hash embedded in JWT · **High** · **P1** · Still open

**Affected component:** token issuance in `POST /rest/user/login` (`lib/insecure.ts`)

**Reasoning.** Decoding the JWT payload requires no secret
(`evidence/findings/V-007-validation.txt`) and returns
`"password": "0192023a7bbd73250516f069df18b500"`, plus `role` and a `totpSecret` field.
I then confirmed `md5("admin123") == 0192023a7bbd73250516f069df18b500`, so the disclosed
value yields the **plaintext password** in a single hash operation — that is what
separates this from an ordinary hash leak and drives Impact to 5.

Likelihood 4 rather than 5 because the attacker must first obtain a token (the app issues
no cookies, so there is no ambient session to steal passively); exploitability 4 because
base64 decoding is trivial but the token must be intercepted, read from client storage,
or captured by a future XSS. Exposure 3, since authentication is required.

**Security consequence:** any party obtaining a token recovers the account password,
and for TOTP-enrolled accounts the embedded seed also permits forging second-factor
codes — converting single-token theft into full account takeover.

---

### WEB-VUL-008 — Unauthenticated encryption key exposure · **High** · **P1** · Still open

**Affected components:** `/encryptionkeys/`, `/encryptionkeys/:file`

**Reasoning.** The highest combined profile in the assessment: exposure 5, exploitability
5, no authentication at all. `evidence/findings/V-008-validation.txt` records the
directory listing plus `premium.key` (200, 50 bytes) and `jwt.pub` (200, 248 bytes)
fetched anonymously. Impact 4: the symmetric key protects premium content and coupon
validation, and the JWT verification key weakens the token trust boundary.

A supporting control comparison strengthens the assessment: the sibling `/ftp` route
*does* enforce a `.md`/`.pdf` allow-list (`403 Only .md and .pdf files are allowed!`), so
the two file-serving surfaces have inconsistent protection and the weaker one holds the
more sensitive material. That is a defensible-configuration gap, not merely an oversight.

**Security consequence:** confidentiality of everything those keys protect is lost;
keys cannot be rotated meaningfully while the route keeps serving whatever file it finds.

---

### WEB-VUL-009 — SQL injection in product search · **High** · **P1** · Still open

**Affected component:** `GET /rest/products/search`

**Reasoning.** `evidence/findings/V-009-validation.txt` records the boolean differential:
`apple` → 3 rows, `zzzznotfound` → 0, `' OR '1'='1` → **46** (the whole catalogue),
`' AND '1'='2` → 0. A tautology/contradiction pair is the signature of boolean-based
SQL injection and is far stronger proof than an error message alone, so exploitability is
5. Exposure 5: the endpoint is fully public. Likelihood 5 for the same reason.

The malformed payload `' OR 1=1--` additionally returns
`500 Error: SQLITE_ERROR: incomplete input`, disclosing the database engine and the
driver error string — an error oracle that shortens exploitation.

**Security consequence:** attacker-controlled boolean logic over the database. The
demonstrated extraction is the public product catalogue; because the same technique
extends to any table in the query, and `Users` is a target the authenticated API
protects (WEB-VUL-006), the realistic ceiling is account data.

**Testing boundary:** escalation to other tables was deliberately *not* attempted, to
remain inside the authorised scope. Impact is scored 4 on that basis, not on an assumed
full-database result.

---

### WEB-VUL-010 — Wildcard CORS · Medium · P2 · Still open

**Affected component:** all `/rest/*` and `/api/*` responses

**Reasoning.** `evidence/findings/V-010-validation.txt` shows
`Access-Control-Allow-Origin: *` for an arbitrary attacker origin, with
`GET,HEAD,PUT,PATCH,POST,DELETE` advertised and `authorization` reflected in
`Access-Control-Allow-Headers`. Exposure 5, exploitability 5.

Impact is held to **2** by a specific observation, not by assumption:
`Access-Control-Allow-Credentials` is **not** set, so the browser will not attach cookies
or ambient credentials. The practical effect is therefore cross-origin reads of
*unauthenticated* content — which widens the reach of WEB-VUL-004, WEB-VUL-005 and
WEB-VUL-008 rather than independently granting access.

This finding also sits against a well-hardened browser layer (strict CSP, CORP
`same-origin`), so it is the one remaining gap in that defence. Noted as amplifying:
Medium alone, higher in combination.

**Security consequence:** any website can harvest the application's already-public
responses from a victim's browser, and if a script-execution flaw ever appears, injected
code could read API responses.

---

## 4. Cross-cutting risk

Three P1 findings chain together, which raises the realistic risk above the sum of the
individual ratings:

1. **WEB-VUL-008** hands an attacker the JWT verification key and premium-content key
   with no authentication.
2. **WEB-VUL-007** means any token reveals the account password in recoverable form.
3. **WEB-VUL-006** hands a self-registered customer the full administrator address list.

An attacker can therefore register, enumerate administrators, obtain or forge tokens
using the disclosed key material, and recover passwords — without ever exploiting a
memory-corruption or authentication-bypass primitive. **The combined P1 chain is the
dominant risk in this assessment**, and it is why remediation priority is ordered
WEB-VUL-008 → WEB-VUL-007 → WEB-VUL-006, breaking the chain rather than treating the
findings as independent tickets.

---

## 5. Remediation priority

| Order | Finding | Action | Rationale |
|---|---|---|---|
| 1 | WEB-VUL-008 | Remove the `/encryptionkeys` web route | Unauthenticated key disclosure; breaks the chain at the cheapest point |
| 2 | WEB-VUL-007 | Strip secrets from the JWT payload | Converts token theft into account takeover |
| 3 | WEB-VUL-009 | Parameterise the search query | Unauthenticated injection; unauthenticated should never outrank authenticated here |
| 4 | WEB-VUL-006 | Enforce role check on `/api/Users` | Removes the admin target list |
| 5 | WEB-VUL-010 | Restrict CORS to an allow-list | Amplifier for 004/005/008 |
| 6 | WEB-VUL-004 | Authenticate `/metrics`, gate version | Reconnaissance value |
| 7 | WEB-VUL-005 | Authenticate `/api/Feedbacks` | User data exposure |

**Remediations selected for implementation in this project** are recorded in
`docs/remediation.md` and `docs/retesting.md`. Two were implemented and re-tested; the
remainder are **recommendations only** and are explicitly *not* claimed as fixed.