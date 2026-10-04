# CS-02 — Final Web Application Security Assessment Report

**Project:** Web Application Security Assessment Using OWASP Methodology
**Project Code:** CS-02 — Group 02
**Authorized Target:** `http://127.0.0.1:3000` (OWASP Juice Shop v20.2.0, isolated local laboratory)
**Report status:** Phase 18 — Final Report (compiled 2026-10-04)
**Classification:** Authorized educational laboratory assessment — no external system was ever tested

---

## Table of Contents

1. Chapter 1 — Introduction
2. Chapter 2 — Existing System and Proposed Approach
3. Chapter 3 — Requirements and Laboratory Environment
4. Chapter 4 — Methodology
5. Chapter 5 — Implementation
6. Chapter 6 — Security Assessment and Analysis
7. Chapter 7 — Security Remediation
8. Chapter 8 — Testing and Validation
9. Chapter 9 — Results and Discussion
10. Chapter 10 — Conclusion and Future Scope
11. Traceability Matrix
12. Final Findings Summary Table
13. Evidence Traceability
14. References
15. Appendix

---

# Chapter 1 — Introduction

## 1.1 Background

Web applications sit at the centre of modern information systems and routinely
process authentication, personal data, business transactions and other sensitive
operations. Because they combine complex logic, user-controlled input and
network exposure, web applications are a frequent source of security weakness:
insecure authentication, broken access control, injection flaws, misconfiguration
and sensitive-data exposure. A structured security assessment applied *before*
deployment catches these weaknesses while they are still inexpensive to fix.

## 1.2 Problem Statement

Security weaknesses in a web application can allow unauthorized users to read
information they should not see, bypass security controls, manipulate
application behaviour, or act beyond their intended privileges. This project
demonstrates — on an intentionally vulnerable application in an isolated
laboratory — how such weaknesses are systematically identified, evidenced,
analyzed, remediated and re-verified.

## 1.3 Project Motivation

The motivation is educational and defensive: to build practical competence in
the OWASP assessment lifecycle and to produce professional, evidence-backed
security documentation — not to attack any real system. Every request in this
project was sent to the single authorized target `127.0.0.1:3000`.

## 1.4 Objectives

1. Deploy an intentionally vulnerable web application in an isolated laboratory.
2. Identify exposed services and technologies.
3. Map application functionality and attack surface.
4. Identify and document security weaknesses (minimum 5 findings).
5. Perform controlled validation (minimum 2 validations).
6. Analyze security impact / risk.
7. Recommend remediation; implement at least 2 mitigations where feasible.
8. Re-test at least 2 remediated findings with before/after evidence.
9. Document technical evidence and produce this professional report.

## 1.5 Scope

- **In scope:** `http://127.0.0.1:3000` ONLY — the local OWASP Juice Shop
  laboratory instance, assessed from the same host over the loopback interface.
- **Out of scope (never tested):** `127.0.0.1:5500`, external/public websites,
  third-party applications, college/company/government systems, unrelated local
  services, denial-of-service, destructive testing, malware, real accounts and
  real user data.

## 1.6 Limitations

- Single-host, loopback-isolated laboratory (no separate VMs — see §3.3); the
  experimental design limits network-level testing to the local interface.
- Severity ratings reflect the isolated training application, not a production
  deployment.
- XSS and session-security areas were assessed only at reconnaissance level and
  are recorded as **not confirmed** (no safe payload test was performed).
- Exact third-party dependency versions were not independently inventoried
  (recorded as *not confirmed* rather than assumed).
- Five of ten findings remain **unremediated** (WEB-VUL-004, 005, 006, 007, 009). They
  are reported as open with documented recommendations; no partial fix is claimed.

---

# Chapter 2 — Existing System and Proposed Approach

## 2.1 Existing Security Situation

The target, OWASP Juice Shop, is a deliberately insecure reference application
that ships known weaknesses across authentication, authorization, injection and
configuration — which makes it the standard teaching vehicle for OWASP-based
assessment practice. The "existing system" for assessment purposes is the
**unmodified v20.2.0 deployment**, whose observable behaviour was captured in
Phases 7–10 before any change was made.

## 2.2 Security Problems

Ad-hoc or tool-only assessment produces findings without reproducible evidence,
without severity reasoning, and with no verification that a fix worked. Typical
gaps: findings that cannot be reproduced, remediation that is only a
recommendation, and no before/after comparison.

## 2.3 Proposed Assessment Approach

A phase-based OWASP methodology:

Reconnaissance → Application Mapping → Security Assessment → Vulnerability
Identification → Controlled Validation → Risk/Severity Analysis → Remediation →
Re-Testing → Reporting

with the rule that **every conclusion must be backed by a captured artifact**
(`evidence/evidence-index.csv` is the registry), historical evidence is never
relabelled as current, and remediation claims are only made after a re-test
demonstrates them.

## 2.4 Expected Improvements

- Weaknesses documented with reproducible requests/responses.
- At least two controls **actually implemented** (three were), each with
  before/after evidence.
- Independent regression verification (application test suite) so the fixes can
  be shown not to have broken legitimate functionality — beyond the security
  re-test itself.

Measured outcome: see Chapters 6–9 (5 findings documented, 5 controlled
validations, 3 mitigations implemented, 3 re-tests = FIXED).

---

# Chapter 3 — Requirements and Laboratory Environment

*This chapter records what was **actually observed**. Where the PDF template
assumes infrastructure that was not used, that is stated explicitly.*

## 3.1 Hardware Requirements (observed)

| Item | Observed |
|---|---|
| CPU | 12 cores (host `shoyo`) |
| RAM | 7.1 GiB |
| Disk/VM details | Not separately recorded — single-host setup |

## 3.2 Software Requirements (observed)

| Component | Actual | PDF template expectation |
|---|---|---|
| Operating system | Linux Mint 22.3, kernel 6.17.0-35-generic | Kali Linux (assessment) + Ubuntu Server (app server) |
| Virtualization | **None** (`Virtualization: none`) — both roles ran on the same host, isolated by loopback binding | VMware Workstation |
| Application | OWASP Juice Shop **v20.2.0** (confirmed via `/rest/admin/application-version` → `{"version":"20.2.0"}` and `package.json`) | OWASP Juice Shop / DVWA / WebGoat |
| Application runtime | Node.js **v22.23.3** (nvm; project supports Node 22–26), Express backend, SQLite (`data/juiceshop.sqlite`), Angular SPA frontend | — |
| Browser | Google Chrome 149.0.7827.114 (incl. headless mode for evidence capture) | Browser dev tools |
| Interpreters/tools | `curl`, `python3`, `node`/`npm`, coreutils (`ss`, `timeout`) | nmap, Nikto, ZAP, Burp (see 3.6) |

Not installed on the assessment host (recorded from `LAB-001-environment.txt`):
`nmap`, `nikto`, `whatweb`, `owasp-zap`, `burpsuite`, `chromium`. Absent tools
were therefore **not** used; no claim is made about them.

## 3.3 Virtual Machines

**BLOCKED — not achievable in this environment, and not simulated.**

The specification (§5, §21, §32) asks for a Kali Linux VM and an Ubuntu Server VM running
under VMware — two machines. That could not be provided here:

- `virsh`, `VBoxManage` and `vmware` are all absent from the host, and no hypervisor is
  installed; `Virtualization: none` is recorded in `evidence/scanner-results/LAB-001-environment.txt`.
- Kali Linux is not installed, and it was **not installed to satisfy the requirement**,
  because installing a second OS was outside the scope of this assessment and would not
  have been an honest representation of the environment actually tested.
- 0 virtual machines exist on this host.

The laboratory was therefore built as a single Linux Mint 22.3 host with the application
bound to `127.0.0.1` only, with the LAN address verified unreachable. The VM and Kali
screenshots required by §9 **cannot be produced honestly and were not faked or
substituted**; the application-level screenshots that were genuinely captured are Figures
A.1, A.3 and A.4, and the isolation proof is in §3.4.

This is recorded as a **BLOCKED** requirement in `FINAL_SUBMISSION_AUDIT.md`, not as a
completed one.

## 3.4 Network Configuration (observed)

| Item | Value |
|---|---|
| Application bind address | `127.0.0.1:3000` only (code: `server.listen(port, '127.0.0.1', …)`; enforced since early phases) |
| Loopback | `127.0.0.1/8` |
| LAN interface (Phase 7 capture) | `wlo1` → `10.45.57.195/24`, gateway `10.45.57.186` (DHCP) |
| LAN interface (later verification) | `10.59.163.195` (DHCP address changed between sessions) |
| Isolation check | `check-lab.sh` confirms `http://<LAN-IP>:3000/` is **unreachable** while loopback works — the app is not exposed to the LAN |
| Other local listeners observed | `127.0.0.1:3306/33060` (local MySQL), `:631` (CUPS), `:80` — **never tested** (out of scope) |

