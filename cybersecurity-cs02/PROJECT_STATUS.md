> ## ⚠️ SUPERSEDED HISTORICAL LOG — NOT THE CURRENT STATE
>
> This file is the **working log of an earlier project phase** (findings WEB-VUL-001…005,
> 3 mitigations). It is retained unchanged as part of the project's history.
>
> **It must not be used as the current status.** It is internally inconsistent (it
> states both "2 of 5" and "3 findings" remediated) and its counts are obsolete.
>
> **Current authoritative status (closeout, 2026-10-04):**
>
> | Item | Value |
> |---|---|
> | Findings | **10** (WEB-VUL-001 … WEB-VUL-010) |
> | Remediated + re-tested | **5** — 001, 002, 003, 008, 010 |
> | Open | **5** — 004, 005, 006, 007, 009 |
> | Evidence index | **74** rows, 0 broken paths, 0 duplicate IDs |
> | Baseline | **unmodified**, still serving on :3000 |
> | Remediation instance | separate copy on **:3001** |
> | Lab health | `check-lab.sh` → `LAB STATUS: PASS` (10/10) |
>
> Authoritative documents:
> `FINAL_SUBMISSION_CHECKLIST.md`, `docs/final-state-snapshot.txt`,
> `findings/REMEDIATION_REGISTER.md`, `docs/risk-analysis.md`,
> `docs/retesting.md`, `report/CS-02_Final_Security_Assessment_Report.md`.

---

# CS-02 Project Status

**Project:** Web Application Security Assessment Using OWASP Methodology
**Project Code:** CS-02
**Authorized Target:** `http://127.0.0.1:3000` (OWASP Juice Shop v20.2.0)
**Scope:** `127.0.0.1:3000` ONLY. Nothing else is in scope (5500 is not the application).

---

## Current Scope

- Authorized URL: `http://127.0.0.1:3000`
- Nothing else in scope. Port 5500 is not the application and has not been tested.

## Phase Status

| Phase | Status |
|---|---|
| Phase 1 PDF / Project Analysis | COMPLETE / Verified |
| Phase 2 Requirement Extraction | COMPLETE / Verified |
| Phase 3 Laboratory Planning | COMPLETE / Verified |
| Phase 4 Environment Preparation | COMPLETE / Verified |
| Phase 5 Application Deployment | COMPLETE / Verified |
| Phase 6 Connectivity Verification | COMPLETE / Verified |
| Phase 7 Reconnaissance | COMPLETE / Verified |
| Phase 8 Reconnaissance Evidence / Verification | COMPLETE / Verified |
| Phase 9 Application Mapping | COMPLETE / Verified |
| Phase 10 Security Assessment | COMPLETE / Verified (candidate re-verification done) |
| Phase 11 Vulnerability Identification | COMPLETE / Verified (5 findings; see Phase 11 section below) |
| Phase 12 Controlled Technical Validation | COMPLETE — activities performed within Phase 10 re-verification (5 controlled validations `EVID-REVERIFY-C1..C5`) + historical validation records (RAW-001..010) |
| Phase 13 Authentication & Authorization | COMPLETE — `docs/security-assessment.md` §3–4, §8 (with evidence) |
| Phase 14 Security Configuration | COMPLETE — `docs/security-assessment.md` §9, §11 (with evidence) |
| Phase 15 Risk Analysis | PARTIAL — severity/impact/justification/recommendation documented for all 5 findings (register = `docs/vulnerability-findings.md` §3); no separate likelihood/exploitability scoring pass |
| Phase 16 Remediation | COMPLETE / Verified (2 mitigations) |
| Phase 17 Re-Testing | COMPLETE / Verified (both retests FIXED) |
| Phase 18 Final Results / Report | COMPLETE / Verified — `report/CS-02_Final_Security_Assessment_Report.md` |
| Phase 19 Presentation / Viva | Not Started (explicitly not begun — STOP after Phase 18) |

## Evidence

