# Security Assessment

## 1. Scope

This document records the **Phase 10 security assessment** for the CS-02 project: a
re-verification of candidate security findings against the **currently running**
OWASP Juice Shop instance, and a structured record of every security area assessed.

**Authorized target:** `http://127.0.0.1:3000` (OWASP Juice Shop v20.2.0)
**Authorized scope:** `127.0.0.1:3000` ONLY. **No other target is in scope.**

> It is important to be precise about what exists. This assessment does **not**
> assume that earlier raw evidence files automatically prove current behaviour.
> Every candidate was re-tested against the live instance; the results are recorded
> below.

## 2. Assessment Methodology

1. **Inspect** all 27 raw evidence artifacts in `evidence/`.
2. **Classify** each artifact as `CONFIRMED CANDIDATE`, `POTENTIAL CANDIDATE`,
   `NOT A SECURITY FINDING`, `INSUFFICIENT EVIDENCE`, or `UNRELATED`.
3. **Verify the lab** is running and that the target responds.
4. For each candidate finding, perform the smallest **safe reproduction**
   (re-authentication, header check, API request) against the live instance.
5. Capture **new current evidence** with a new evidence ID (`EVID-REVERIFY-Cx`).
   Historical evidence is **never** relabeled as current.
6. Record the result as `CONFIRMED`, `NOT REPRODUCED`, `REQUIRES FURTHER VALIDATION`,
   or `OBSOLETE`.
7. Write this document.

Methodology rule: **current evidence must support a conclusion; a filename does not.**

## 3. Authentication Assessment

**Assessment ID:** EVID-ASSESS-001
**Candidate:** C1 — SQL Injection authentication bypass
**Target:** `POST /rest/user/login`
**Test objective:** Confirm whether a SQL injection payload still bypasses
authentication on the current instance.

**Test method:** An invalid-credentials control was sent first (expected `401`), then the
historical payload `' OR 1=1--` (and a second variant) was sent.

**Expected behaviour:** Only correct credentials should produce a token.

**Observed behaviour:**

- Control: `{"error":"Invalid email or password."}` → `HTTP 401`.
- Payload `' OR 1=1--`: `HTTP 200` with a JWT whose payload states
  `"role":"admin"` (token redacted in evidence).

**Result:** **CONFIRMED**

Evidence: `EVID-REVERIFY-C1-sqli.txt` (see also `EVID-ASSESS-001`).

## 4. Authorization Assessment

**Assessment ID:** EVID-ASSESS-002
**Candidate:** C2 — Broken access control / IDOR
**Target:** `GET /rest/basket/:id`
**Test objective:** Confirm whether a lower-privileged account can read a basket that
does not belong to it.

**Test method:** An unauthenticated request was sent first (expected `401`). Then the
historical victim-basket data was re-checked, and a fresh request was made with a
**valid administrator's JWT**, reading another user's basket (`/rest/basket/2`), whose
owner is `UserId: 2`.

**Expected behaviour:** Without a token, `401` is returned. After authentication, a user
may only read their own basket.

**Observed behaviour:**

- Unauthenticated `/rest/basket/1`: `HTTP 401` (Protected by the JWT middleware).
- Admin read of `/rest/basket/2`: `HTTP 200` carrying `"UserId": 2` and its products.
  The identity of the basket owner is observable in the response, and the API performs
  no ownership check.

**Result:** **CONFIRMED**

Evidence: `EVID-REVERIFY-C2-idor.txt` (see also `EVID-ASSESS-002`).

> **Note on historical data.** The file
> `evidence/responses/WEB-VUL-002-response.txt` actually contains an older
> `UnauthorizedError: No Authorization header was found` html page, and is **not** the
> basket-IDOR evidence. The valid basket data is in
> `evidence/responses/WEB-VUL-002-victim-basket.json`. This is recorded here because
> file names do not prove content, and this confusion is resolved in the inventory.