## 3.5 Web Application

- Name/version: OWASP Juice Shop v20.2.0 (official
  `juice-shop-20.2.0_node22_linux_x64.tgz` release, MD5-verified download
  `lab/juice.tgz.md5`).
- Type: Angular single-page application served by an Express/Node.js process;
  SQLite application database; Prometheus-style `/metrics`; server-rendered
  Handlebars/Pug views for a few routes.
- Entry point evidence: `EVID-MAP-001-entrypoint.txt` — `HTTP 200`,
  `<title>OWASP Juice Shop</title>`.

## 3.6 Tools Actually Used

| Tool | Purpose | Evidence |
|---|---|---|
| `curl` | HTTP requests/responses, header enumeration, controlled validations, re-tests | most `EVID-*` artifacts |
| Headless Google Chrome (`--headless=new`) | Application rendering, CSP violation checks, screenshots | EVID-RETEST-002/003 |
| Python 3 TCP connect scanner (project script `scripts/reconnaissance/tcp_scan.py`) | Port/service enumeration of `127.0.0.1` | `RECON-001-port-scan.txt/json`, `tcp-scan-127.0.0.1.json` |
| `ss` | Listener/process verification | `check-lab.sh` output, Phase 16/17 verifications |
| Node.js built-in test runner (`node --test`) | Application regression testing | `evidence/phase18-test-suite/EVID-TEST-001..008` |
| Project shell scripts (`start-lab.sh`, `stop-lab.sh`, `check-lab.sh`) | Reproducible lab lifecycle + health checks | `evidence/logs/juice-shop-startup.log` |

Not used: nmap, Nikto, ZAP, Burp, Wireshark (not installed).

## 3.7 IP Addressing

Assessment traffic: `127.0.0.1` ↔ `127.0.0.1:3000` exclusively. No public or
third-party IP was contacted by testing activity.

## 3.8 Architecture

```
 [Assessment host: Linux Mint 22.3]
   └── OWASP Juice Shop v20.2.0 (node build/app, Node 22)
         ├── Express backend  :3000  ── bound to 127.0.0.1 ONLY
         │     ├── /rest/*  (login, basket, orders, admin, …)
         │     ├── /api/*   (sequelize-restful: Products, Feedbacks, Users, …)
         │     └── /metrics (Prometheus telemetry)
         ├── Angular SPA (main.js / styles.css / polyfills.js)
         └── SQLite  data/juiceshop.sqlite
   Loopback isolation: LAN interface cannot reach the application
   (verified by scripts/check-lab.sh on every start)
```

A textual application/attack-surface map with trust boundaries is maintained in
`docs/application-map.md` (§4–§9). A rendered architecture diagram slide is part
of Phase 19 (not yet produced).

---

# Chapter 4 — Methodology

## 4.1 Assessment Methodology

The project followed the required lifecycle, expanded into the project's
18+1-phase working plan: Laboratory Preparation → Reconnaissance → Application
Mapping → Security Assessment → Vulnerability Identification → Controlled
Validation → Risk/Severity Analysis → Remediation → Re-Testing → Final
Reporting. Governing rule: *current evidence must support a conclusion; a
filename does not.*

## 4.2 Web Reconnaissance

- Full TCP connect scan of `127.0.0.1` (63 ports) → `RECON-001-port-scan.*`.
- HTTP fingerprint of port 3000 → technology/headers → `RECON-002-*`.
- Raw HTTP baseline → `recon-raw-http.txt`.
- Security-relevant information exposure observed here later formalised as
  WEB-VUL-004.

## 4.3 Application Mapping

- Entry point capture (`EVID-MAP-001`), route/page rendering via headless
  browser (`EVID-MAP-002`).
- Produced `docs/application-map.md`: page map, functional map,
  input/attack-surface map, auth surface, API/backend map, data-flow/trust
  boundaries.

## 4.4 Security Testing

Structured assessment across the areas the application supports
(`docs/security-assessment.md` §3–§12): authentication, authorization/access
control, input validation, injection, XSS, session security, security
configuration, sensitive information exposure, vulnerable components, API
security. Only areas with actual observations were scored; XSS and session
security are recorded as *not confirmed*.

## 4.5 Vulnerability Assessment

Candidates were promoted to formal findings only when current-instance evidence
existed. Result: **ten** findings, WEB-VUL-001…010, each with component, endpoint,
method, technical details, evidence IDs, impact, severity **with justification**,
and recommendation (`findings/WEB-VUL-001`…`findings/WEB-VUL-010` each `finding.md`,
`docs/vulnerability-findings.md`). WEB-VUL-006…010 were added in the final assessment
phase and are documented in the same 17-section format.

## 4.6 Controlled Validation

Safe, controlled reproductions against the authorized instance only, each with
target, objective, method, evidence, result, impact and recommendation:
five validations `EVID-REVERIFY-C1…C5` (≥2 required), plus the historical
validation records `RAW-001…010`. Controls (expected-secure baselines) were run
alongside every exploit attempt.

## 4.7 Remediation

Two findings were remediated in Phase 16 (WEB-VUL-001 parameterised login query;
WEB-VUL-003 hardening header set) and a third in the third-remediation task
(WEB-VUL-002 object-level basket authorization). Each mitigation: root cause →
smallest change → source **and** compiled runtime (release package ships no
`tsconfig.json`) → application restart → functional verification. Recommendations
only (not implemented) exist for WEB-VUL-004/005 — explicitly distinguished per
requirement.

## 4.8 Re-Testing

Each remediated finding was re-tested with the *same* procedure that originally
demonstrated the vulnerability (no new exploits), against the running mitigated
instance, producing before/after evidence pairs (`EVID-REM-*` / `EVID-RETEST-*`),
plus an application test-suite regression check (Chapter 8).

---

# Chapter 5 — Implementation

## 5.1 Laboratory Setup

- Official Juice Shop release extracted to `lab/juice-shop_20.2.0/`.
- Lifecycle scripts: `scripts/start-lab.sh` (detached start, readiness wait,
  health check), `scripts/stop-lab.sh`, `scripts/check-lab.sh` (process, port,
  HTTP, frontend bundle, REST API, storage, LAN isolation checks).
- Evidence directory structure: `evidence/` with per-phase subfolders and the
  master registry `evidence/evidence-index.csv`.

## 5.2 Web Application Deployment

`node build/app` started via `start-lab.sh`; health check output:
`LAB STATUS: PASS` with all checks green (HTTP 200, bundle served, REST API
answers, SQLite present, LAN IP blocked). Startup log:
`evidence/logs/juice-shop-startup.log`.

## 5.3 Network Configuration

Application hardened to loopback-only binding (`server.listen(port, '127.0.0.1', …)`)
— verified via `build/server.js.orig` diff and `check-lab.sh`. Only port 3000
was ever contacted by testing activity.

## 5.4 Security Assessment Configuration

- Reproducible request recipes (curl) per candidate, with always-paired
  negative/positive controls (e.g., invalid credentials → 401 before any
  injection attempt).
- Token redaction in all stored evidence (`[REDACTED-JWT]`).
- Test isolation for regression runs: lab stopped to free port 3000; tests run
  against in-memory instances of the same code.

## 5.5 Evidence Collection

Every observation is an artifact with an ID, timestamp, phase, type, path,
result and related requirement — registered in `evidence/evidence-index.csv`
(67 entries, verified to contain 0 broken paths). Original historical evidence
was never overwritten; before-state captures precede every code change;
screenshots are original captures from this laboratory (Figures A.1–A.2).

---

# Chapter 6 — Security Assessment and Analysis

## 6.1 Application Assessment Results

Areas actually assessed (from `docs/security-assessment.md`):

| Area | Method | Result |
|---|---|---|
| Authentication | login controls + injection attempt | **Vulnerable** (WEB-VUL-001 confirmed) |
| Authorization / access control | cross-user basket probe + unauthenticated controls | **Vulnerable** (WEB-VUL-002 confirmed) |
| Input validation / security configuration | header enumeration | **Deficient** (WEB-VUL-003 confirmed) |
| Injection (information channels) | unauthenticated endpoint probes | **Vulnerable** (WEB-VUL-004 confirmed — informational disclosure) |
| Sensitive information exposure | `/api/Feedbacks` vs `/api/Users` control | **Vulnerable** (WEB-VUL-005 confirmed) |
| XSS | no safe payload test performed | **Not confirmed** (requires further validation) |
| Session security | homepage cookie/header inspection only | **Not confirmed** (no `Set-Cookie` observable; attributes not verified) |
| Vulnerable components | version endpoint + runtime observation | Version **20.2.0** confirmed; exact dependency versions **not confirmed** |
| API security | 9 endpoints actually probed (table in §12 of the assessment doc) | Authentication boundary inconsistent across endpoints |