- Evidence registry: 45 entries (`evidence/evidence-index.csv`); all `EVID-*` row paths verified to resolve to real files
- Evidence-bearing artifacts: 42 files under `evidence/` + 11 under `remediation/` = 53 total (historical artifacts preserved unchanged)
- Current-instance re-verification evidence: 5 (`EVID-REVERIFY-C1..C5`) — Phase 10
- Remediation evidence: 7 (`EVID-REM-001..007`) — Phases 16/18 (3 findings)
- Retest evidence: 4 (`EVID-RETEST-001..004`) — Phases 17/18 (3 findings, all FIXED)
- Test-suite evidence: 10 files (`EVID-TEST-001, 001B, 002..008`) — Phase 18 (`evidence/phase18-test-suite/`)

## Current Instance Verification

- Application reachable at `http://127.0.0.1:3000`: **YES** (HTTP 200, Juice Shop)
- Server process: `node build/app` (pid live)
- Port 3000 listening: **YES** (127.0.0.1 only)
- Port 5500: free (not a target)
- Isolation: LAN IP unreachable (loopback-isolated)

## Historical Artifact Inventory (27 raw artifacts — preserved)

- `evidence/findings/WEB-VUL-001-validation.txt` — SQLi validation (historical)
- `evidence/findings/WEB-VUL-002-validation.txt` — IDOR validation (historical)
- `evidence/findings/WEB-VUL-003-validation.txt` — security headers validation (historical)
- `evidence/findings/WEB-VUL-004-validation.txt` — information disclosure validation (historical)
- `evidence/findings/WEB-VUL-005-validation.txt` — feedback exposure validation (historical)
- `evidence/responses/WEB-VUL-001-response.txt` — token-redacted SQLi response (historical)
- `evidence/responses/WEB-VUL-002-response.txt` — 401 HTML (the `/api/Users` probe, NOT the basket IDOR evidence)
- `evidence/responses/WEB-VUL-002-victim-basket.json` — valid basket read (historical)
- `evidence/requests/WEB-VUL-001-request.txt` — SQLi request (historical)
- `evidence/requests/WEB-VUL-002-request.txt` — IDOR request (historical)
- `evidence/scanner-results/EVID-MAP-001-entrypoint.txt` — entry point (Phase 9)
- `evidence/scanner-results/EVID-MAP-002-routes.txt` — routes (Phase 9)
- `evidence/scanner-results/LAB-001-environment.txt` — lab env (Phase 7)
- `evidence/scanner-results/RECON-001-port-scan.txt/json` — port scan (Phase 7)
- `evidence/scanner-results/RECON-002-response-headers.txt` — headers (Phase 7)
- `evidence/scanner-results/RECON-002-technology.txt/json` — technology (Phase 7)
- `evidence/scanner-results/recon-raw-http.txt` — recon raw (Phase 7)
- `evidence/scanner-results/tcp-scan-127.0.0.1.json` — port scan json (Phase 7)
- `evidence/screenshots/LAB-003-application-running.png` — screenshot (Phase 9)
- `evidence/logs/juice-shop-startup.log` — startup log (Phase 5)
- `evidence/reverification/EVID-REVERIFY-C1-sqli.txt` — re-verification C1 (Phase 10)
- `evidence/reverification/EVID-REVERIFY-C2-idor.txt` — re-verification C2 (Phase 10)
- `evidence/reverification/EVID-REVERIFY-C3-headers.txt` — re-verification C3 (Phase 10)
- `evidence/reverification/EVID-REVERIFY-C4-disclosure.txt` — re-verification C4 (Phase 10)
- `evidence/reverification/EVID-REVERIFY-C5-feedback.txt` — re-verification C5 (Phase 10)

## Candidate Re-Verification (Phase 10)

| Candidate | Description | Status | Current Evidence |
|---|---|---|---|
| C1 — SQLi authentication bypass | Login bypass via `' OR 1=1--` | **CONFIRMED** | EVID-REVERIFY-C1-sqli.txt |
| C2 — Broken access control / IDOR | Cross-user basket read | **CONFIRMED** | EVID-REVERIFY-C2-idor.txt |
| C3 — Missing security headers | Hardening headers absent | **CONFIRMED** | EVID-REVERIFY-C3-headers.txt |
| C4 — Sensitive information disclosure | /metrics, version, /robots.txt exposed | **CONFIRMED** | EVID-REVERIFY-C4-disclosure.txt |
| C5 — Unauthenticated feedback exposure | User content returned unauthenticated | **CONFIRMED** | EVID-REVERIFY-C5-feedback.txt |