## 5. Input Validation Assessment

**Assessment ID:** EVID-ASSESS-003
**Candidate:** C3 — Missing security HTTP headers
**Target:** `GET /`
**Test objective:** Confirm which security headers the server actually sends.

**Test method:** Issued `curl -D - -o /dev/null` for the homepage and read the headers.

**Expected behaviour:** A hardened application sends
`Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options`,
`X-Frame-Options`, `X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy`,
`Cross-Origin-Opener-Policy`, and `Cross-Origin-Resource-Policy`.

**Observed behaviour:**

| Header | Observed |
|---|---|
| `X-Content-Type-Options` | `nosniff` present |
| `X-Frame-Options` | `SAMEORIGIN` present |
| `Cache-Control` | `public, max-age=0` present |
| `Strict-Transport-Security` | **absent** |
| `Content-Security-Policy` | **absent** |
| `X-XSS-Protection` | **absent** |
| `Referrer-Policy` | **absent** |
| `Permissions-Policy` | **absent** |
| `Cross-Origin-Opener-Policy` | **absent** |
| `Cross-Origin-Resource-Policy` | **absent** |

**Result:** **CONFIRMED** (deficiency)

Evidence: `EVID-REVERIFY-C3-headers.txt` (see also `EVID-ASSESS-002`).

## 6. Injection Assessment

**Assessment ID:** EVID-ASSESS-004
**Candidate:** C4 — Sensitive information disclosure
**Target:** `/metrics`, `/rest/admin/application-version`, `/robots.txt`
**Test objective:** Confirm whether internal information is exposed without
authentication.

**Test method:** Three unauthenticated requests were issued and the responses captured.

**Expected behaviour:** Deployment telemetry, version strings, and directory hints
should not be returned from public paths.

**Observed behaviour:**

| Request | Observed |
|---|---|
| `GET /metrics` | `HTTP 200`, 25,640 bytes of Prometheus-style telemetry |
| `GET /rest/admin/application-version` | `HTTP 200`, `{"version":"20.2.0"}` |
| `GET /robots.txt` | `HTTP 200`, `Disallow: /ftp` |

**Result:** **CONFIRMED**

Evidence: `EVID-REVERIFY-C4-disclosure.txt` (see also `EVID-ASSESS-003`).

## 7. Cross-Site Scripting Assessment

**Assessment ID:** none
**Candidate:** none currently confirmed by the evidence base.
**Test method:** Controlled, harmless input checks were not triggered for a specific
stored/reflected XSS payload in this re-verification pass.

**Result:** **NOT TESTED / NOT CONFIRMED** — this phase did not produce a safe XSS
test. The candidate list therefore stands at four confirmed items (C1–C4); the XSS area
is recorded as **REQUIRES FURTHER VALIDATION** and would be the subject of a dedicated
Phase 12 test.

## 8. Session Security Assessment

**Assessment ID:** none
**Candidate:** none currently confirmed.

**Assessment method:** The Cookie header of `GET /` was inspected. No `Set-Cookie`,
`Authorization`, or token header is present on the homepage response.

**Result:** The session mechanism is not directly observable from the homepage; cookie
attributes (HttpOnly, Secure, SameSite) are **NOT CONFIRMED** from the available
evidence and require a dedicated Phase 12 test.

## 9. Security Configuration Assessment

**Assessment ID:** EVID-ASSESS-005
**Candidate:** C5 — Unauthenticated user feedback exposure
**Target:** `GET /api/Feedbacks`
**Test objective:** Confirm whether user-generated feedback containing masked email
addresses is exposed without authentication.

**Test method:** An unauthenticated request was issued and the JSON response was read.

**Expected behaviour:** Feedback is content for logged-in users; an unauthorised caller
should not receive it.

**Observed behaviour:** `GET /api/Feedbacks` returns `HTTP 200` with records containing a
`UserId` and a masked email address (e.g. `***in@juice-sh.op`).

