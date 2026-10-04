# CS-02 — Final Traceability Matrix

Maps each CS-02 requirement → implementation → evidence → test → final status.
Generated at closeout; every path below exists on disk (verified).

| # | CS-02 Requirement | Implementation | Evidence | Test | Final Status |
|---|---|---|---|---|---|
| 1 | **Laboratory deployment** | `scripts/start-lab.sh` runs `node build/app` from the real install | `evidence/logs/LAB-003-juice-shop-running.txt` | `scripts/check-lab.sh` → `LAB STATUS: PASS` | **COMPLETE** |
| 2 | **Network architecture** | Loopback-only binding; LAN IP verified unreachable | `docs/final-state-snapshot.txt` | `check-lab.sh` isolation check | **COMPLETE** |
| 3 | **IP addressing** | Host `10.59.163.195/24`, gw `10.59.163.213`; app on `127.0.0.1:3000` / `:3001` | `docs/final-state-snapshot.txt`, `evidence/recon/RECON-001-port-scan.txt` | `ip addr`, `ss -ltn` | **COMPLETE** |
| 4 | **Reconnaissance** | TCP connect scan + HTTP fingerprinting | `evidence/recon/RECON-001-port-scan.txt` | Re-runnable; raw `connect_ex` output | **COMPLETE** |
| 5 | **Service identification** | Apache :80, MySQL :3306/33060, CUPS :631, Juice Shop :3000 | `RECON-001-port-scan.txt`, `evidence/scanner-results/RECON-001-port-scan.txt` | banner/version inspection | **COMPLETE** |
| 6 | **Technology identification** | Juice Shop 20.2.0, Express 4.22.2, Node v22.23.3, Angular SPA, SQLite/Sequelize; `X-Powered-By` absent | `evidence/recon/RECON-002-technology.txt` | headers + `package.json` + runtime inspection | **COMPLETE** |
| 7 | **Application mapping** | Route inventory + live probing; registered a customer account to see authed behaviour | `docs/application-map.md`, `evidence/scanner-results/EVID-MAP-001-entrypoint.txt`, `EVID-MAP-002-routes.txt` | `curl` probe of each route | **COMPLETE** |
| 8 | **Security assessment (10 areas)** | Authentication, authorization, access control, input validation, injection, XSS, session, misconfiguration, info exposure, components | `docs/security-assessment.md` | Per-area notes incl. **not-confirmed** areas | **COMPLETE** |
| 9 | **Findings (10)** | `findings/WEB-VUL-001` … `findings/WEB-VUL-010` (each `finding.md`, 17 sections) | `evidence/findings/V-001` … `evidence/findings/V-010` | `bash scripts/capture-verification-evidence.sh` | **COMPLETE** |
| 10 | **Controlled validation** | Boolean-differential SQLi; three-token-matrix access control; content-level key check | `V-001`, `V-006`, `V-009` | Deterministic, repeatable | **COMPLETE** (10 validations) |
| 11 | **Authentication assessment** | Login behaviour, password storage, token issuance | `V-001`, `V-007` | `POST /rest/user/login`; JWT payload decode | **COMPLETE** |
| 12 | **Access-control assessment** | Object-level (basket) and function-level (`/api/Users`) | `V-002`, `V-006` | 3-token matrix; cross-user basket probe | **COMPLETE** |
| 13 | **Security-configuration assessment** | Headers, CORS, info disclosure, verbose errors | `V-003`, `V-004`, `V-010`, `V-009` | Header enumeration; preflight; error capture | **COMPLETE** |
| 14 | **Risk analysis** | 4-factor scoring with written reasoning | `docs/risk-analysis.md`, `findings/risk-register.csv` | 10 rows, CSV-parsed | **COMPLETE** |
| 15 | **Remediation — recommendations** | Recommended control per finding | `findings/REMEDIATION_REGISTER.md`, `docs/remediation.md` | Table separates recommended vs implemented | **COMPLETE** |
| 16 | **Remediation — implemented** | REMED-001 (CORS), REMED-002 + 002b (keys) | `evidence/remediation/REMED-before.txt`, `REMED-after.txt`, `REMED-cors-analysis.txt` | Baseline left unmodified; fixes only in copy | **COMPLETE (3 changes)** |
| 17 | **Re-testing** | Identical request replayed against :3000 and :3001 | `docs/retesting.md`, `evidence/remediation/REMED-after.txt` | 5 findings re-tested | **COMPLETE (5 RE-TESTED)** |
| 18 | **Before/after evidence** | Side-by-side capture, both instances live | `evidence/remediation/REMED-before.txt`, `REMED-after.txt` | Byte counts + status codes + content greps | **COMPLETE** |
| 19 | **Evidence index** | `evidence/evidence-index.csv`, 78 rows | index itself | CSV-aware existence check | **COMPLETE (0 broken paths, 0 duplicate IDs)** |
| 20 | **Baseline preservation** | Baseline untouched and still vulnerable | `evidence/remediation/REMED-baseline-integrity.txt` | MD5 + live `ACAO: *` on :3000 | **COMPLETE** |
| 21 | **Technical report** | 10 chapters + references + appendix | `report/CS-02_Final_Security_Assessment_Report.md` | Chapter/section presence check | **COMPLETE** |
| 22 | **Architecture diagram** | Testing machine → app server → Juice Shop (baseline + remediation) | `docs/architecture-final.md` | Rendered text diagram | **COMPLETE** |
| 23 | **Presentation** | 15 slides | `presentation/CS-02_Presentation.md` | Slide count = 15 | **COMPLETE** |
| 24 | **Practical demonstration** | 18-step checklist with verified commands | `docs/practical-demonstration.md` | Commands spot-checked live | **COMPLETE** |
| 25 | **Viva preparation** | 24 questions, short + detailed + project example | `viva/CS-02_Viva_Preparation.md` | Project examples cross-checked to evidence | **COMPLETE** |
| 26 | **Individual contribution** | 3-student split with whole-project comprehension | `docs/individual-contribution.md` | — | **COMPLETE** |

## Honest status summary

- Deliverables 1–26: **all COMPLETE**.
- **Findings:** 10 documented. **Remediated and re-tested: 5.** **Open: 5.**
- No requirement is marked complete on the basis of an unverified claim; every status
  above is backed by a file that exists and, where applicable, was re-run against the
  running lab during closeout.