## Current Blockers

- docs/application-map.md: now created and verified (Phase 9 complete)
- docs/security-assessment.md: created (Phase 10 complete; re-verification done)
- evidence/evidence-index.csv: created (26 entries)
- PROJECT_STATUS.md: current
- findings/ directory: still empty — Phase 10 does not create formal findings (Phase 11 will)

## Next Action

1. Phase 11 — Vulnerability Identification: create formal findings with REAL, reproduced
   current evidence (C1–C5 are all reproduced and form the finding basis).
2. Phase 12 — Controlled Technical Validation (2 minimum).
3. Phase 13 — Authentication & Authorization assessment.
4. Phase 14 — Security configuration assessment.
5. Phase 15 — Risk analysis.
6. Phase 16 — Remediation (documented; application is intentionally vulnerable).
7. Phase 17 — Re-testing.
8. Phase 18/19 — Final report, presentation, viva.


## Phase 11 Status — Vulnerability Identification
Status: **COMPLETE**

Confirmed findings: 5
- WEB-VUL-001 — SQL injection authentication bypass (High) — EVID-REVERIFY-C1-sqli.txt
- WEB-VUL-002 — Broken access control / IDOR (High) — EVID-REVERIFY-C2-idor.txt
- WEB-VUL-003 — Missing HTTP security headers (Medium) — EVID-REVERIFY-C3-headers.txt
- WEB-VUL-004 — Sensitive information disclosure (Medium) — EVID-REVERIFY-C4-disclosure.txt
- WEB-VUL-005 — Unauthenticated feedback exposure (Low) — EVID-REVERIFY-C5-feedback.txt

Candidate-to-finding mapping (Phase 10 → Phase 11):
C1 -> WEB-VUL-001, C2 -> WEB-VUL-002, C3 -> WEB-VUL-003, C4 -> WEB-VUL-004, C5 -> WEB-VUL-005

Evidence coverage: 5/5 confirmed candidates formalised, each with current-instance
evidence (EVID-REVERIFY-C1..C5) plus historical validation records (EVID-VAL-001..005).

Excluded/non-confirmed candidates: none (all 5 Phase 10 candidates were CONFIRMED).

Limitations:
- Evidence is from the authorized isolated single-host lab (loopback); severity is
  assessed at lab level.
- Findings 1 and 2 require app-layer changes; code was not modified this phase.
- No finding was remediated or retested this phase (Phase 16/17 will cover this).

Files created/updated:
- findings/WEB-VUL-001..005/finding.md (5 finding records)
- docs/vulnerability-findings.md (master findings document, 175 lines)
- evidence/evidence-index.csv (added EVID-FIND-001..005)

Next phase: Final report (Phase 18) + presentation/viva (Phase 19).

---

## Phase 16 Status — Remediation
Status: **COMPLETE** (verified 2026-10-04)

Selection was based on technical feasibility only (root cause understood,
affected code identifiable, safe reversible local change, objectively
re-testable) — not severity; findings were not ranked.

Remediated findings:
- WEB-VUL-001 — SQL injection authentication bypass
- WEB-VUL-003 — Missing HTTP security headers

Root causes:
- WEB-VUL-001: raw SQL string built by concatenating unsanitised `req.body.email`
  in `routes/login.ts` / `build/routes/login.js`
- WEB-VUL-003: only `helmet.noSniff()` + `helmet.frameguard()` enabled in
  `server.ts` / `build/server.js`; seven hardening headers never emitted

Mitigations implemented:
- WEB-VUL-001: parameterised query via Sequelize named `replacements`
  (email/password bound as data, never parsed as SQL)
- WEB-VUL-003: middleware adding the seven missing headers, CSP allow-listing
  the app's two legitimate inline snippets by SHA-256 hash

