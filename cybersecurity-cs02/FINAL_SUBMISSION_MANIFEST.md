# CS-02 — Final Submission Manifest

**Generated:** 2026-10-04 · **Audit:** `FINAL_SUBMISSION_AUDIT.md`

---

## Project

| Field | Value |
|---|---|
| **Project** | CS-02 — Web Application Security Assessment Using OWASP Methodology |
| **Application** | OWASP Juice Shop 20.2.0 (official `node22_linux_x64` distribution) |
| **Methodology** | OWASP WSTG phases; findings mapped to OWASP Top 10 categories |
| **Laboratory** | Single Linux Mint 22.3 host, loopback-only binding |
| **Baseline instance** | `lab/juice-shop_20.2.0` @ `127.0.0.1:3000` (pristine) |
| **Remediated instance** | `lab/juice-shop_20.2.0-remediated` @ `127.0.0.1:3001` |

## Verified counts

Derived from the artifacts on disk, not from documentation prose.

| Quantity | Value |
|---|---|
| **Findings** | **10** (WEB-VUL-001 … WEB-VUL-010) |
| **Remediated + Retested** | **5** — WEB-VUL-001, 002, 003, 008, 010 |
| **Open** | **5** — WEB-VUL-004, 005, 006, 007, 009 |
| Severity split | 1 Critical · 5 High · 3 Medium · 1 Low |
| Controlled validations | 10 (spec minimum 2) |
| Remediation code changes | 3 (REMED-001, REMED-002, REMED-002b) |
| **Evidence** | **78 rows**, 0 broken paths, 0 duplicate IDs, 0 ragged rows |
| Risk register | 10 rows × 10 fields, CSV-parsed |
| Presentation | 15 slides (spec 12–15) |
| Traceability | 26 requirement rows |

## Component status

| Component | Status | Basis |
|---|---|---|
| **Lab** | **PASS** | `scripts/check-lab.sh` → `LAB STATUS: PASS` (10/10 checks); both instances live on loopback |
| **Application** | **PASS** | Juice Shop 20.2.0 serving; 93 product tiles; REST API and SPA functional on both instances |
| **Findings** | **PASS** | 10 findings, 17 sections each, all 8 spec-required fields present |
| **Remediated + retested** | **PASS** | 5 findings with before evidence, implementation, after evidence and functional control |
| **Open findings** | **PASS** | 5 findings documented with evidence, impact, severity, recommendation and a stated reason for remaining open |
| **Evidence** | **PASS** | 78 indexed rows, every path exists, no duplicates, no secrets |
| **Risk** | **PASS** | 4-factor scoring + overall risk + priority + rationale for all 10 |
| **Report** | **PASS** | Chapters 1–10 + References + Appendix; 0 placeholders; counts and statuses verified |
| **Presentation** | **PASS** | 15 slides covering all 15 required topics; figures match the final report |
| **Practical demonstration** | **PASS** | 12-step checklist covering all 10 required areas, using the real project |
| **Viva** | **PASS** | 27 entries covering all 25 spec questions and all 20 required topics |
| **Individual contribution** | **PASS** | Three student roles documented; no names invented |
| **Traceability** | **PASS** | Requirement → component → implementation → evidence → test → status |
| **ZIP** | **PASS** | Opens, extracts cleanly, contains all final materials, excludes caches/secrets/stale docs |
| Kali Linux + 2 VMs | **BLOCKED** | Not available on this host; not simulated or faked (audit LAB-01) |
| Vulnerable components | **PARTIAL** | Application version confirmed; third-party dependency CVE inventory not performed (audit SA-07) |

## Deliverables

| Artifact | Path |
|---|---|
| Technical report | `report/CS-02_Final_Security_Assessment_Report.md` |
| Findings (10 × 17 sections) | `findings/WEB-VUL-0NN/finding.md` |
| Vulnerability register | report Appendix A.6 · `findings/risk-register.csv` |
| Risk analysis | `docs/risk-analysis.md` · `findings/risk-register.csv` |
| Remediation | `docs/remediation.md` · `findings/REMEDIATION_REGISTER.md` · `remediation/` |
| Re-testing | `docs/retesting.md` · `evidence/remediation/REMED-{before,after}.txt` |
| Evidence register | `evidence/evidence-index.csv` (78 rows) + captured artifacts |
| Architecture | `docs/architecture-final.md` |
| Presentation | `presentation/CS-02_Presentation.md` (15 slides) |
| Practical demonstration | `docs/practical-demo-checklist.md` · `docs/practical-demonstration.md` |
| Viva | `docs/viva.md` · `viva/CS-02_Viva_Preparation.md` |
| Individual contribution | `docs/individual-contribution.md` |
| Traceability | `docs/traceability.md` · `docs/traceability-matrix.md` |
| Lab scripts | `scripts/start-lab.sh` · `stop-lab.sh` · `check-lab.sh` · `capture-verification-evidence.sh` |
| Compliance audit | `FINAL_SUBMISSION_AUDIT.md` |
| Packaged submission | `CS-02_FINAL_SUBMISSION.zip` |

## Limitations (actual only)

1. **No Kali Linux host and no virtual machines.** `virsh`, `VBoxManage` and `vmware` are
   absent; 0 VMs exist. Kali was **not installed to satisfy the requirement**, and the VM /
   Kali screenshots required by spec §9 were **not faked or substituted**. Disclosed in
   report §3.3 and Appendix A.4; recorded as BLOCKED in the audit.
2. **No automated security scanners.** nmap, Nikto, OWASP ZAP, WhatWeb and Nuclei are not
   installed and `sudo` requires a password. All validation used `curl`, Python
   `socket`/`sqlite3`, headless Chrome and source analysis. **No scanner severity is quoted
   anywhere in this submission**, because none was produced.
3. **TypeScript not recompiled.** The distribution ships no `tsconfig.json`, so
   `npm run build:server` (tsc) cannot run. Fixes were applied to `build/*.js` (the runtime
   artifact) and mirrored into `*.ts`, which therefore are **not type-checked**.
4. **XSS not reproduced.** Harmless payloads did not reflect and the CSP restricts
   `script-src` without `'unsafe-inline'`. Reported as **not confirmed**, never as a pass.
5. **Privilege escalation not demonstrated.** `PATCH /api/Users/1` is unrouted, so
   WEB-VUL-006 is rated on proven read-only impact only.
6. **Five findings remain open** — WEB-VUL-004, 005, 006, 007, 009 — each with a documented
   reason. They are not claimed as fixed, and no further remediation was forced merely to
   improve the numbers.
7. **Third-party dependency inventory not performed** (no scanner; network-restricted).
8. **Baseline-integrity defect found and repaired during this audit.** Six files in the
   "unmodified" baseline had been edited with remediation code, so it no longer reproduced
   WEB-VUL-001/002/003. They were restored byte-for-byte from the original distribution
   archive (MD5 verified against its sidecar); only the loopback bind was re-applied. All
   ten findings were then re-validated against the correct instance. Full disclosure in
   `evidence/remediation/REMED-baseline-integrity.txt`, report §10.2, and audit rows
   `AUDIT-001…004`.

---

## Final determination

**SUBMISSION READY** — with one requirement **BLOCKED** (Kali Linux + two virtual
machines, which could not be provided or honestly simulated) and one **PARTIAL**
(third-party dependency inventory). Both are disclosed in the report, the audit and this
manifest. No finding was fabricated, no scanner output was invented, and no open finding
was closed to improve the result.