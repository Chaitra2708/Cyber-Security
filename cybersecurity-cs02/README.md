# Web Application Security Assessment Using OWASP Methodology

## CS-02

An authorized web application security assessment conducted against an
intentionally vulnerable OWASP Juice Shop instance in an isolated laboratory
environment.

---

## Access

### LOCAL LAB (private, never published)

| Instance | URL |
|---|---|
| Vulnerable baseline | http://127.0.0.1:3000/ |
| Remediated instance | http://127.0.0.1:3001/ |

Both bind loopback only and are unreachable from the internet.

### PUBLIC SECURE DEMO (any device, HTTPS)

**https://chaitra2708.github.io/Cyber-Security/**

A read-only documentation build of this assessment — findings, risk register,
remediation, re-testing, architecture and report summary.

Health check: https://chaitra2708.github.io/Cyber-Security/health.html

> **The vulnerable assessment instance is not publicly exposed.** The public site
> contains no application runtime, no database and no credentials. The remediated
> instance was explicitly *not* published because it still carries five open
> findings (including live SQL injection and credential-leaking JWTs) — see
> `docs/cloud-deployment.md`.

## Project Overview

This project deploys OWASP Juice Shop v20.2.0 locally, assesses it with a
structured OWASP-based methodology, documents every weakness with captured
evidence, implements mitigations where technically feasible, and re-tests each
mitigation with before/after evidence — culminating in a full technical
assessment report (Phase 18).

- **10 confirmed findings** (1 Critical, 5 High, 3 Medium, 1 Low)
- **10 controlled validations** (minimum required: 2)
- **5 mitigations implemented and re-tested → all 5 REMEDIATED** (minimum required: 2)
- **5 findings remain OPEN** with documented recommendations — deliberately not
  over-remediated
- **78-entry evidence registry**, 0 broken paths, 0 duplicate IDs; application
  regression testing executed against a preserved vulnerable baseline

## Objectives

1. Deploy an intentionally vulnerable web application in an isolated lab.
2. Identify exposed services and technologies.
3. Map application functionality and attack surface.
4. Identify and document security weaknesses.
5. Perform controlled validation in the authorized lab.
6. Analyze security impact.
7. Recommend remediation; implement where technically feasible.
8. Re-test remediated findings with before/after evidence.
9. Document technical evidence and produce a professional report.

## Scope

Target:

```text
http://127.0.0.1:3000
```

The assessment was restricted to the authorized local laboratory instance
(loopback only). **Out of scope and never tested:** `127.0.0.1:5500`, public
websites, third-party applications, college/company/government systems,
unrelated local services, denial-of-service, destructive testing, malware,
real accounts and real user data.

## Methodology

1. Laboratory Preparation
2. Web Reconnaissance
3. Application Mapping
4. Security Assessment
5. Vulnerability Identification
6. Controlled Validation
7. Risk Analysis
8. Remediation
9. Re-Testing
10. Final Reporting

Governing rule: *current evidence must support a conclusion* — every result in
this repository maps to a captured artifact in `evidence/evidence-index.csv`.

## Technology and Tools

Only tools actually used:

| Tool | Purpose |
|---|---|
| `curl` | HTTP requests, header enumeration, controlled validations, re-tests |
| Headless Google Chrome | Rendering checks, CSP verification, screenshots |
| Python 3 (project script) | TCP connect scan of `127.0.0.1` |
| `ss` / coreutils | Listener and process verification |
| Node.js built-in test runner (`node --test`) | Application regression testing |
| Project shell scripts (`start-lab.sh`, `stop-lab.sh`, `check-lab.sh`) | Reproducible lab lifecycle and health checks |

Application stack: OWASP Juice Shop v20.2.0 — Node.js (v22, Express) backend,
SQLite database, Angular single-page frontend. Assessed host: Linux Mint 22.3
(single host, loopback isolation; no VM hypervisor in use — recorded honestly
in the report).