Files changed (source + compiled runtime, identical edits):
- lab/juice-shop_20.2.0/routes/login.ts
- lab/juice-shop_20.2.0/build/routes/login.js
- lab/juice-shop_20.2.0/server.ts
- lab/juice-shop_20.2.0/build/server.js

Files created/updated (Phase 16):
- remediation/WEB-VUL-001/{before/, remediation.md, after/}
- remediation/WEB-VUL-003/{before/, remediation.md, after/}
- remediation/safety-check-phase16.txt
- docs/remediation.md
- findings/WEB-VUL-001/finding.md, findings/WEB-VUL-003/finding.md (status update)
- docs/vulnerability-findings.md (status update, 2 findings only)
- evidence/evidence-index.csv (EVID-REM-001..005)

Before evidence: EVID-REM-001 (SQLi, 2026-10-04T15:42:55+05:30),
EVID-REM-002 (headers, 2026-10-04T15:43:03+05:30) — both captured on the
unmodified instance before any edit.

Safety: application starts, all functional controls pass (legitimate login,
product API, own-basket read, frontend bundle), headless-browser check clean.

---

## Phase 17 Status — Re-Testing
Status: **COMPLETE** (verified 2026-10-04)

Retest results:
- WEB-VUL-001 → **FIXED** (both Phase 10 payloads now HTTP 401; legitimate
  seeded login still HTTP 200)
- WEB-VUL-003 → **FIXED** (10/10 baseline headers present; 0 browser/CSP
  violations; application renders correctly)

Before evidence: EVID-REM-001, EVID-REM-002 (+ original EVID-REVERIFY-C1/C3)
After evidence: EVID-RETEST-001, EVID-RETEST-002 (+ supporting screenshot
EVID-RETEST-003)

Evidence IDs: EVID-REM-001..005, EVID-RETEST-001..003 (all real artifacts,
indexed in evidence/evidence-index.csv — 33 entries total)

Files created/updated (Phase 17):
- remediation/WEB-VUL-001/after/EVID-RETEST-001-sqli-retest.txt
- remediation/WEB-VUL-003/after/EVID-RETEST-002-headers-retest.txt
- remediation/WEB-VUL-003/after/LAB-016-post-remediation.png
- docs/retesting.md
- findings/WEB-VUL-001/finding.md, findings/WEB-VUL-003/finding.md (retest Fixed)
- docs/vulnerability-findings.md (retest status, 2 findings only)
- evidence/evidence-index.csv (EVID-RETEST-001..003)
- PROJECT_STATUS.md

Retest instance: node build/app pid 6690 started 2026-10-04 15:50:27 +05:30
(after the code changes) serving the mitigated build on 127.0.0.1:3000 only.

Limitations:
- Exactly 2 of 5 findings remediated/retested; WEB-VUL-002, WEB-VUL-004 and
  WEB-VUL-005 remain Not Remediated / Not Retested (by instruction).
- Packaged release has no tsconfig.json, so changes were applied to both TS
  source and compiled build/ output instead of a `tsc` rebuild.
- CSP keeps `style-src 'unsafe-inline'` and two hash-allow-listed inline
  snippets — the verified minimum for the app to run unmodified; not claimed
  maximally strict. HSTS is inert over plain-HTTP localhost by browser design.
- The WEB-VUL-001 fix intentionally makes Juice Shop's own login coding
  challenges unsolvable (direct purpose of the fix).
- Scope is the authorized isolated loopback lab instance only.
- Pre-existing note: the Phase 11 report claimed EVID-FIND-001..005 rows in the
  evidence index, but those rows are not present in evidence/evidence-index.csv
  (pre-existing inconsistency, left unchanged this phase).

Next phase: Phase 19 (Presentation / Viva) — NOT started (stop condition observed).

---

## Third Remediation + Retest — WEB-VUL-002 (basket IDOR)
Status: **COMPLETE** (2026-10-04)

- Root cause: all three `/rest/basket/:id*` handlers loaded the basket solely by
  the client-supplied id (no object-level authorization).
- Mitigation: shared ownership guard `ensureBasketOwnership()` wired into
  `GET /rest/basket/:id`, `POST /rest/basket/:id/checkout`,
  `PUT /rest/basket/:id/coupon/:coupon`.
