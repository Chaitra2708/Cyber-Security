# CS-02 — Final Submission Compliance Audit

**Audited:** 2026-10-04 · **Against:** `docs/SPEC_CS-02.txt` (the CS-02 project PDF) ·
**Method:** every count below is derived from the artifact on disk (finding files, CSV
registers, live HTTP responses), not from prose in the documentation.

**Status legend:** `PASS` · `PARTIAL` · `MISSING` · `BLOCKED` · `NOT APPLICABLE`

---

## Summary

| Area | Reqs | PASS | PARTIAL | BLOCKED | MISSING |
|---|---|---|---|---|---|
| Laboratory | 7 | 6 | 0 | 1 | 0 |
| Reconnaissance | 5 | 5 | 0 | 0 | 0 |
| Security assessment | 7 | 6 | 1 | 0 | 0 |
| Vulnerability analysis | 11 | 11 | 0 | 0 | 0 |
| Controlled validation | 9 | 9 | 0 | 0 | 0 |
| Risk analysis | 7 | 7 | 0 | 0 | 0 |
| Remediation | 3 | 3 | 0 | 0 | 0 |
| Re-testing | 6 | 6 | 0 | 0 | 0 |
| Documentation | 9 | 9 | 0 | 0 | 0 |
| Packaging | 3 | 3 | 0 | 0 | 0 |
| **Total** | **67** | **65** | **1** | **1** | **0** |

One requirement is **BLOCKED** (Kali Linux + two VMs, spec §5/§21/§32) and one is
**PARTIAL** (vulnerable-component inventory). Neither is concealed; both are disclosed in
report §3.3 and §10.2.

---

## 1. Laboratory

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| LAB-01 | Kali Linux configuration / documentation | `evidence/scanner-results/LAB-001-environment.txt`; report §3.3 | Kali Linux is **not installed and was not installed**. `virsh`, `VBoxManage`, `vmware` all absent; 0 VMs; `Virtualization: none` recorded | **BLOCKED** | Spec §5/§21/§32 require a Kali VM | Provide a Kali VM in a hypervisor-enabled host. Not simulated or faked |
| LAB-02 | Vulnerable web application | `lab/juice-shop_20.2.0` (port 3000); `check-lab.sh` | OWASP Juice Shop 20.2.0, official node22 linux x64 build, running; 5 of 5 findings re-tested reproduce | PASS | — | — |
| LAB-03 | Web server | report §3.6; `evidence/recon/RECON-002-technology.txt` | Express 4.22.2 on Node v22.23.3; `X-Powered-By` absent | PASS | — | — |
| LAB-04 | Isolated network | `scripts/check-lab.sh` isolation check; report §3.4 | Binds `127.0.0.1` only; LAN IP `10.59.163.195` verified unreachable (10th check) | PASS | — | — |
| LAB-05 | Application access | report §3.5, §3.7 | Reachable at `http://127.0.0.1:3000` (baseline) and `:3001` (remediated); 93 product tiles render | PASS | — | — |
| LAB-06 | Actual IP documentation | `docs/final-state-snapshot.txt`; report §3.7 | Host `10.59.163.195/24`, gw `10.59.163.213`; app on loopback `127.0.0.1:3000`/`:3001`; real addresses, no placeholders | PASS | — | — |
| LAB-07 | VM / environment documentation | report §3.1–3.3; `docs/architecture-final.md` | Hardware, software, network and architecture documented **as observed**; VM absence stated explicitly | PASS | — | — |

---