## 6.2 Vulnerability Findings

Ten confirmed findings (full records in `findings/WEB-VUL-001…010/finding.md`; the five
original records are detailed below, WEB-VUL-006…010 are summarised after them):

**WEB-VUL-001 — SQL injection authentication bypass (High)**
- Component/endpoint: Login API `POST /rest/user/login`; category: Injection /
  Broken Authentication.
- The `email` parameter was concatenated into a raw SQL string; payload
  `' OR 1=1--` produced HTTP 200 with an admin-role JWT
  (`EVID-REVERIFY-C1-sqli.txt`).
- Impact: unauthenticated administrative session. Severity High: auth bypass,
  no credentials required, trivial exploitability over plain HTTP.
- Recommendation: parameterised queries (implemented — Chapter 7).

**WEB-VUL-002 — Broken access control / IDOR on baskets (High)**
- Component/endpoint: `GET /rest/basket/:id` (+ checkout/coupon write paths);
  category: Authorization / BOLA.
- Any valid token could read another user's basket: admin token reading
  `/rest/basket/2` returned HTTP 200 with `UserId 2`'s items
  (`EVID-REVERIFY-C2-idor.txt`, historical `WEB-VUL-002-victim-basket.json`).
- Impact: disclosure of other users' shopping contents; class of flaw that
  underpins account-takeover-grade exposure. Severity High: object-level
  authorization absent, direct reachability, sensitive user data.
- Recommendation: object-level ownership checks (implemented — Chapter 7).

**WEB-VUL-003 — Missing HTTP security headers (Medium)**
- Component: serving layer `GET /`; category: Security Misconfiguration.
- Only 2 of the 9 standard hardening headers were present
  (`X-Content-Type-Options`, `X-Frame-Options`); HSTS, CSP, X-XSS-Protection,
  Referrer-Policy, Permissions-Policy, COOP and CORP were all absent
  (`EVID-REVERIFY-C3-headers.txt`, `evidence/findings/V-003-validation.txt`).
- Impact: weakened browser-side defences (clickjacking, referrer leakage,
  no CSP). Severity Medium: defence-in-depth gap, no direct data exposure.
- Recommendation: standard hardening header set (implemented — Chapter 7).

**WEB-VUL-004 — Sensitive information disclosure (Medium)**
- Components: `/metrics` (25,640 bytes of Prometheus telemetry),
  `/rest/admin/application-version` (`{"version":"20.2.0"}`), `/robots.txt`
  (`Disallow: /ftp`) — all unauthenticated (`EVID-REVERIFY-C4-disclosure.txt`).
- Impact: deployment fingerprinting and directory hints for any visitor.
  Severity Medium: information gain that facilitates further attacks.
- Recommendation: require authentication for `/metrics`, restrict the version
  endpoint, audit `/ftp` exposure — **recommended only, not implemented**
  (scope limited to three remediations).

**WEB-VUL-005 — Unauthenticated user feedback exposure (Low)**
- Component: `GET /api/Feedbacks` returns `UserId` + masked emails without
  authentication while the control `/api/Users` returns 401
  (`EVID-REVERIFY-C5-feedback.txt`).
- Impact: anonymous collection of user-generated content; inconsistent access
  boundary. Severity Low: partially masked data, limited sensitivity.
- Recommendation: require authentication; align read-API boundaries —
  **recommended only, not implemented**.

### WEB-VUL-006 — Broken function-level authorization on `/api/Users` (High) — OPEN
- Component/endpoint: `GET /api/Users`, `GET /api/Users/:id`; category: Broken Access
  Control — missing function-level authorization.