- Files changed: `routes/basket.ts`, `server.ts`, `build/routes/basket.js`,
  `build/server.js` (source + compiled, identical edits).
- Before: cross-user read HTTP 200 with victim contents (`EVID-REM-006`).
- After: cross-user read/write HTTP 403; own-basket + full legitimate flow OK
  (`EVID-RETEST-004`) → retest result **FIXED**.
- Validation: basket API 13/22 (9 = cross-user/forged-JWT assertions of the
  fixed IDOR, tests unmodified), unit suite unchanged (410/415), full API suite
  delta vs pre-fix run = 9 intended + 1 external fetch flake
  (`EVID-TEST-006/007/008`).
- Records updated: `findings/WEB-VUL-002/finding.md` (Remediated / Fixed),
  `docs/vulnerability-findings.md`, `docs/remediation.md` (Third Remediation
  section), `docs/retesting.md` (third retest section), evidence index
  (+6 entries).
- Previous two remediation records unaltered.

---

## Phase 18 Status — Final Report
Status: **COMPLETE** (2026-10-04)

- Final report: `report/CS-02_Final_Security_Assessment_Report.md`
  (Chapters 1–10 + Traceability Matrix + Findings Summary + Evidence
  Traceability + References + Appendix, per `docs/SPEC_CS-02.txt` §23).
- Cross-checked against actual artifacts (findings/, remediation/, evidence/,
  docs/) — not against status claims alone.

Confirmed findings: **5** (WEB-VUL-001…005)
Remediated findings: **3** (WEB-VUL-001, WEB-VUL-002, WEB-VUL-003)
Retested findings: **3** (all → FIXED: EVID-RETEST-001, EVID-RETEST-004,
EVID-RETEST-002/003)
Remaining findings: **2** (WEB-VUL-004, WEB-VUL-005 — recommendations only)

Application regression testing: **FAIL (documented, fully attributed)**
- Server unit: 415 tests / 410 pass / 3 fail — 3 = files absent from the
  release package (identical with original code).
- Login API: 18 / 13 pass / 5 fail — all 5 assert the fixed SQLi bypass.
- Basket API (after fix 3): 22 / 13 pass / 9 fail — all cross-user or
  forged-JWT assertions of the fixed IDOR.
- Full API suite: 537 / 476 pass / 49 fail vs 492 pass / 33 fail on original
  code (control run) → every delta failure is a vulnerability-assertion test
  (plus 1 external GitHub fetch flake).
- Functional regressions: **0** (13/13 functional login tests pass; full
  basket flow passes; app healthy). No test was modified/disabled/weakened.
- Analysis record: `evidence/phase18-test-suite/EVID-TEST-005-*.md`.

Files created/updated in Phase 18:
- `report/CS-02_Final_Security_Assessment_Report.md` (created)
- `evidence/phase18-test-suite/EVID-TEST-001..008` + `EVID-TEST-005` analysis
- `remediation/WEB-VUL-002/{before/, remediation.md, after/}` (created)
- `findings/WEB-VUL-002/finding.md`, `docs/vulnerability-findings.md` (status)
- `docs/remediation.md`, `docs/retesting.md` (third-remediation sections)
- `evidence/evidence-index.csv` (+12 entries → 45)
- `PROJECT_STATUS.md` (this file)

Known limitations:
- Single-host loopback lab (no VMs — `Virtualization: none`); no network-level
  attack testing; port 5500 and all external systems never touched.
- XSS and session-security areas not confirmed (no safe payload test performed).
- Exact third-party dependency versions not inventoried (not claimed).
- Risk analysis PARTIAL: no separate likelihood/exploitability scoring pass.
- Packaged release lacks `tsconfig.json` and `test/` sources → mitigations
  applied to source + compiled `build/`; regression tests run compiled
  equivalents on Node v22.23.3 (documented commands cannot run as-is).
- Upstream tests assert vulnerable behaviour → documented failures, unmodified.
- Phase 19 (presentation/viva, contribution records, rendered architecture
  diagram) NOT started — stop condition honored.

Next phase: Phase 19 (Presentation / Viva) — requires explicit instruction.