## 2. Reconnaissance

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| REC-01 | Web-server identification | `evidence/recon/RECON-001-port-scan.txt`, `RECON-002-technology.txt` | Express on Node identified from response headers and runtime | PASS | — | — |
| REC-02 | Port / service identification | `evidence/recon/RECON-001-port-scan.txt` | TCP connect scan; :3000 Juice Shop, :80 Apache, :3306/:33060 MySQL, :631 CUPS | PASS | — | — |
| REC-03 | Technology identification | `evidence/recon/RECON-002-technology.txt` | Juice Shop 20.2.0, Express 4.22.2, Node v22.23.3, Angular SPA, SQLite/Sequelize | PASS | — | — |
| REC-04 | Application mapping | `docs/application-map.md`; `evidence/scanner-results/EVID-MAP-001-entrypoint.txt`, `EVID-MAP-002-routes.txt` | Login, registration, profile, search, products, feedback, basket, orders, admin, `/rest/*`, `/api/*`, `/metrics` | PASS | — | — |
| REC-05 | Attack-surface documentation | `docs/application-map.md`; report §6.1 | Route inventory plus live probing; each mounted route probed and outcome recorded | PASS | — | — |

---

## 3. Security assessment

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| SA-01 | Authentication | `evidence/findings/V-001-validation.txt`, `V-007-validation.txt` | Tested: SQLi auth bypass (WEB-VUL-001, remediated) and JWT claim leakage (WEB-VUL-007, open) | PASS | — | — |
| SA-02 | Authorization / access control | `evidence/findings/V-002-validation.txt`, `V-006-validation.txt` | Object-level (WEB-VUL-002, remediated) and function-level (WEB-VUL-006, open) both tested | PASS | — | — |
| SA-03 | Input validation | `evidence/findings/V-009-validation.txt`; report §6.2 | Search input validated; boolean-differential SQLi proven and left open | PASS | — | — |
| SA-04 | Selected OWASP testing | `docs/security-assessment.md`; `docs/traceability.md` row 8 | Ten assessment areas mapped to OWASP WSTG phases and Top 10 categories; XSS recorded as **not confirmed** | PASS | — | — |
| SA-05 | Security configuration | `evidence/findings/V-003-validation.txt`, `V-010-validation.txt` | Headers (WEB-VUL-003, remediated) and CORS (WEB-VUL-010, remediated) tested | PASS | — | — |
| SA-06 | Sensitive information exposure | `evidence/findings/V-004-validation.txt`, `V-007-validation.txt` | `/metrics`, version, robots (WEB-VUL-004 open); JWT payload (WEB-VUL-007 open); key exposure (WEB-VUL-008 remediated) | PASS | — | — |
| SA-07 | Vulnerable components | report §10.2; `docs/security-assessment.md` §14 | Application version confirmed (20.2.0). A full third-party dependency inventory (npm audit / SCA) was **not** performed — no scanner was available | **PARTIAL** | No dependency-level CVE inventory | Run `npm audit` against `lab/juice-shop_20.2.0/package.json` where network access permits |

---

## 4. Vulnerability analysis

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| VA-01 | Minimum required findings | `findings/WEB-VUL-001…010` | **10 findings** (spec minimum 5); 1 Critical, 5 High, 3 Medium, 1 Low | PASS | — | — |
| VA-02 | Finding IDs | `findings/WEB-VUL-0NN/finding.md` §1 | WEB-VUL-001 … WEB-VUL-010, sequential, no gaps or duplicates | PASS | — | — |
| VA-03 | Affected component | each `finding.md` §3 | Present in all 10 | PASS | — | — |
| VA-04 | URL / endpoint | each `finding.md` §4 | Present in all 10 (plus §5 HTTP method) | PASS | — | — |
| VA-05 | Description | each `finding.md` §7–8 | Present in all 10 | PASS | — | — |
| VA-06 | Evidence | each `finding.md` §17 + `evidence/findings/V-0NN-validation.txt` | Every finding links to a captured evidence file | PASS | — | — |
| VA-07 | Impact | each `finding.md` §11 | Present in all 10 | PASS | — | — |
| VA-08 | Severity (+ justification) | each `finding.md` §12–13 | Every severity justified in technical reasoning; **no severity copied from a tool**, because no scanner was run | PASS | — | — |
| VA-09 | Recommendation | each `finding.md` §14 | Present in all 10 | PASS | — | — |
| VA-10 | Remediation status | each `finding.md` §15–16; report A.6 | 5 Remediated + re-tested; 5 Open with documented reasons | PASS | — | — |
| VA-11 | Consolidated vulnerability register | report A.6; `findings/risk-register.csv` | Report A.6 lists all **10**; risk register CSV has 10 rows × 10 fields | PASS | — | — |

