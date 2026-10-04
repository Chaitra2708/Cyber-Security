# CS-02 — Traceability Matrix

Maps every major requirement of the project specification to the project phase
that fulfilled it, the artifact that carries it, the supporting evidence, and
the honest status. (The specification document itself is not published.)

Legend: **COMPLETE** — artifact + evidence exist · **PARTIAL** — performed in
part with a recorded limitation · **NOT COMPLETE** — not performed and not
claimed · **NOT APPLICABLE** — requirement does not fit the actual lab.

## A. Methodology / lifecycle requirements

| PDF Requirement | Phase | Project Artifact | Evidence | Status |
|---|---|---|---|---|
| Laboratory preparation & deployment | 4–6 | `scripts/start-lab.sh`, `scripts/check-lab.sh` | `evidence/logs/juice-shop-startup.log` (local only), `evidence/scanner-results/LAB-001-environment.txt`, screenshot Figure A.1 | COMPLETE |
| Network isolation / application access | 5–6 | `scripts/check-lab.sh` (LAN-unreachable check) | Health-check output recorded in `PROJECT_STATUS.md` | COMPLETE |
| Web reconnaissance (ports/services) | 7 | `evidence/scanner-results/RECON-001-port-scan.txt`, `tcp-scan-127.0.0.1.json` | RAW-013 / RAW-017 | COMPLETE |
| Technology identification | 7 | `evidence/scanner-results/RECON-002-technology.txt/json` | RAW-014 | COMPLETE |
| Application mapping | 9 | `docs/application-map.md` | `EVID-MAP-001`, `EVID-MAP-002` | COMPLETE |
| Security assessment (OWASP areas) | 10 | `docs/security-assessment.md` §3–§12 | EVID-ASSESS-001…008 (within the doc), `EVID-REVERIFY-C1..C5` | COMPLETE |
| Vulnerability identification (≥5 findings) | 11 | `docs/vulnerability-findings.md`, `findings/WEB-VUL-001..005/` | 5 finding records + evidence IDs | COMPLETE |
| Controlled validation (≥2) | 10/12 | `docs/security-assessment.md` §13–14 | 5 validations: `EVID-REVERIFY-C1..C5` (+ historical `RAW-001..010`) | COMPLETE |
| Authentication & access-control assessment | 13 | `docs/security-assessment.md` §3, §4, §8 | EVID-ASSESS-001/002 + C1/C2 evidence | COMPLETE |
| Security configuration assessment | 14 | `docs/security-assessment.md` §9, §11 | EVID-ASSESS-005/007 + C3/C4/C5 evidence | COMPLETE |
| Risk analysis / risk register | 15 | Severity, impact, justification, recommendation per finding; register = `docs/vulnerability-findings.md` §3 | finding records | PARTIAL — no separate likelihood/exploitability scoring pass |
| Remediation recommendations (all major findings) | 16 | recommendation sections in all 5 findings | — | COMPLETE |
| Remediation implemented (≥2) | 16 | `docs/remediation.md`, `remediation/WEB-VUL-001`, `remediation/WEB-VUL-003` | `EVID-REM-001..005` | COMPLETE (2 required, 2 implemented in Phase 16) |
| Additional remediation | 16/18 | `remediation/WEB-VUL-002` | `EVID-REM-006`, `EVID-REM-007` | COMPLETE (3rd implemented) |
| Re-testing (≥2, before/after) | 17 | `docs/retesting.md` | `EVID-RETEST-001..003` | COMPLETE (2 required, 2 retested in Phase 17) |
| Additional retest | 17/18 | `docs/retesting.md` (third section) | `EVID-RETEST-004` | COMPLETE (3rd retested, FIXED) |
| Application regression testing | 18 | `evidence/phase18-test-suite/EVID-TEST-005` (analysis) | `EVID-TEST-001..008` | COMPLETE (executed; result FAIL = attributed vulnerability-assertion failures, 0 functional regressions) |
| Final technical report | 18 | `report/CS-02_Final_Security_Assessment_Report.md` | — | COMPLETE |
| Evidence documentation (13 mandatory categories) | all | `evidence/`, `remediation/` | `evidence/evidence-index.csv` (45 entries) | COMPLETE |
| Presentation (12–15 slides) | 19 | — | — | NOT COMPLETE (not started by instruction) |
| Practical demonstration / viva | 19 | — | — | NOT COMPLETE (not started by instruction) |
| Architecture diagram (deliverable) | 19 | textual architecture + trust boundaries in `docs/application-map.md` §9 and report §3.8 | — | PARTIAL (textual only) |
| Individual contribution records | 19 | — | — | NOT COMPLETE (not available) |

## B. Minimum technical deliverables (spec §21)

| Deliverable | Required | Actual | Status |
|---|---|---|---|
| Vulnerability findings | ≥5 | 5 | COMPLETE |
| Controlled validations | ≥2 | 5 | COMPLETE |
| Findings with evidence/impact/severity/recommendation | all majors | 5/5 | COMPLETE |
| Remediations implemented | ≥2 | 3 | COMPLETE |
| Re-tests with before/after evidence | ≥2 | 3 | COMPLETE |
| Technical report | yes | `report/CS-02_Final_Security_Assessment_Report.md` | COMPLETE |
| Evidence index | yes | `evidence/evidence-index.csv` | COMPLETE |
| Presentation | yes | — | NOT COMPLETE (Phase 19) |

## C. Scope compliance

| Requirement | Status |
|---|---|
| Only `127.0.0.1:3000` tested | COMPLETE — no other target contacted by testing activity |
| Out-of-scope list honored (5500, public sites, third-party, DoS, malware, real accounts) | COMPLETE |
| No destructive testing | COMPLETE (cross-user checkout deliberately *not* executed pre-fix to avoid destroying seeded data — recorded in `EVID-REM-006`) |
| Evidence authentic (no fabrication) | COMPLETE — every `EVID-*` path verified to resolve |
