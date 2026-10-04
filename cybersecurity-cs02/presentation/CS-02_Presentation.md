# CS-02 — Presentation (15 slides)

Every figure below is produced by this project. No internet screenshots are used.

---

## Slide 1 — Project Title

**CS-02: Web Application Security Assessment of OWASP Juice Shop**
Assessment, Remediation and Re-testing
Environment: Linux Mint 22.3 · Node v22.23.3 · Juice Shop 20.2.0

---

## Slide 2 — Introduction

- OWASP Juice Shop: a deliberately vulnerable web application, widely used for
  hands-on application-security training.
- Its value here: real application code with realistic defects, so findings are
  genuine rather than contrived.
- Assessed as a live HTTP service, not read from source alone.

---

## Slide 3 — Problem Statement

- "Insecure by design" apps are studied, but remediation and **re-testing** are
  rarely demonstrated side by side.
- Risk is often quoted as a scanner severity label with no reasoning.
- A previous session of this project was serving a **directory listing**, not the
  application — assessment on the wrong artefact is worse than no assessment.
- Need: verified lab, evidence-backed findings, and fixes proven by re-test.

---

## Slide 4 — Objectives

1. Deploy and verify the real application (not a listing or a substitute).
2. Map the application and its attack surface.
3. Produce findings supported by reproducible evidence.
4. Score risk with reasoning, not scanner labels.
5. Remediate at least two findings without destroying the baseline.
6. Re-test those findings and prove before → after.

---

## Slide 5 — Scope

**In scope**
- Local lab application on `127.0.0.1:3000` and remediated build on `:3001`
- Authentication, authorization, access control, injection, session handling,
  security configuration, information exposure

**Out of scope / not done**
- No public or third-party target was tested at any point
- No automated scanner was available (nmap/Nikto/ZAP absent, `sudo` locked)
- XSS not confirmed and therefore **not** claimed
- Five findings remain open and are reported as open

---

## Slide 6 — Laboratory Architecture

```
  Test operator (Kali-style CLI / headless Chrome)
              |
              | authorised local HTTP traffic only
              v
    OWASP Juice Shop 20.2.0
    Node v22.23.3 · Express 4.22.2 · Angular SPA
    SQLite (Sequelize) -> data/juiceshop.sqlite
              |
              v
    Baseline      127.0.0.1:3000   UNMODIFIED
    Remediated    127.0.0.1:3001   FIX 1 + FIX 2
```
Host `10.59.163.195` is a LAN interface; the app binds loopback only, and
`check-lab.sh` verifies the LAN IP is **not** reachable.

---

## Slide 7 — The Application

- Verified as real Juice Shop: `<title>OWASP Juice Shop</title>`, `<app-root>`.
- Angular SPA renders **93 product tiles**, toolbar, nav drawer, product images.
- `main.js` 1.2 MB, `styles.css` 151 KB, REST API returns real seeded data.
- Root cause of an earlier 404: a stale baked absolute path
  (`/home/asta/Desktop/project bb/...`) held by a long-running process. Fixed by
  restarting from the correct directory — **not** by editing the app to fit port 5500.

---

## Slide 8 — Tools & Technologies

| Purpose | Tool actually used |
|---|---|
| Runtime | Node v22.23.3 (matches `engines.node: 22`) |
| HTTP probing | `curl` |
| Port scanning | Python `socket.connect_ex` |
| UI verification | Google Chrome headless (`--dump-dom`, `--screenshot`) |
| DB inspection | Python `sqlite3` (read-only) |
| Lifecycle | project scripts: `start/stop/check-lab.sh`, `capture-verification-evidence.sh` |

**Not available:** nmap, Nikto, ZAP, WhatWeb, Nuclei, Burp — no scanner output is claimed.

---

## Slide 9 — Methodology

1. Verify the lab serves the real application (not a listing)
2. Recon: ports, technologies, exposure
3. Map the application and its routes
4. Assess and **validate** each finding by a controlled HTTP test
5. Score risk on 4 factors with written reasoning
6. Copy the baseline; remediate in the copy only
7. Replay the **identical** test against both instances
8. Record before/after evidence; report open findings as open

---

## Slide 10 — Application Mapping