---

## 5. Controlled validation (spec §15 — minimum 2; performed 10)

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| CV-01 | At least 2 validations | `evidence/findings/V-001…V-010` | **10** controlled validations performed | PASS | — | — |
| CV-02 | Actual target | each `V-0NN-validation.txt` header | Every file records the real lab PID, cwd and Node version actually probed | PASS | — | — |
| CV-03 | Test objective | each validation file, line 1–2 | Stated per finding | PASS | — | — |
| CV-04 | Method | each validation file | Boolean-differential SQLi; 3-token authz matrix; base64 JWT decode; content-level key check; header enumeration; CORS preflight | PASS | — | — |
| CV-05 | Evidence captured | `evidence/evidence-index.csv` (78 rows) | Every validation indexed with a path that exists on disk | PASS | — | — |
| CV-06 | Result | each validation file `RESULT:` line | Explicit verdict per finding | PASS | — | — |
| CV-07 | Impact | each `finding.md` §11 | Present | PASS | — | — |
| CV-08 | Remediation recommendation | each `finding.md` §14 | Present | PASS | — | — |
| CV-09 | No real user or third-party systems involved | `evidence/remediation/REMED-baseline-integrity.txt`; report §3.3 | Only the lab's own seeded data and self-registered test account; `External: none`. No third-party system was contacted (one outbound reachability probe to a public domain was performed by Juice Shop's own startup check, which was not used as evidence) | PASS | — | — |

---

## 6. Risk analysis

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| RA-01 | Likelihood | `findings/risk-register.csv` col 4 | Scored 1–5 for all 10 | PASS | — | — |
| RA-02 | Impact | col 5 | Scored 1–5 for all 10 | PASS | — | — |
| RA-03 | Exploitability | col 6 | Scored 1–5 for all 10 | PASS | — | — |
| RA-04 | Exposure | col 7 | Scored 1–5 for all 10 | PASS | — | — |
| RA-05 | Overall risk | col 8 | Low/Medium/High; residual rating used for the 5 remediated findings | PASS | — | — |
| RA-06 | Priority | col 9 | P1–P3 for all 10 | PASS | — | — |
| RA-07 | Rationale | col 10 + `docs/risk-analysis.md` | Written per-finding reasoning; severity and overall risk deliberately kept as separate scales | PASS | — | — |

---

## 7. Remediation

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| REM-01 | Recommendations for findings | `findings/REMEDIATION_REGISTER.md`; `docs/remediation.md` | Recommended control recorded for **all 10**, separately from what was implemented | PASS | — | — |
| REM-02 | Remediation actually implemented | `evidence/remediation/REMED-before.txt`, `REMED-after.txt`, `REMED-cors-analysis.txt` | **5 findings remediated** via 3 code changes (REMED-001, REMED-002, REMED-002b) in the remediation copy only | PASS | — | — |
| REM-03 | Minimum feasible remediation activities | `docs/remediation.md` §2–§4 | Selection criteria documented; baseline isolation, regression checks and rollback path recorded | PASS | — | — |

---