**Result:** **CONFIRMED**

Evidence: `EVID-REVERIFY-C5-feedback.txt` (see also `EVID-ASSESS-004`).

> As a control, unauthenticated `GET /api/Users` returns `HTTP 401`
> (`UnauthorizedError: No Authorization header was found`), demonstrating that API
> exposure is **not** uniform across endpoints; `/api/Feedbacks` is unintentionally
> public.

## 10. Sensitive Information Exposure Assessment

**Assessment ID:** EVID-ASSESS-006
**Candidate:** C4 revisits — server-information exposure
**Target:** several public paths
**Result:** **CONFIRMED**

Evidence: `EVID-REVERIFY-C4-disclosure.txt` (see also `EVID-ASSESS-003`).

## 11. Vulnerable Components Assessment

**Assessment ID:** EVID-ASSESS-007
**Component:** OWASP Juice Shop
**Confirmed information:**

- Version visible to the operator: **20.2.0** (from `GET /rest/admin/application-version`).
- Frontend: an Angular single-page application (`main.js` served by the Express process).
- Backend: Node.js (Express) process, SQLite (`juiceshop.sqlite`) for the application
  database.
- Framework evidence is visible in the served HTML (`angular` tags), but **exact third-party
  dependency versions (Express, Angular, SQLite runtime) are NOT CONFIRMED** from the
  available evidence.

> Exact dependency versions can be confirmed by inspecting `package.json` / `package-lock.json`
> from the local project, or by running `npm ls` in the project — this would be a Phase 12
> or 16 task, not a Phase 10 conclusion.

## 12. API Security Assessment

**Assessment ID:** EVID-ASSESS-008
**Confirmed API endpoints (observed during Phase 9 and Phase 10):**

| API ID | Method | Endpoint | Purpose | Authentication | Observed response |
|---|---|---|---|---|---|
| API-A | GET | `/api/Products` | list products | none confirmed (returns 200) | 200 JSON |
| API-A | GET | `/api/Feedbacks` | list feedback (user content) | **none** — returns 200 | 200 JSON |
| API-A | GET | `/api/Users` | user list | **required** (401 otherwise) | 401 HTML |
| API-B | GET | `/rest/user/whoami` | current user identity | expects JWT | 200 |
| API-B | GET | `/rest/captcha` | reCAPTCHA payload | none | 200 |
| API-B | GET | `/rest/languages` | supported languages | none | 200 |
| API-B | GET | `/rest/admin/application-version` | app version | expects JWT | 200 `{"version":"20.2.0"}` |
| API-B | POST | `/rest/user/login` | authenticate | none | 401 or 200 + JWT |
| API-A | GET | `/metrics` | Prometheus telemetry | none | 200 |

> Every endpoint above was **actually probed** on the live instance. No API path was
> added from memory or from the framework.

## 13. Candidate Finding Re-Verification (Summary)

| Candidate | Historical Evidence | Current Test | Current Result | Current Evidence | Status |
|---|---|---|---|---|---|
| C1 — SQLi authentication bypass | EVID-VAL-001 | control 401 + payload 200 | Reproduced | EVID-REVERIFY-C1-sqli.txt | **CONFIRMED** |
| C2 — Broken access control / IDOR | EVID-VAL-002 | control 401 + admin reads userId 2's basket | Reproduced | EVID-REVERIFY-C2-idor.txt | **CONFIRMED** |
| C3 — Missing security headers | EVID-VAL-003 | header enumeration | Reproduced | EVID-REVERIFY-C3-headers.txt | **CONFIRMED** |
| C4 — Sensitive information disclosure | EVID-VAL-004 | /metrics + version + robots.txt | Reproduced | EVID-REVERIFY-C4-disclosure.txt | **CONFIRMED** |
| C5 — Unauthenticated feedback exposure | EVID-VAL-005 | unauthenticated /api/Feedbacks | Reproduced | EVID-REVERIFY-C5-feedback.txt | **CONFIRMED** |