Real routes confirmed against the running app:

| Area | Endpoint | Auth |
|---|---|---|
| Auth | `POST /rest/user/login`, `POST /api/Users` | mixed |
| Users | `GET /api/Users`, `/api/Users/:id` | **any token** (defect) |
| Products | `GET /rest/products/search?q=` | none |
| Basket | `GET /rest/basket/:id` | token + ownership |
| Static | `/ftp`, `/encryptionkeys`, `/support/logs` | **none** (defect) |
| Telemetry | `/metrics`, `/rest/admin/application-version` | **none** (defect) |

---

## Slide 11 — Major Findings (10)

| ID | Finding | Sev |
|---|---|---|
| WEB-VUL-001 | SQLi authentication bypass | High |
| WEB-VUL-002 | Basket IDOR | High |
| WEB-VUL-003 | Missing security headers | Medium |
| WEB-VUL-004 | Unauthenticated info disclosure | Medium |
| WEB-VUL-005 | Unauthenticated feedback exposure | Low |
| WEB-VUL-006 | Broken function-level authz on `/api/Users` | High |
| WEB-VUL-007 | Password hash embedded in JWT | **Critical** |
| WEB-VUL-008 | Unauthenticated encryption key exposure | High |
| WEB-VUL-009 | SQLi in product search + SQLite error leak | High |
| WEB-VUL-010 | Wildcard CORS | Medium |

Distribution: **Critical 1 · High 5 · Medium 3 · Low 1**

---

## Slide 12 — Security Impact (measured)

- **WEB-VUL-007:** token decodes with no secret →
  `"password":"0192023a7bbd73250516f069df18b500"`; `md5("admin123")` matches, so the
  **plaintext password** is recovered in one hash operation.
- **WEB-VUL-009:** `' OR '1'='1` → **46 rows** vs 3 for `apple`; plus
  `500 SQLITE_ERROR: incomplete input` naming the database engine.
- **WEB-VUL-006:** a `customer` token lists **the entire user directory incl. every admin**,
  while no token correctly gets 401.
- **WEB-VUL-008:** `jwt.pub` served anonymously — 248 B of real key material.

---

## Slide 13 — Remediation (what was actually changed)

Baseline **preserved**: `lab/juice-shop_20.2.0` still running on :3000, MD5 unchanged.
Fixes applied only in `lab/juice-shop_20.2.0-remediated` (:3001).

| # | Finding | Change | File |
|---|---|---|---|
| REMED-002 | WEB-VUL-008 | Removed both `/encryptionkeys` routes | `build/server.js`, `server.ts` |
| REMED-002b | WEB-VUL-008 | Explicit `404` handler (SPA catch-all was answering 200) | `build/server.js` |
| REMED-001 | WEB-VUL-010 | CORS allow-list **array** of own origins | `build/server.js`, `server.ts` |

The other five findings carry **recommendations only** and are reported as open.

---

## Slide 14 — Re-testing & Results

| Finding | Before (:3000) | After (:3001) | Status |
|---|---|---|---|
| WEB-VUL-010 | `ACAO: *` for `evil.example` | 204, **no ACAO** | **RETESTED / REMEDIATED** |
| WEB-VUL-008 | 200, 248 B **key material** | **404** `Not Found`, no key | **RETESTED / REMEDIATED** |

**Key lesson:** REMED-001 was wrong twice before it worked — cors echoes a string
`origin` unvalidated, and a falsy callback broke the preflight into a 500. Only an
**array** allow-list is correct. REMED-002 was then caught returning 200 via the SPA
catch-all and repaired to 404. Regression: 93 product tiles render, login works,
`check-lab.sh` = PASS.

---

## Slide 15 — Conclusion

- **5 remediated and re-tested** (001, 002, 003, 008, 010).
- **5 still open** (004, 005, 006, 007, 009) — reported honestly, not as fixed.
- Highest-value lesson: *status-code-only re-testing is not enough*. REMED-002
  returns HTTP 200 after the fix; only content comparison proved it worked.
- Next: close WEB-VUL-007 (JWT secrets) and WEB-VUL-009 (search SQLi) — the two
  findings with the highest impact-to-fix ratio remaining.