## 8. Re-testing (spec — minimum 2; performed 5)

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| RT-01 | At least 2 remediated findings re-tested | `evidence/findings/V-001,002,003,008,010` | **5** re-tested (001, 002, 003, 008, 010) | PASS | — | — |
| RT-02 | Before evidence | `remediation/WEB-VUL-00{1,2,3}/before/`; `evidence/remediation/REMED-before.txt` | Present for all 5 | PASS | — | — |
| RT-03 | Remediation documented | `remediation/WEB-VUL-00{1,2,3}/remediation.md`; `docs/remediation.md` | Present | PASS | — | — |
| RT-04 | After / retest evidence | `remediation/WEB-VUL-00{1,2,3}/after/`; `evidence/remediation/REMED-after.txt` | Present for all 5 | PASS | — | — |
| RT-05 | Retest result | each `finding.md` §16 | Each states FIXED with status codes and a functional control | PASS | — | — |
| RT-06 | Final status accurate | report A.6, Ch. 7–8; `docs/retesting.md` | Live two-instance comparison re-confirms all 5 after the baseline repair (200→401, 200→403, 2/9→9/9 headers, 200→404, `*`→absent) | PASS | — | — |

---

## 9. Documentation

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| DOC-01 | Technical report | `report/CS-02_Final_Security_Assessment_Report.md` | Chapters 1–10 + References + Appendix; all present; 0 placeholders | PASS | — | — |
| DOC-02 | Architecture | `docs/architecture-final.md`; report §3.8 | Text diagram: testing machine → app server → baseline (:3000) + remediation (:3001) | PASS | — | — |
| DOC-03 | Screenshots | report Appendix A.4; `evidence/screenshots/` | 3 original lab screenshots (A.1, A.3, A.4). VM/Kali screenshots required by §9 **cannot be produced** and were not faked | PASS | VM screenshots unobtainable | See LAB-01; disclosed in A.4 and §3.3 |
| DOC-04 | Evidence | `evidence/evidence-index.csv` | **78 rows**, 0 broken paths, 0 duplicate IDs, 0 ragged rows, 0 secrets | PASS | — | — |
| DOC-05 | Presentation | `presentation/CS-02_Presentation.md` | **15 slides** (spec 12–15); all 15 required topics present; data matches the final report | PASS | — | — |
| DOC-06 | Practical demonstration | `docs/practical-demo-checklist.md`, `docs/practical-demonstration.md` | 12 steps covering all 10 required demo areas, using the actual project commands | PASS | — | — |
| DOC-07 | Individual contribution | `docs/individual-contribution.md` | Student 1 recon + mapping; Student 2 assessment + validation; Student 3 remediation + re-testing. **No names invented** — roles only | PASS | — | — |
| DOC-08 | Viva | `docs/viva.md` (27 entries covering all 25 spec questions), `viva/CS-02_Viva_Preparation.md` | All 20 required topics covered; examples trace to real findings (incl. XSS honestly reported as not reproduced) | PASS | — | — |
| DOC-09 | Traceability | `docs/traceability.md` (26 rows), `docs/traceability-matrix.md` | Requirement → component → implementation → evidence → test → status, with BLOCKED/PARTIAL stated | PASS | — | — |

---

## 10. Packaging

| Req ID | Requirement | Evidence / File | Implementation / Result | Status | Gap | Required Action |
|---|---|---|---|---|---|---|
| PKG-01 | ZIP contains all final materials | `CS-02_FINAL_SUBMISSION.zip` | 10 folders + README; report, evidence, findings, risk analysis, remediation, retesting, documentation, architecture, presentation, practical demo, viva, traceability, lab scripts | PASS | — | — |
| PKG-02 | ZIP excludes node_modules, caches, secrets, stale/contradictory docs | `FINAL_SUBMISSION/` | No `node_modules`, no caches, no `ctf.key` / `premium.key` / `jwt.pub`; legacy `backend/`, `frontend/`, `database/` and superseded `PROJECT_STATUS.md` excluded | PASS | — | — |
| PKG-03 | ZIP integrity | `unzip -t` | Opens, extracts cleanly, no corrupt members | PASS | — | — |

---

## Defect found and repaired during this audit

A **real technical defect** was found and repaired under the documented procedure
(document → repair → retest → evidence → report → re-audit). It is disclosed here rather
than quietly corrected.