## Architecture

```
 [Assessment host]
   └── OWASP Juice Shop v20.2.0 (node build/app)
         ├── Express backend  :3000  ── bound to 127.0.0.1 ONLY
         │     ├── /rest/*  (login, basket, orders, admin)
         │     ├── /api/*   (Products, Feedbacks, Users, ...)
         │     └── /metrics (Prometheus telemetry)
         ├── Angular SPA (main.js / styles.css / polyfills.js)
         └── SQLite database
   Isolation: the LAN interface cannot reach the application (verified)
```

Full maps, attack surface and trust boundaries: `docs/application-map.md`.

## Security Findings

Ten confirmed findings were documented — **5 remediated and re-tested, 5 still open**:

| ID | Finding | Severity | Remediation | Retest |
|---|---|---|---|---|
| WEB-VUL-001 | SQL injection authentication bypass (`/rest/user/login`) | High | Remediated (implemented) | Fixed |
| WEB-VUL-002 | Basket IDOR / broken object-level authorization (`/rest/basket/:id`) | High | Remediated (implemented) | Fixed |
| WEB-VUL-003 | Missing HTTP security headers (`GET /`) | Medium | Remediated (implemented) | Fixed |
| WEB-VUL-004 | Sensitive information disclosure (`/metrics`, version endpoint, `robots.txt`) | Medium | Not remediated (recommended) | Re-tested — still open |
| WEB-VUL-005 | Unauthenticated feedback exposure (`/api/Feedbacks`) | Low | Not remediated (recommended) | Re-tested — still open |
| WEB-VUL-006 | Broken function-level authorization (`/api/Users`) | High | Not remediated (recommended) | Still open |
| WEB-VUL-007 | Password hash embedded in JWT (`POST /rest/user/login`) | Critical | Not remediated (recommended) | Still open |
| WEB-VUL-008 | Unauthenticated encryption key exposure (`/encryptionkeys`) | High | **Remediated (REMED-002/002b)** | **RETESTED — REMEDIATED** |
| WEB-VUL-009 | SQL injection in product search (`/rest/products/search`) | High | Not remediated (recommended) | Still open |
| WEB-VUL-010 | Wildcard CORS policy | Medium | **Remediated (REMED-001)** | **RETESTED — REMEDIATED** |

Full records: `findings/WEB-VUL-001` … `findings/WEB-VUL-010` (each `finding.md`) and
`docs/vulnerability-findings.md`.

## Remediation

**Five** findings were remediated where technically feasible:

1. **WEB-VUL-001** — parameterised login query (Sequelize named replacements)
   replacing string-concatenated SQL.
2. **WEB-VUL-003** — full hardening header set (HSTS, CSP with hash-allow-listed
   inline snippets, Referrer-Policy, Permissions-Policy, COOP, CORP,
   X-XSS-Protection) on every response.
3. **WEB-VUL-002** — object-level authorization guard
   (`ensureBasketOwnership()`) on all three basket-object routes
   (read + checkout + coupon), fail-closed with HTTP 403.

Records: `docs/remediation.md`, `remediation/<finding>/` (before-state,
implementation record, after-state). WEB-VUL-004/005 carry documented
recommendations only — never claimed as fixed.

## Retesting

Each remediated finding was re-tested with the *same* procedure that originally
demonstrated the vulnerability — no new exploits — against the running
mitigated instance:

| Finding | Before | After | Result |
|---|---|---|---|
| WEB-VUL-001 | SQLi payloads → HTTP 200 + admin-role JWT | payloads → HTTP 401; valid login still 200 | FIXED |
| WEB-VUL-003 | 7/9 hardening headers missing | 9/9 present; 0 browser CSP violations | FIXED |
| WEB-VUL-002 | cross-user basket read → 200 with victim contents | cross-user read/write → 403; own basket unchanged | FIXED |