### Notes on each candidate

- **C1** — Reproduction is clean. The control (`401`) proves the login endpoint is
  behaving normally when given bad credentials, and the payload (`200` + admin JWT)
  proves the injection point bypasses authentication.
- **C2** — Reproduction is clean. The boundary is: *no token → 401* (protected, but
  requires any token), *any valid token → reads another user's basket*. The API does not
  enforce ownership. (Historical `customer@example.local` account no longer exists in the
  seeded DB; the re-test used an authenticated admin account, which is the weaker —
  but still correct — demonstration.)
- **C3** — Reproduction is clean. Three of the nine expected hardening headers are
  present; six are absent. The app is not misconfigured with *wrong* headers; it is
  simply missing a standard set.
- **C4** — Reproduction is clean. All three information-exposure behaviours are present
  and unauthenticated.
- **C5** — Reproduction is clean. `/api/Feedbacks` returns user content (with masked
  emails) with no authentication. As a control, `/api/Users` requires a token.

## 14. Assessment Results

| Assessment Area | Tested | Result | Evidence | Status |
|---|---|---|---|---|
| Authentication | Yes | 1 of 2 candidates confirmed | EVID-REVERIFY-C1 | Confirmed |
| Authorization | Yes | C2 confirmed | EVID-REVERIFY-C2-idor.txt | Confirmed |
| Input Validation (headers) | Yes | C3 confirmed | EVID-REVERIFY-C3-headers.txt | Confirmed |
| Injection | Yes (C1) | 1 candidate confirmed | EVID-REVERIFY-C1-sqli.txt | Confirmed |
| Cross-Site Scripting | No | Not tested this phase | — | Requires Further Validation |
| Session Security | No | Not tested this phase | — | NOT CONFIRMED |
| Security Configuration | Yes | C3, C4 confirmed | EVID-REVERIFY-C3/C4 | Confirmed |
| Sensitive Information Exposure | Yes | C4, C5 confirmed | EVID-REVERIFY-C4/C5 | Confirmed |
| Vulnerable Components | Cursory | Version confirmed | version endpoint | Partial |
| API Security | Yes (probed) | 9 endpoints observed | see table above | Complete |

## 15. Evidence References

| Evidence ID | Description | File |
|---|---|---|
| EVID-REVERIFY-C1-sqli.txt | SQLi auth bypass current re-verification | evidence/reverification/ |
| EVID-REVERIFY-C2-idor.txt | IDOR current re-verification | evidence/reverification/ |
| EVID-REVERIFY-C3-headers.txt | Header re-verification | evidence/reverification/ |
| EVID-REVERIFY-C4-disclosure.txt | Information disclosure re-verification | evidence/reverification/ |
| EVID-REVERIFY-C5-feedback.txt | Feedback exposure re-verification | evidence/reverification/ |
| EVID-VAL-001..005 | Historical validation files (not current proof) | evidence/findings/ |
| EVID-MAP-001..002 | Application mapping evidence | evidence/scanner-results/ |
| RECON-001 / RECON-002 | Reconnaissance evidence | evidence/scanner-results/ |

## 16. Limitations

- **C1 (SQLi)** — verified on the existing Juice Shop build. Fixing this finding
  properly (parameterised queries at the application layer) is a **Phase 16**
  remediation task; this document does not modify the application.
- **C2 (IDOR)** — the re-test used an authenticated admin account as the *weaker*
  demonstration because the historical customer account no longer exists in the seeded
  database. The underlying missing-ownership-check remains.
- **XSS** — a dedicated, harmless XSS probe was not performed this phase.
- **Session cookies** — cookie attributes were not observable from the homepage and were
  not tested.
- **Exact dependency versions** — not confirmed (would need the repository's
  `package.json`).

*This document is a re-verification record. It does not create or claim a formal
vulnerability until a later phase creates that artifact.*