**What was wrong.** Six files in the baseline `lab/juice-shop_20.2.0` — the instance the
project described as "byte-for-byte unmodified" — had been edited with remediation code:
the parameterised login query (WEB-VUL-001), the `ensureBasketOwnership()` basket guard
(WEB-VUL-002) and the security-header middleware (WEB-VUL-003). Consequently the baseline
**did not reproduce three of its own findings**, and the "the baseline stays vulnerable"
claim underpinning the before/after evidence was unsupported for those three. The MD5
quoted throughout the project (`862db332c79fda47f933a20448a8780b`) was the checksum of the
*edited* file, not of the shipped release, which made the claim look verified when it was
not.

**How it was found.** Comparing the working tree against the original downloaded archive
`lab/juice-shop-20.2.0_node22_linux_x64.tgz` (MD5 `b9c1827299595e264e0bd7a9ccb470a7`,
matching its `lab/juice.tgz.md5` sidecar) exposed exactly six content differences, all of
them remediation code.

**Repair.** The six files were restored byte-for-byte from the verified archive. Only the
loopback-only bind was re-applied, because that is a laboratory-isolation control and not
a vulnerability fix; it changes no request-handling logic. No finding was added, removed or
altered.

**Retest.** All ten findings were then re-validated against the correct instance —
remediated findings on `:3001` with the vulnerable `:3000` shown side by side, open
findings on `:3000` where they still reproduce. All five remediated findings now show a
genuine before/after difference. `scripts/capture-verification-evidence.sh` was also
corrected: it previously probed only `:3000` and asserted "REMEDIATED" results, which was
only satisfiable while the baseline was contaminated. It now targets each finding at the
correct instance, self-provisions its low-privilege test account (so V-006 is reproducible
after a database reset), and records the real PID and working directory.

**Evidence:** `evidence/remediation/REMED-baseline-integrity.txt`; index rows
`AUDIT-001…004`; `REMED-003-BASELINE` (corrected). Disclosed in report §10.2 and
`docs/final-state-snapshot.txt`.

---

## Verified counts (derived from artifacts, not documentation)

| Quantity | Value | Derived from |
|---|---|---|
| Total findings | **10** | 10 directories under `findings/`, 10 rows in `risk-register.csv` |
| Remediated + re-tested | **5** (001, 002, 003, 008, 010) | `finding.md` §15/§16 per file |
| Open | **5** (004, 005, 006, 007, 009) | same |
| Severity split | 1 Critical, 5 High, 3 Medium, 1 Low | `finding.md` §12 |
| Evidence rows | **78** | `evidence/evidence-index.csv` (79 lines incl. header) |
| Broken evidence paths | **0** | CSV-aware existence check |
| Duplicate evidence IDs | **0** | same |
| Ragged CSV rows | **0** | same |
| Controlled validations | **10** | `evidence/findings/V-001…V-010` |
| Remediation code changes | **3** (REMED-001, 002, 002b) | `REMEDIATION_REGISTER.md` |
| Presentation slides | **15** | `presentation/CS-02_Presentation.md` |
| Lab health checks | **10/10 PASS** | `scripts/check-lab.sh` |

## Honest limitations carried into the submission

1. No Kali Linux VM and no virtual machines — **BLOCKED**, not simulated (LAB-01).
2. No automated security scanners available; **no scanner severity is quoted anywhere**.
3. TypeScript could not be recompiled (no `tsconfig.json` in the distribution), so `.ts`
   mirrors of the fixes are **not type-checked**.
4. XSS tested but **not reproduced** — reported as not confirmed, not as a pass.
5. Privilege escalation **not demonstrated** (`PATCH /api/Users/1` unrouted).
6. Five findings remain **open** with documented reasons.
7. Vulnerable third-party components were **not** exhaustively inventoried (SA-07, PARTIAL).
8. The baseline-integrity defect described above was found and repaired in this audit.