Records: `docs/retesting.md`, `remediation/<finding>/after/`.

## Test Suite

The OWASP Juice Shop application test suites (server unit + API) were run from
the project's own test configuration, on Node v22.23.3, using the shipped
compiled tests (the packaged release does not include the TypeScript `test/`
sources the npm scripts expect).

| Run | Tests | Pass | Fail | Notes |
|---|---|---|---|---|
| Server unit (final) | 415 | 410 | 3 | 3 = files absent from the release package |
| Login API | 18 | 13 | 5 | all 5 assert the *fixed* SQLi bypass |
| Basket API (after fix) | 22 | 13 | 9 | all cross-user/forged-JWT assertions of the *fixed* IDOR |
| Full API suite (mitigated code) | 537 | 476 | 49 | — |
| Full API suite (original code, control) | 537 | 492 | 33 | proves the delta = vulnerability-assertion tests |

**Regression result: FAIL (recorded honestly)** — every failure is either a
test asserting the vulnerability that was intentionally fixed, or a
pre-existing environment/package issue proven identical by the control run.
**Functional regressions: 0.** No test was modified, disabled or weakened.
Raw outputs: `evidence/phase18-test-suite/`.

## Documentation

- [Application Map](docs/application-map.md)
- [Security Assessment](docs/security-assessment.md)
- [Vulnerability Findings](docs/vulnerability-findings.md)
- [Remediation](docs/remediation.md)
- [Retesting](docs/retesting.md)
- [Traceability Matrix](docs/traceability-matrix.md)
- [Publishing Inventory](docs/publishing-inventory.md)
- [Final Security Assessment Report](report/CS-02_Final_Security_Assessment_Report.md)

## Evidence

Evidence is provided only where it is safe and appropriate for public release.
`evidence/evidence-index.csv` tags every entry with a **Publish Status**
(`Public Evidence` / `Sanitized Evidence` / `Restricted/Not Published`).
Session tokens were redacted at capture time (`[REDACTED-JWT]`); machine
paths, hostname and LAN IPs were sanitized in this repository (see
`docs/publishing-inventory.md` §9). Raw runtime logs, the local application
instance and unrelated scaffolding directories are not published.

## Project Status

Phase 18 — Final Security Assessment Report: **COMPLETE**

Slides and viva content were intentionally not created as part of this
project workflow.

## Important Scope Notice

This repository documents an authorized educational security assessment of an
intentionally vulnerable **local** laboratory application. The target
`http://127.0.0.1:3000` exists only on the original machine and is not a
public service. Do not use the documented techniques against systems without
explicit authorization.

## Reproduction

For an authorized reviewer with a local machine and internet access:

1. Download the official OWASP Juice Shop release **v20.2.0**
   (`juice-shop-20.2.0_node22_linux_x64.tgz` from
   https://github.com/juice-shop/juice-shop/releases) and verify it against a
   checksum you record yourself.
2. Extract it and start it locally: `node build/app` (Node.js 22+).
   Confirm `http://127.0.0.1:3000` answers.
3. Optionally copy `scripts/` into the project root of that instance —
   `scripts/start-lab.sh`, `scripts/stop-lab.sh`, `scripts/check-lab.sh`
   replicate the lab lifecycle and health checks used here.
4. Re-run the reproductions described in each finding
   (`findings/WEB-VUL-00N/finding.md` §Reproduction) against **your own local
   instance only**.
5. Re-run the re-tests described in `docs/retesting.md` to reproduce the
   before/after results against a locally modified instance — the exact code
   changes are documented in `remediation/*/remediation.md`.
6. Regression tests: `node --test build/test/server/*.unit.test.js` and
   `node --test build/test/api/*.test.js` from the instance root (Node 22+).

No credentials, tokens or secrets from the original assessment are required or
provided.

## Author / Team

Group 02 — CS-02 student group project. Individual names and institution
details are intentionally not included in this repository.