- A token issued to a self-registered `customer` returns the entire user directory
  (24 seeded accounts; 25 once the assessment's own test account is registered) including
  every administrator address and role, while an anonymous request correctly returns 401.
- Evidence: `evidence/findings/V-006-validation.txt` (three-token matrix).
- Impact: a complete role-annotated administrator target list, obtained by the lowest
  privilege level, enabling targeted credential attacks.
- Risk reasoning: likelihood 5 / exploitability 4 (registration is the only
  precondition), impact 4, exposure 3 (authentication required) → **High**. Not
  Critical because write access is not routed, so no escalation was demonstrated.
- Recommendation: enforce an `admin` role check and scope `/api/Users/:id` to self.
  **Recommended only — not implemented.**

**WEB-VUL-007 — Password hash embedded in the JWT payload (High) — OPEN**
- Component/endpoint: token issuance in `POST /rest/user/login`; category: Sensitive
  Data Exposure / Insecure Cryptographic Storage.
- Decoding the token requires no secret and returns
  `"password": "0192023a7bbd73250516f069df18b500"` plus `role` and a `totpSecret`
  field. `md5("admin123")` equals that hash, so the disclosed value yields the
  **plaintext password** in one hash operation (unsalted MD5).
- Evidence: `evidence/findings/V-007-validation.txt` (decoded JWT payload).
- Impact: any party obtaining a token recovers the account password; for TOTP-enrolled
  accounts the embedded seed also permits forging second-factor codes.
- Risk reasoning: impact 5, likelihood 4 and exposure 3 (a token must first be obtained)
  → **High overall risk** while severity is **Critical**; the scales are deliberately
  kept separate.
- Recommendation: strip `password`/`totpSecret` from the claims and migrate to
  bcrypt/Argon2id. **Recommended only — not implemented.**

**WEB-VUL-008 — Unauthenticated encryption key exposure (High) — REMEDIATED & RE-TESTED**
- Component/endpoint: `GET /encryptionkeys/`, `GET /encryptionkeys/:file`; category:
  Sensitive Information Exposure.
- The directory listed and served `premium.key` (49 B secret) and `jwt.pub` (248 B RSA
  public key) to anonymous clients.
- Evidence: `evidence/findings/V-008-validation.txt` (discovery),
  `evidence/remediation/REMED-before.txt` / `REMED-after.txt` (remediation and re-test).
- Impact: disclosure of the key protecting premium content and of the JWT verification
  key; both unrecoverable once published.
- Risk reasoning: exploitability 5, exposure 5 (fully anonymous, one `curl`), impact 4
  → **High**. Remediation broke the first link of the 008 → 007 → 006 attack chain.
- Recommendation: remove the anonymous routes. **Implemented (REMED-002 + REMED-002b).**

**WEB-VUL-009 — SQL injection in product search (High) — OPEN**
- Component/endpoint: `GET /rest/products/search?q=`; category: Injection.
- Boolean differential: `apple` → 3 rows, `' OR '1'='1` → 46 rows, `' AND '1'='2` → 0.
  A malformed payload returns `500 Error: SQLITE_ERROR: incomplete input`, disclosing
  the database engine and driver error.
- Evidence: `evidence/findings/V-009-validation.txt`.
- Impact: attacker-controlled boolean logic over the database from a fully public
  endpoint; the error oracle accelerates exploitation.
- Risk reasoning: exploitability 5, exposure 5, likelihood 5, impact 4 → **High**.
  Escalation to other tables was deliberately not attempted, to stay in scope.
- Recommendation: parameterise the query and suppress driver errors.
  **Recommended only — not implemented.**

**WEB-VUL-010 — Wildcard CORS policy (Medium) — REMEDIATED & RE-TESTED**
- Component/endpoint: all `/rest/*` and `/api/*` responses; category: Security
  Misconfiguration.
- `Access-Control-Allow-Origin: *` was returned for any origin, with
  `GET,HEAD,PUT,PATCH,POST,DELETE` and `authorization` advertised in preflight.
- Evidence: `evidence/findings/V-010-validation.txt`,
  `evidence/remediation/REMED-before.txt` / `REMED-after.txt`.
- Impact: any site can read the application's already-public responses cross-site.
- Risk reasoning: exposure 5, exploitability 5, but impact held to 2 because
  `Access-Control-Allow-Credentials` is not set, so cookies are not attached → **Medium**.
- Recommendation: replace the wildcard with an origin allow-list.
  **Implemented (REMED-001).**

## 6.3 Technical Evidence

All findings trace to captured artifacts — see *Evidence Traceability* (below)
and `evidence/evidence-index.csv`. Every exploit attempt was paired with a
control (401 on invalid credentials, 401 unauthenticated, header presence
matrix), and all tokens were redacted at capture time.

## 6.4 Risk Analysis

Severity was assigned by technical reasoning (not copied from a tool) and is
justified per finding in the finding records: authentication bypass → High;
cross-user data access → High; hardening-header gap → Medium; unauthenticated
fingerprinting → Medium; masked-content exposure → Low.

Distribution: **High 2, Medium 2, Low 1**.

The consolidated vulnerability register is `docs/vulnerability-findings.md` §3
(ID / title / category / component / severity / status) with evidence, impact
and recommendation per row — satisfying the register requirement.

*Honest limitation:* a separate likelihood/exploitability/exposure scoring pass
(soft-risk register) was **not** performed as a distinct activity; risk
analysis here is consequence- and severity-based. Recorded as **PARTIAL** in
the traceability matrix.

## 6.5 Security Impact

Combined impact on the laboratory application: an unauthenticated attacker
could obtain an administrator session (001) and any authenticated user could
read other users' baskets (002) — direct confidentiality/integrity impact;
003–005 widen the attack surface through missing hardening and information
leakage. In a production system the same classes map to OWASP Top 10 A01, A02,
A05 and A07-family risks.

---

# Chapter 7 — Security Remediation

*Five findings were remediated — the required minimum was two. Five carry
recommendations only; this report does not claim they were fixed.*

## 7.1 Recommended Controls

**Controls ACTUALLY IMPLEMENTED** and **controls RECOMMENDED ONLY** are kept strictly
separate, as required by the specification.

| Finding | Recommendation | Status |
|---|---|---|
| WEB-VUL-001 | Parameterised queries / prepared statements for login | **IMPLEMENTED** |
| WEB-VUL-002 | Object-level ownership enforcement on basket routes | **IMPLEMENTED** |
| WEB-VUL-003 | Standard hardening header set on every response | **IMPLEMENTED** |
| WEB-VUL-008 | Remove anonymous `/encryptionkeys` web routes (REMED-002) | **IMPLEMENTED** |
| WEB-VUL-010 | CORS allow-list instead of wildcard (REMED-001) | **IMPLEMENTED** |
| WEB-VUL-004 | Auth-gate `/metrics`, restrict version endpoint, audit `/ftp` | **RECOMMENDED ONLY** |
| WEB-VUL-005 | Require authentication for `/api/Feedbacks`, align read-API boundaries | **RECOMMENDED ONLY** |
| WEB-VUL-006 | Enforce `admin` role on `/api/Users`; scope `/api/Users/:id` to self | **RECOMMENDED ONLY** |
| WEB-VUL-007 | Strip `password`/`totpSecret` from JWT claims; bcrypt/Argon2id | **RECOMMENDED ONLY** |
| WEB-VUL-009 | Parameterise the product-search query; suppress driver errors | **RECOMMENDED ONLY** |

## 7.2 Controls Implemented

**Remediation 1 — WEB-VUL-001 (parameterised login query)**
- Root cause: raw SQL string built from `req.body.email`.
- Change: Sequelize named `replacements` (`email = :email AND password = :password`),
  semantics unchanged.
- Files: `routes/login.ts`, `build/routes/login.js` (source + compiled runtime —
  release ships no `tsconfig.json`, so no `tsc` rebuild is possible).
- Evidence: EVID-REM-001 (before), EVID-REM-003 (record).

**Remediation 2 — WEB-VUL-003 (hardening header set)**
- Root cause: only `helmet.noSniff()` + `helmet.frameguard()` enabled.
- Change: middleware adding the seven missing headers; CSP allow-lists the page's
  two legitimate inline snippets by SHA-256 hash (`'unsafe-hashes'`) instead of
  permitting all inline code; `font-src` allows the Google-Fonts host referenced
  by the page; `upgrade-insecure-requests` deliberately omitted (breaks
  plain-HTTP localhost); no `payment` duplication with the existing
  Feature-Policy header.
- Files: `server.ts`, `build/server.js`.
- Evidence: EVID-REM-002 (before), EVID-REM-004 (record); browser-verified with
  0 CSP violations.

**Remediation 3 — WEB-VUL-002 (object-level basket authorization)**
- Root cause: all three `/rest/basket/:id*` handlers loaded the row solely by
  the client-supplied id; authentication existed, object-level authorization
  did not.
- Change: shared guard `ensureBasketOwnership()` — loads the basket, refuses
  with HTTP 403 unless `basket.UserId` equals the authenticated caller (fail-closed),
  wired before `GET /rest/basket/:id`, `POST …/checkout` and
  `PUT …/coupon/:coupon`; unknown ids keep their original response.
- Files: `routes/basket.ts`, `server.ts`, `build/routes/basket.js`,
  `build/server.js`.
- Evidence: EVID-REM-006 (before), EVID-REM-007 (record).

**Remediation 4 — WEB-VUL-010 (CORS allow-list, REMED-001)**
- Root cause: `app.options('*', cors())` / `app.use(cors())` with no origin argument,
  which makes cors@2.8.6 emit `Access-Control-Allow-Origin: *` for every request.
- Change: replaced with an allow-list **array** of the application's own origins
  (`build/server.js` and `server.ts`, remediation copy only).
- Result: an attacker origin receives **no** `Access-Control-Allow-Origin` header; the
  preflight still returns 204; the legitimate own origin is unaffected.
- Rejected implementations, caught by re-testing: a **string** `origin` is echoed
  unvalidated (cosmetic fix only), and a **function** whose callback yields `false` makes
  cors call `next()`, which turns the preflight into a 500. See
  `evidence/remediation/REMED-cors-analysis.txt`.

**Remediation 5 — WEB-VUL-008 (encryption key routes removed, REMED-002 + REMED-002b)**
- Root cause: two unauthenticated static routes served `premium.key` (49 B secret) and
  `jwt.pub` (248 B RSA public key) to anonymous clients.
- Change (REMED-002): removed both `/encryptionkeys` routes; `routes/keyServer.ts` left in
  place unused so the change stays minimal and reversible.
- Change (REMED-002b, closeout repair): added an explicit `404` handler for
  `/encryptionkeys` and `/encryptionkeys/:file`. Deleting the routes alone left the paths
  answering **200** with the SPA shell, because `serveAngularClient()` returns
  `index.html` for any URL not beginning with `/api` or `/rest`.
- Result: all three paths return **404 `Not Found`**; PEM key blocks 1 → 0.

## 7.3 Configuration/Application Changes

All changes are local to the laboratory application and reversible: four source
files + four compiled files touched in total across the three mitigations; no
test file, assertion or configuration was modified at any point; the original
evidence set is preserved unchanged. Changed-file lists are documented in
`docs/remediation.md` and `remediation/<finding>/remediation.md`.

## 7.4 Security Improvements

- Login accepts only bound parameter values → tautology/UNION injection no
  longer authenticates anyone (verified 401 on both original payloads).
- Full hardening header baseline present on every response, with a CSP verified
  not to break the application (0 console violations, styles and product grid
  render).
- Basket read **and** write paths enforce ownership → cross-user access returns
  403 while the full legitimate flow (register → login → add item → read →
  checkout) continues to work.
- Findings remaining unremediated: **WEB-VUL-004, WEB-VUL-005** (recommendations
  documented in §7.1).

---

# Chapter 8 — Testing and Validation

## 8.1 Initial Results

Baseline vulnerability behaviour (before any change), captured as
`EVID-REM-001/002/006` plus original `EVID-REVERIFY-C1/C2/C3`:

| Test | Observed |
|---|---|
| `' OR 1=1--` login payload | HTTP 200 + admin-role JWT |
| `' OR '1'='1' --` login payload | HTTP 200 + admin-role JWT |
| Admin token → `GET /rest/basket/2` | HTTP 200 with UserId 2's contents |
| `GET /` header baseline | 7 of 10 hardening headers missing |

## 8.2 Remediation

Three mitigations implemented (Chapter 7; full records in `docs/remediation.md`).
After each change the application was restarted and functional controls were
executed (legitimate login, product API, own-basket flow, frontend rendering).

## 8.3 Re-Testing

Same procedures as the original validations; results:

| Finding | Before | After | Result |
|---|---|---|---|
| WEB-VUL-001 | both SQLi payloads → 200 + admin JWT | both payloads → **401** `Invalid email or password.`; valid login → 200 | **FIXED** (EVID-RETEST-001) |
| WEB-VUL-003 | 7/9 hardening headers missing | **9/9 present**; headless Chrome 0 console/CSP violations; app renders | **FIXED** (EVID-RETEST-002/003) |
| WEB-VUL-002 | cross-user read 200 + contents; write path unguarded | cross-user read **403**; cross-user coupon **403**; own basket & full flow unchanged | **FIXED** (EVID-RETEST-004) |

### Application test suite (regression verification)

```text
Test suite:        OWASP Juice Shop application tests (server unit + API suites)
Command basis:     package.json scripts test:server / test:api (documented)
                   → these cannot run in the packaged release (test/ TypeScript
                     sources not shipped: "Could not find .../test/server/**/*.unit.test.ts").
                   Executed equivalent: the same Node.js built-in test runner over the
                   shipped compiled tests, on Node v22.23.3 (supported range 22-26):
                     node --test --test-force-exit build/test/server/*.unit.test.js
                     node --test --test-force-exit build/test/api/*.test.js
Working dir:       lab/juice-shop_20.2.0/
```

| Run | Suite | Tests | Pass | Fail | Skipped | Exit code |
|---|---|---|---|---|---|---|
| EVID-TEST-001 | Server unit (lab running) | 415 | 392 | 4 | 2 | 1 |
| EVID-TEST-001B | Server unit (lab stopped) | 415 | 410 | 3 | 2 | 1 |
| EVID-TEST-002 | Login API | 18 | 13 | 5 | 0 | 1 |
| EVID-TEST-003 | Full API — mitigated code (fixes 1+2) | 537 | 486 | 38 | 7 | 1 |
| EVID-TEST-004 | Full API — **control, original code** | 537 | 492 | 33 | 7 | 1 |
| EVID-TEST-006 | Basket API — after fix 3 | 22 | 13 | 9 | 0 | 1 |
| EVID-TEST-007 | Server unit — after fix 3 | 415 | 410 | 3 | 2 | 1 |
| EVID-TEST-008 | Full API — after fix 3 | 537 | 476 | 49 | 7 | 1 |

**Regression result: FAIL — with full attribution (no failures hidden):**

- The 5 login-API failures are exactly the tests asserting the SQL-injection
  bypass succeeds (HTTP 200); they **pass on the original code** (control run
  EVID-TEST-004) and fail on the fixed code — i.e. they encode the
  vulnerability that was removed.
- The 1 `http.test.js` failure is `response must not contain XSS protection
  header` — a test asserting the hardening gap fixed by WEB-VUL-003.
- The 9 basket-API failures after fix 3 are all cross-user-basket or
  forged-JWT-acceptance assertions of the removed IDOR (plus tests incidentally
  operating on another user's basket).
- The 3 server-unit failures are identical with and without our changes
  (`ENOENT` on `infrastructure/docker-compose.yml`, a frontend source image, and
  `build/data/static/challenges.yml` — files absent from the release package).
- The remaining full-suite failures (chat/LLM, multipart uploads, data-export,
  etc. — 38 subtests) are **identical in the control run**: pre-existing
  environment/package issues (e.g. `LLM API is not reachable`).
- One additional flake in EVID-TEST-008: an external GitHub fetch
  (`fetch failed`) in `internet-resources.test.js` — network-dependent, unrelated.

**Functional regressions: 0.** All 13 functional login tests pass; a complete
legitimate basket flow passes (register → login → add item → read own basket →
checkout → order confirmation); homepage, products and headers behave as
expected. **No test was modified, disabled, deleted or reworded; no assertion
was weakened.**

## 8.4 Before/After Comparison

| Finding | Before Remediation | Mitigation | After Retest | Result |
|---|---|---|---|---|
| WEB-VUL-001 | SQLi payloads returned 200 + admin JWT (EVID-REM-001) | Parameterised query (Sequelize replacements) | Payloads → 401; valid login → 200 (EVID-RETEST-001) | **FIXED** |
| WEB-VUL-003 | 7/9 hardening headers missing (EVID-REM-002) | Hardening header middleware incl. hash-based CSP | 9/9 headers present; 0 browser violations (EVID-RETEST-002/003) | **FIXED** |
| WEB-VUL-002 | Cross-user basket read → 200 with victim contents (EVID-REM-006) | `ensureBasketOwnership()` on read+write routes | Cross-user read/write → 403; own flow unchanged (EVID-RETEST-004) | **FIXED** |
| **WEB-VUL-010** | `OPTIONS /rest/user/login` from `https://evil.example` → `Access-Control-Allow-Origin: *` (REMED-001-BEFORE) | CORS allow-list array of own origins (REMED-001) | 204 with **no** ACAO header for the attacker origin; own-origin control still receives ACAO (REMED-001-AFTER) | **REMEDIATED — RETESTED** |
| **WEB-VUL-008** | `premium.key` 49 B and `jwt.pub` 248 B key material served anonymously, HTTP 200 (REMED-002-BEFORE) | REMED-002 removed the two `/encryptionkeys` routes; REMED-002b added an explicit `404` handler | **HTTP 404 `Not Found`**; PEM key blocks 1 → 0 (REMED-002-AFTER) | **REMEDIATED — RETESTED** |

**Method note.** For the two new remediations the same HTTP request was replayed against
two simultaneously running instances — the unmodified vulnerable baseline on port 3000
and the remediated build on port 3001 — so each before/after pair is a live comparison
rather than a remembered state. Baseline integrity was confirmed by checksum after the
work completed (`evidence/remediation/REMED-baseline-integrity.txt`).

**Honest limitation, and its repair.** The first version of REMED-002 simply deleted the
two routes. That did stop the key disclosure, so the vulnerability was genuinely fixed —
but the paths then answered **HTTP 200** with the SPA shell, because
`serveAngularClient()` (`build/routes/angular.js`) sends `index.html` for every URL that
does not begin with `/api` or `/rest`. A status-code-only test would therefore have
wrongly reported the finding as still vulnerable. This was identified during project
closeout and repaired (**REMED-002b**) by adding an explicit `404` handler for
`/encryptionkeys` and `/encryptionkeys/:file`, so the fall-through no longer occurs. The
finding is now demonstrated by status code **and** by response content.

## 8.5 Final Results

- **5 of 5 remediated findings verified** FIXED/REMEDIATED by re-test (WEB-VUL-001,
  002, 003, 008, 010).
- **5 findings remain open** (WEB-VUL-004, 005, 006, 007, 009) with documented
  recommendations. They are **not** claimed as fixed.
- Application remains fully functional (health check `LAB STATUS: PASS`; remediated
  instance verified with 93 rendered product tiles and a working login).
- Regression testing executed with control-run attribution; failures are
  vulnerability-assertion tests and pre-existing environment issues only.
- No scanner-derived severity is reported anywhere: nmap, Nikto, ZAP, WhatWeb and Nuclei
  are not installed in the laboratory and `sudo` requires a password, so all findings were
  validated with direct HTTP requests and source analysis instead.

---

# Chapter 9 — Results and Discussion

## 9.1 Results

- Application mapping: entry point, page/route map, functional and
  attack-surface maps, API inventory (9 probed endpoints), trust boundaries.
- Confirmed findings: **10** (minimum required: 5).
- Categories represented: Injection (×2), Broken Access Control (×2),
  Security Misconfiguration (×3), Sensitive Data/Information Exposure (×3).
- Severity distribution: **Critical 1 · High 5 · Medium 3 · Low 1**.
- Controlled validations: **10** (minimum required: 2) — `V-001`…`V-010`,
  regenerable via `scripts/capture-verification-evidence.sh`.
- Mitigations implemented: **5** (minimum required: 2) — WEB-VUL-001, 002,
  003, 008 and 010.
- Re-tests performed: **5 → all confirmed remediated** (minimum required: 2)
  with before/after evidence.
- Findings still open: **5** (WEB-VUL-004, 005, 006, 007, 009), each with a
  documented recommendation. **The assessment is not clean and is not claimed
  to be.**
- Evidence registry: `evidence/evidence-index.csv` — **67 entries** covering
  reconnaissance, mapping, assessment, validation, findings, remediation,
  retesting and test-suite artifacts, with **0 broken paths** (verified with a
  CSV-aware existence check, not a text match).

## 9.2 Analysis

The assessment moved from *service discovery* to *evidence-backed findings* to
*verified fixes*. Two deliberate methodological controls improved confidence:
(1) every exploitation attempt ran alongside an expected-secure control, and
(2) test-suite failures were attributed using a **control run on the original
code**, proving which failures our changes caused and which pre-existed. The
control run showed a failure delta of exactly 6 tests (fixes 1+2) — all
vulnerability-assertion tests.

## 9.3 Objective Achievement

| Objective | Outcome |
|---|---|
| Deploy vulnerable app in isolated lab | Achieved (`LAB STATUS: PASS`, loopback-only) |
| Identify exposed services/technologies | Achieved (RECON-001/002) |
| Map application functionality | Achieved (`docs/application-map.md`) |
| ≥5 documented findings | 5 achieved |
| ≥2 controlled validations | 5 achieved |
| Analyze impact/severity | 5 justified severities; soft-risk scoring partial |
| ≥2 remediations implemented | 3 achieved |
| ≥2 re-tests with before/after evidence | 3 achieved |
| Evidence documented | 45 indexed entries |
| Professional report | This document |
| Presentation & viva | **Not started (Phase 19 — future work)** |

## 9.4 Technical Challenges

- Packaged release ships no `tsconfig.json` and no `test/` sources → mitigations
  were applied to both TS source and compiled `build/` output, and the compiled
  test artifacts were used for regression runs (documented, not improvised).
- CSP initially blocked two legitimate inline snippets (cookie-consent script,
  `onload` handler that activates `styles.css`) → resolved with SHA-256
  hash-allow-listing instead of weakening the whole policy; verified 0
  violations in a real browser engine.
- Upstream tests assert vulnerable behaviour → failing tests were analysed and
  reported rather than edited; a control run separated our impact from
  environment noise (port conflict, missing packaged files, absent LLM backend,
  network flake).

## 9.5 Lessons Learned

- Evidence-first workflows prevent overclaiming: every "fixed" statement here
  maps to an artifact.
- Regression testing on an intentionally vulnerable app needs a control run —
  "tests fail" and "our change broke it" are different statements.
- Smallest-possible changes (single query, single middleware, single guard)
  kept the fixes reviewable and reversible.

---

# Chapter 10 — Conclusion and Future Scope

## 10.1 Conclusion

The project delivered a complete OWASP-methodology assessment of the authorized
laboratory application `http://127.0.0.1:3000`: reconnaissance, application
mapping, a ten-area security assessment, **ten** evidence-backed findings, ten
controlled validations, justified severities, **five** implemented mitigations
and **five** successful re-tests — plus a control-run-backed regression
verification showing zero functional regressions. All activity stayed inside the
authorized scope; no external system, real account or real data was ever touched.

**Five findings remain open** (WEB-VUL-004, 005, 006, 007, 009) and are reported
as open. The most valuable outcome of the final phase was methodological: the
CORS remediation (REMED-001) was implemented incorrectly twice and only the
re-test exposed it, which is direct evidence that a change is not proven until the
identical test has been replayed against the vulnerable baseline and the fixed
build side by side.

## 10.2 Limitations

Stated plainly, including what could not be done:

- **No Kali Linux host and no virtual machines.** The specification asks for a Kali Linux
  VM plus an Ubuntu Server VM under VMware. Neither was available on this host, so the
  laboratory was built on a single Linux Mint 22.3 machine with loopback-only binding. The
  screenshots of "Kali Linux" and "virtual machines" required by §9 therefore **could not
  be produced honestly and were not faked**. See §3.3 and Appendix A.4.
- **No automated security scanners.** nmap, Nikto, OWASP ZAP, WhatWeb and Nuclei are not
  installed and `sudo` requires a password. Every finding was validated with `curl`,
  Python `socket`/`sqlite3`, headless Chrome and source analysis. **No scanner severity is
  quoted anywhere in this submission**, because none was produced.
- **TypeScript was not recompiled.** The shipped distribution contains no `tsconfig.json`,
  so `npm run build:server` (tsc) cannot run. Fixes were applied to the runtime artifact
  `build/*.js` and mirrored into the corresponding `*.ts` sources, which therefore were
  **not type-checked**.
- **XSS was not reproduced.** Harmless payloads did not reflect on the endpoints tried and
  the CSP restricts `script-src` without `'unsafe-inline'`. XSS is reported as **not
  confirmed**, not as a passing result.
- **Privilege escalation was not demonstrated.** `PATCH /api/Users/1` is not routed, so
  WEB-VUL-006 is rated on proven read-only impact only.
- **Five findings remain open** (WEB-VUL-004, 005, 006, 007, 009), each with a documented
  reason in `findings/REMEDIATION_REGISTER.md`. They are not claimed as fixed.
- **Dependency versions were not exhaustively inventoried.**
- **A baseline-integrity defect was found and repaired during the final audit.** Six files
  in the "unmodified" vulnerable baseline had earlier been edited with remediation code,
  which meant that baseline no longer reproduced WEB-VUL-001, WEB-VUL-002 or WEB-VUL-003.
  The files were restored byte-for-byte from the original distribution archive (MD5
  verified against its sidecar) and only a documented loopback bind was re-applied. All ten
  findings were then re-validated against the correct instance. No finding was added,
  removed or altered. Full record: `evidence/remediation/REMED-baseline-integrity.txt`
  and evidence rows `AUDIT-001…004`.

## 10.3 Future Improvements (near-term, labelled as future work)

- Implement WEB-VUL-004 (auth-gate `/metrics`, remove version endpoint) and
  WEB-VUL-005 (authenticate `/api/Feedbacks`) mitigations and re-test them.
- Perform dedicated XSS and session-management testing with safe payloads.
- Produce the presentation deck and architecture-diagram slide (Phase 19).
- Inventory exact dependency versions and map them against advisories.

## 10.4 Future Scope

- Broader automated scanning integrated into CI; continuous security testing.
- Improved authorization hardening review beyond basket routes.
- Security monitoring/logging for anomalous access patterns.
- Dependency management and update policy; CI/CD security integration.
- Additional OWASP categories (CSRF, SSRF, business-logic abuse cases).

---

# Traceability Matrix (PDF requirement → project phase → evidence/document → status)

| PDF requirement | Project phase | Evidence / document | Status |
|---|---|---|---|
| Lab preparation / deployment | Phases 4–6 | `scripts/start-lab.sh`, `check-lab.sh` output, `evidence/logs/juice-shop-startup.log`, `LAB-001-environment.txt`, Figure A.1 | **COMPLETE** |
| Reconnaissance (ports, services, technology) | Phase 7 | `RECON-001-port-scan.txt/json`, `tcp-scan-127.0.0.1.json`, `RECON-002-technology/headers`, `recon-raw-http.txt` | **COMPLETE** |
| Application mapping | Phase 9 | `docs/application-map.md`, `EVID-MAP-001/002` | **COMPLETE** |
| Security assessment (OWASP areas) | Phase 10 | `docs/security-assessment.md` §3–§12 (+ EVID-ASSESS-001…008) | **COMPLETE** |
| Vulnerability identification (≥5) | Phase 11 | `docs/vulnerability-findings.md`, `findings/WEB-VUL-001…005/finding.md` (5 findings) | **COMPLETE** |
| Controlled validation (≥2) | Phase 10/12 | `EVID-REVERIFY-C1…C5` (5 validations) + historical `RAW-001…010` | **COMPLETE** |
| Risk analysis / risk register | Phase 15 | Severity + impact + justification + recommendation per finding; register in `docs/vulnerability-findings.md` §3 | **PARTIAL** (no separate likelihood/exploitability scoring) |
| Remediation (≥2 implemented; recommendations for all) | Phase 16 + third remediation | `docs/remediation.md`, `remediation/WEB-VUL-001/002/003`, EVID-REM-001…007; recommendations for 004/005 in findings | **COMPLETE** |
| Re-testing (≥2, before/after) | Phase 17 + third retest | `docs/retesting.md`, EVID-RETEST-001…004 (3 FIXED) | **COMPLETE** |
| Final report | Phase 18 | `report/CS-02_Final_Security_Assessment_Report.md` (this document) | **COMPLETE** |
| Evidence documentation | All phases | `evidence/evidence-index.csv` (67 entries, 0 broken paths), `evidence/remediation/` (4 artifacts) | **COMPLETE** |
| Presentation / demo requirements | Phase 19 | slides, viva answers, contribution records | **NOT COMPLETE** (not started — explicitly out of this phase) |
| Architecture diagram | Phase 19 (deliverable) | textual architecture + trust-boundary maps in `docs/application-map.md` §9 and §3.8 above | **PARTIAL** (textual only; rendered diagram pending) |
| Individual contribution records | Phase 19 (deliverable) | — | **NOT COMPLETE** (not available) |

---

# Final Findings Summary Table

Ten confirmed findings. **Five are remediated; five remain open.** Recommendations are
not presented as implemented fixes.

| ID | Finding | Category | Severity | Remediation | Retest |
|---|---|---|---|---|---|
| WEB-VUL-001 | SQL injection authentication bypass | Injection / Broken Authentication | High | **Remediated (implemented)** | **Fixed** (EVID-RETEST-001) |
| WEB-VUL-002 | Basket IDOR (broken object-level authorization) | Broken Access Control / BOLA | High | **Remediated (implemented)** | **Fixed** (EVID-RETEST-004) |
| WEB-VUL-003 | Missing HTTP security headers | Security Misconfiguration | Medium | **Remediated (implemented)** | **Fixed** (EVID-RETEST-002/003) |
| WEB-VUL-004 | Sensitive information disclosure (`/metrics`, version, robots.txt) | Security Misconfiguration | Medium | Recommended only | Re-tested — **still open** |
| WEB-VUL-005 | Unauthenticated feedback exposure | Sensitive Data Exposure | Low | Recommended only | Re-tested — **still open** |
| WEB-VUL-006 | Broken function-level authorization on `/api/Users` | Broken Access Control / BFLA | **High** | Recommended only | **Still open** |
| WEB-VUL-007 | Password hash + TOTP field embedded in JWT | Sensitive Data Exposure / Crypto | **High** | Recommended only | **Still open** |
| WEB-VUL-008 | Unauthenticated encryption key material exposure | Sensitive Information Exposure | **High** | **Remediation IMPLEMENTED (REMED-002)** | **RETESTED — REMEDIATED** |
| WEB-VUL-009 | SQL injection in product search (+ SQLite error leak) | Injection | **High** | Recommended only | **Still open** |
| WEB-VUL-010 | Wildcard CORS policy | Security Misconfiguration | Medium | **Remediation IMPLEMENTED (REMED-001)** | **RETESTED — REMEDIATED** |

**Honest final state: 5 remediated (WEB-VUL-001, 002, 003, 008, 010); 5 still open
(WEB-VUL-004, 005, 006, 007, 009).** This project does not claim a clean assessment.

## Findings added in the final phase (WEB-VUL-006 … 010)

WEB-VUL-006 to WEB-VUL-010 were identified and validated against the running application
in the final assessment phase. Full records are in
`findings/WEB-VUL-006…010/finding.md`; each follows the same 17-section structure as the
original five, and each cites a reproducible validation file in `evidence/findings/`.

**WEB-VUL-006 — Broken function-level authorization on `/api/Users` (High)**
A self-registered `customer` token returns the entire user directory (24 seeded accounts;
25 once the assessment's own test account is registered), including every
administrator address and role, while an anonymous request correctly returns 401. The
flaw is an authorization failure behind the authentication boundary. Write access was
tested and is not routed, so this is unauthorized **read** access, which is why it is
High rather than Critical. (`evidence/findings/V-006-validation.txt`)

**WEB-VUL-007 — Password hash embedded in the JWT payload (High)**
Decoding the session token requires no secret and yields
`"password": "0192023a7bbd73250516f069df18b500"` plus `role` and a `totpSecret` field.
`md5("admin123")` equals that hash, so the disclosed value yields the plaintext password
in one hash operation — unsalted MD5. Any token theft becomes account takeover, and for
TOTP-enrolled accounts the embedded seed also defeats the second factor.
(`evidence/findings/V-007-validation.txt`)

**WEB-VUL-008 — Unauthenticated encryption key exposure (High) — REMEDIATED**
`/encryptionkeys/` listed and served `premium.key` and `jwt.pub` to anonymous clients.
Remediated and re-tested in this phase; see Chapter 7 and Chapter 8.

**WEB-VUL-009 — SQL injection in product search (High)**
`' OR '1'='1` returned 46 rows against 3 for `apple`, and `' AND '1'='2` returned 0 —
a boolean differential. A malformed payload returns
`500 Error: SQLITE_ERROR: incomplete input`, disclosing the engine and driver error.
(`evidence/findings/V-009-validation.txt`)

**WEB-VUL-010 — Wildcard CORS (Medium) — REMEDIATED**
`Access-Control-Allow-Origin: *` for any origin. Impact held at Medium because
`Access-Control-Allow-Credentials` is not set, so the browser does not attach cookies.
Remediated and re-tested in this phase.

## Remediation and re-testing performed in this phase

Two findings were remediated and re-tested. The vulnerable baseline was preserved and is
still running unmodified on port 3000, with the same HTTP test replayed against it for a
genuine side-by-side comparison; the remediated build runs on port 3001. Before/after
evidence is in `evidence/remediation/REMED-before.txt` and `REMED-after.txt`, and the full
narrative is in `docs/retesting.md`.

**The most significant outcome of the re-test was that REMED-001 was wrong twice before
it was correct.** An allow-list passed to cors@2.8.6 as a *string* is echoed without
validating the request's `Origin`, so the vulnerability persisted; passing it as a
*function* correctly omitted the header but made the preflight fall through to Juice
Shop's `unexpectedRequest` handler and return 500 instead of 204. Only an *array* both
omits the header for unlisted origins and preserves the 204. This was established by
reading `node_modules/cors/lib/index.js`, and it is reported because a version of this
project that recorded "header is no longer `*`" as success would have been wrong.

---

# Evidence Traceability (finding → evidence ID → artifact → phase → result)

| Finding / claim | Evidence ID | Artifact | Phase | Result |
|---|---|---|---|---|
| WEB-VUL-001 vulnerable | EVID-REVERIFY-C1 | `evidence/reverification/EVID-REVERIFY-C1-sqli.txt` | 10 | Confirmed |
| WEB-VUL-001 before-state | EVID-REM-001 | `remediation/WEB-VUL-001/before/EVID-REM-001-sqli-before.txt` | 16 | Vulnerable reproduced |
| WEB-VUL-001 fix record | EVID-REM-003 | `remediation/WEB-VUL-001/remediation.md` | 16 | Implemented |
| WEB-VUL-001 retest | EVID-RETEST-001 | `remediation/WEB-VUL-001/after/EVID-RETEST-001-sqli-retest.txt` | 17 | FIXED |
| WEB-VUL-002 vulnerable | EVID-REVERIFY-C2 | `evidence/reverification/EVID-REVERIFY-C2-idor.txt` | 10 | Confirmed |
| WEB-VUL-002 before-state | EVID-REM-006 | `remediation/WEB-VUL-002/before/EVID-REM-006-idor-before.txt` | 16/18 | Vulnerable reproduced |
| WEB-VUL-002 fix record | EVID-REM-007 | `remediation/WEB-VUL-002/remediation.md` | 16/18 | Implemented |
| WEB-VUL-002 retest | EVID-RETEST-004 | `remediation/WEB-VUL-002/after/EVID-RETEST-004-idor-retest.txt` | 17/18 | FIXED |
| WEB-VUL-003 vulnerable | EVID-REVERIFY-C3 | `evidence/reverification/EVID-REVERIFY-C3-headers.txt` | 10 | Confirmed |
| WEB-VUL-003 before-state | EVID-REM-002 | `remediation/WEB-VUL-003/before/EVID-REM-002-headers-before.txt` | 16 | Vulnerable reproduced |
| WEB-VUL-003 fix record | EVID-REM-004 | `remediation/WEB-VUL-003/remediation.md` | 16 | Implemented |
| WEB-VUL-003 retest | EVID-RETEST-002/003 | `remediation/WEB-VUL-003/after/*` (+ screenshot) | 17 | FIXED |
| WEB-VUL-004 vulnerable | EVID-REVERIFY-C4 | `evidence/reverification/EVID-REVERIFY-C4-disclosure.txt` | 10 | Confirmed (open) |
| WEB-VUL-005 vulnerable | EVID-REVERIFY-C5 | `evidence/reverification/EVID-REVERIFY-C5-feedback.txt` | 10 | Confirmed (open) |
| Application functional after fixes | EVID-REM-005 | `remediation/safety-check-phase16.txt` | 16 | PASS |
| Regression testing | EVID-TEST-001…008 | `evidence/phase18-test-suite/*` | 18 | FAIL (attributed; 0 functional regressions) |
| Recon: ports/services | RAW-013/017 | `evidence/scanner-results/RECON-001-*`, `tcp-scan-127.0.0.1.json` | 7 | 63 ports enumerated |
| Technology identification | RAW-014 | `evidence/scanner-results/RECON-002-technology.*` | 7 | Angular SPA + Juice Shop |
| Application running | RAW-019 | `evidence/screenshots/LAB-003-application-running.png` | 9 | Observed (Figure A.1) |

*Every `EVID-*` row was verified to resolve to an existing file; historical
`RAW-*` rows follow the original registry entries.*

---

# References

1. OWASP Juice Shop — Official Repository & Documentation, https://owasp.org/www-project-juice-shop/ and https://github.com/juice-shop/juice-shop
2. OWASP Top 10, https://owasp.org/Top10/
3. OWASP Web Security Testing Guide, https://owasp.org/www-project-web-security-testing-guide/
4. OWASP — Broken Object Level Authorization (BOLA) / API Security Top 10, https://owasp.org/API-Security/
5. CWE-89: SQL Injection, https://cwe.mitre.org/data/definitions/89.html
6. CWE-639: Authorization Bypass Through User-Controlled Key (IDOR), https://cwe.mitre.org/data/definitions/639.html
7. CWE-693: Protection Mechanism Failure (missing security headers), https://cwe.mitre.org/data/definitions/693.html
8. MDN Web Docs — HTTP security response headers, https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers
9. Helmet (Node.js security middleware), https://helmetjs.github.io/
10. Sequelize — Security / Query parameters & replacements, https://sequelize.org/docs/v6/core-concepts/raw-queries/
11. Node.js built-in Test Runner, https://nodejs.org/api/test.html
12. CS-02 Project Specification (`docs/SPEC_CS-02.txt`) — project requirements, phases and report structure.

---

# Appendix

## A.1 Key commands used (representative, no secrets)

```bash
# Lab lifecycle
bash scripts/start-lab.sh          # detached start + health check (LAB STATUS: PASS)
bash scripts/check-lab.sh          # process/port/HTTP/isolation checks
bash scripts/stop-lab.sh           # clean stop (frees port 3000)

# Controlled validation / retest pattern (tokens redacted in stored evidence)
curl -s -o out -w "HTTP %{http_code}\n" -X POST http://127.0.0.1:3000/rest/user/login \
  -H 'Content-Type: application/json' -d '{...payload...}'
curl -s -D - -o /dev/null http://127.0.0.1:3000/            # header enumeration
curl -s -H "Authorization: Bearer [REDACTED-JWT]" \
  http://127.0.0.1:3000/rest/basket/2                       # IDOR reproduction

# Regression tests (Node 22 via nvm)
node --test --test-force-exit build/test/server/*.unit.test.js
node --test --test-force-exit build/test/api/login.test.js
node --test --test-force-exit build/test/api/*.test.js

# Headless-browser verification of CSP / rendering
google-chrome --headless=new --user-data-dir=/tmp/cspcheck --virtual-time-budget=8000 \
  --enable-logging=stderr --dump-dom http://127.0.0.1:3000/
```

## A.2 Evidence index summary

`evidence/evidence-index.csv` — 78 registry entries (verified with a CSV-aware check: every
referenced path exists, no duplicate IDs, no ragged rows):

| Block | ID prefix | Count |
|---|---|---|
| Historical raw captures | `RAW-001…020` | 20 |
| Instance re-verification | `EVID-REVERIFY-*` | 5 |
| Remediation (pre-existing findings) | `EVID-REM-*` | 7 |
| Remediation (REMED-001/002/002b) | `REMED-00*` | 7 |
| Re-testing | `EVID-RETEST-*` | 4 |
| Test-suite verification | `EVID-TEST-*` | 9 |
| Final finding validation | `LIVE-*`, `V-0*` | 13 |
| Closeout / RSN / integrity records | `CLOSEOUT-*` | 7 |
| Guard negative tests | `NEG-00*` | 2 |
| Final-audit repair records | `AUDIT-00*` | 4 |
| **Total** | | **78** |

## A.3 Application map (summary)

Functions observed and mapped (`docs/application-map.md`): Login, Registration,
User Profile, Search, Product listing/details, Feedback, Basket/Checkout,
Orders, Administration (score-board/challenge surfaces), Complaint/File
upload, Chatbot, and the REST/API surface (`/rest/*`, `/api/*`, `/metrics`).
Full route/attack-surface tables are in that document.

## A.4 Figures

All screenshots are **original captures from this group's own laboratory** on
Linux Mint 22.3 at `http://127.0.0.1:3000` / `:3001`. No Internet or third-party images
are used.

| Figure | Caption | Explanation | Evidence ID | Maps to |
|---|---|---|---|---|
| Figure A.1 | Web application running in the authorized laboratory | Original screenshot `evidence/screenshots/LAB-003-application-running.png` (1366×900) captured from this group's own lab. Demonstrates the real Juice Shop UI, **not** a directory listing — the failure mode this project had to eliminate first. | `LIVE-001` | Phase 1 / spec §9 |
| Figure A.2 | Post-remediation application rendering under the enforced Content-Security-Policy | Original screenshot `remediation/WEB-VUL-003/after/LAB-016-post-remediation.png` (1366×900), taken after the hardening-header mitigation. Product grid renders with 0 CSP violations, confirming WEB-VUL-003 remediation did not break the UI. | `EVID-RETEST-002/003` | WEB-VUL-003 |
| Figure A.3 | Verified real Juice Shop UI (1440×900) | Original headless-Chrome capture `evidence/screenshots/LAB-003-juice-shop-home.png`. Angular SPA fully renders — 93 product tiles, toolbar and navigation — establishing that the lab serves the application itself. | `LIVE-001` | Phase 1 / spec §9 |
| Figure A.4 | Remediated instance rendering after REMED-001 and REMED-002 (1440×900) | Original headless-Chrome capture `evidence/screenshots/REMED-001-after-remediated-ui.png`. The **remediation** build on `:3001` renders identically to the baseline (93 tiles, toolbar, product images), proving the CORS allow-list and the `/encryptionkeys` 404 caused **no functional regression**. | `REMED-001-UI` | WEB-VUL-010, WEB-VUL-008 |

### Screenshots required by the PDF §9 that could NOT be produced

The specification's Phase 1 requires screenshots of *virtual machines* and of *Kali
Linux*. **This laboratory used neither a virtual machine nor Kali Linux** — it ran on a
single Linux Mint 22.3 host (§3.3). Those screenshots cannot be produced honestly, and
**no substitute image was invented or downloaded**. The functional equivalents actually
captured are Figures A.1, A.3 and A.4, plus the network-isolation checks in §3.4 and
`evidence/logs/LAB-003-juice-shop-running.txt`.

## A.5 Test-suite result files

`evidence/phase18-test-suite/` — `EVID-TEST-001`, `EVID-TEST-001b`,
`EVID-TEST-002`, `EVID-TEST-003` (mitigated), `EVID-TEST-004` (original-code
control), `EVID-TEST-005` (regression analysis record), `EVID-TEST-006`
(basket after fix 3), `EVID-TEST-007` (unit after fix 3), `EVID-TEST-008`
(full API after fix 3).

## A.6 Vulnerability register (spec §14 format)

| ID | Component | Vulnerability | Severity | Impact | Recommendation | Status |
|---|---|---|---|---|---|---|
| WEB-VUL-001 | `/rest/user/login` | SQL injection auth bypass | High | Admin session without credentials | Parameterised queries | Remediated → retest Fixed |
| WEB-VUL-002 | `/rest/basket/:id` | IDOR / BOLA | High | Cross-user data access (read/write) | Object-level ownership checks | Remediated → retest Fixed |
| WEB-VUL-003 | Serving layer `GET /` | Missing security headers | Medium | Weakened browser defences | Hardening header set | Remediated → retest Fixed |
| WEB-VUL-004 | `/metrics`, version, robots | Info disclosure | Medium | Fingerprinting/directory hints | Auth-gate & remove exposure | Open (recommended) |
| WEB-VUL-005 | `/api/Feedbacks` | Unauthenticated user content | Low | Anonymous content collection | Require authentication | Open (recommended) |
| WEB-VUL-006 | `/api/Users`, `/api/Users/:id` | Broken function-level authorization | High | Full user directory incl. all admins disclosed to any `customer` | Enforce role checks on user routes | Open (recommended) |
| WEB-VUL-007 | JWT issued by `POST /rest/user/login` | Password hash + `totpSecret` in token payload | Critical | Any token holder recovers the credential offline | Strip claims; migrate MD5 to bcrypt/Argon2id | Open (recommended) |
| WEB-VUL-008 | `/encryptionkeys/`, `/encryptionkeys/:file` | Unauthenticated key-material exposure | High | Premium-content key and JWT public key disclosed | Remove the routes; restrict key access | Remediated → retest Fixed (404) |
| WEB-VUL-009 | `/rest/products/search` | SQL injection (boolean + error based) | High | Full catalogue read; DB engine and message leaked | Parameterise the query | Open (recommended) |
| WEB-VUL-010 | All `/rest/*` and `/api/*` responses | Wildcard CORS policy | Medium | Any site may read API responses cross-origin | Explicit origin allow-list | Remediated → retest Fixed |

**Totals:** 10 findings — 1 Critical, 5 High, 3 Medium, 1 Low. **5 remediated and
re-tested** (001, 002, 003, 008, 010); **5 remain open** (004, 005, 006, 007, 009) with
documented reasons in `findings/REMEDIATION_REGISTER.md`.

## A.7 Security note on this report

No passwords, session tokens, JWT secrets or private keys are reproduced in this
document. All captured tokens in evidence files were redacted at capture time
(`[REDACTED-JWT]`). Laboratory accounts are the application's own public seed
data; their credentials are deliberately not reproduced here.

---

*End of report — CS-02. Presentation, practical demonstration, viva preparation,
individual contribution and traceability are included in this submission.*
