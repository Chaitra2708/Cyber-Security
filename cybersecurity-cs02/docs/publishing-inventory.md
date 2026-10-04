# Publishing Inventory — CS-02

Classification of every important project artifact for public release.
Produced for the publishing/packaging task (no assessment content was changed
for publishing; sanitization only affects the public copy).

Legend:

- **PUBLIC** — safe to publish as-is.
- **SANITIZE BEFORE PUBLICATION** — publishable after sanitization (machine
  paths, hostname, LAN IPs). Replacements used: `<PROJECT_ROOT>`, `<HOME>`,
  `<HOSTNAME>`, `<LAN_IP>`, `<LAN_GATEWAY>`, `<LAN_SUBNET>`. Loopback
  `127.0.0.1` is retained because it is necessary to reproduce the project.
- **DO NOT PUBLISH** — excluded from the public repository entirely.

## 1. Root files

| Artifact | Classification | Notes |
|---|---|---|
| `README.md` (created for publishing) | PUBLIC | Written for GitHub/faculty/reviewers |
| `PROJECT_STATUS.md` | PUBLIC | No secrets; machine paths sanitized in copy |
| `.gitignore` | PUBLIC | Extended with key/env/coverage patterns |
| `LICENSE` | N/A — **not selected by project owner** | No license existed; none invented |
| `docs/SPEC_CS-02.txt`, `docs/SPEC_CS-02.pdf` | DO NOT PUBLISH | College assignment document; not needed to understand the project |

## 2. docs/

| Artifact | Classification | Notes |
|---|---|---|
| `docs/application-map.md` | PUBLIC | |
| `docs/security-assessment.md` | PUBLIC | |
| `docs/vulnerability-findings.md` | PUBLIC | |
| `docs/remediation.md` | PUBLIC | |
| `docs/retesting.md` | PUBLIC | |
| `docs/publishing-inventory.md` | PUBLIC | This file |
| `docs/traceability-matrix.md` | PUBLIC | Created for publishing |

## 3. report/

| Artifact | Classification | Notes |
|---|---|---|
| `report/CS-02_Final_Security_Assessment_Report.md` | PUBLIC | Verified: no passwords/tokens/secrets (grep audit) |

## 4. findings/

| Artifact | Classification | Notes |
|---|---|---|
| `findings/WEB-VUL-001`…`findings/WEB-VUL-005` (5 files) | PUBLIC | Tokens redacted at capture time |

## 5. remediation/

| Artifact | Classification | Notes |
|---|---|---|
| `remediation/WEB-VUL-001/` (before, remediation.md, after) | PUBLIC | |
| `remediation/WEB-VUL-002/` (before, remediation.md, after) | PUBLIC | |
| `remediation/WEB-VUL-003/` (before, remediation.md, after + PNG) | PUBLIC | PNG is a headless-browser viewport capture of the lab app |
| `remediation/safety-check-phase16.txt` | PUBLIC | |

## 6. evidence/

| Artifact | Classification | Notes |
|---|---|---|
| `evidence/evidence-index.csv` | PUBLIC (sanitized copy adds a `Publish Status` column) | |
| `evidence/findings/*.txt` (5) | PUBLIC | |
| `evidence/requests/*.txt` (2) | PUBLIC | `Authorization: Bearer [REDACTED-JWT]` |
| `evidence/responses/*` (6) | PUBLIC | Tokens redacted; API data is Juice Shop seed data |
| `evidence/reverification/*.txt` (5) | PUBLIC | |
| `evidence/scanner-results/*` (10) | SANITIZE BEFORE PUBLICATION | `LAB-001-environment.txt` contains hostname + LAN IPs; machine paths sanitized |
| `evidence/screenshots/*.png` (1) | PUBLIC | Headless-browser viewport capture of the app |
| `evidence/phase18-test-suite/*` (9) | SANITIZE BEFORE PUBLICATION | TAP logs contain absolute machine paths (`/home/asta/...`) |
| `evidence/logs/juice-shop-startup.log` | DO NOT PUBLISH | Raw runtime log (`*.log`); no unique analytical value |

## 7. Other project directories

| Artifact | Classification | Notes |
|---|---|---|
| `lab/` (OWASP Juice Shop v20.2.0 incl. node_modules, SQLite DB, logs, config) | DO NOT PUBLISH | Third-party application + runtime state; official release is publicly downloadable. Mitigation code changes are documented in `remediation/*/remediation.md` |
| `backend/` (**contains a real `.env`** + node_modules) | DO NOT PUBLISH | Unrelated scaffolding; `.env` must never leave the machine |
| `frontend/`, `database/`, `tests/` (empty/regression scaffolding) | DO NOT PUBLISH | Unrelated to the assessment deliverables |
| `scripts/` (lab lifecycle + recon scan) | PUBLIC | No secrets; portable (derive paths from script location) |
| `presentation/`, `viva/`, `reports/` (empty) | DO NOT PUBLISH | Empty; slides/viva intentionally not created |
| Root `.gitignore` | PUBLIC | |

## 8. Secret-scan record (step 4)

Scanned (excluding third-party `lab/node_modules`) for: `password`, `passwd`,
`secret`, `JWT_SECRET`, `API_KEY`, `TOKEN`, `ACCESS_TOKEN`, `REFRESH_TOKEN`,
`PRIVATE_KEY`, `DATABASE_URL`, `DB_PASSWORD`, `Authorization:`, `Bearer`,
`Cookie:`, `credential`, real JWTs (`eyJhbGciOi...`), `.env*` files.

Results:

| Pattern class | Result |
|---|---|
| `.env` files | 1 found: `backend/.env` → **DO NOT PUBLISH** (directory excluded) |
| Real JWTs (`eyJ...`) | Only inside third-party `lab/` test fixtures → excluded (directory not published) |
| `JWT_SECRET` / `DB_PASSWORD` / `DATABASE_URL` / `PRIVATE_KEY` / `ACCESS_TOKEN` in project artifacts | **0 files** |
| `API_KEY` | Only `ALCHEMY_API_KEY` *absence warnings* in test logs (no values) |
| `Bearer` in evidence | Only `[REDACTED-JWT]` placeholders (verified line-by-line) |
| Juice Shop seed-account password strings (values of the application's public seed accounts) in published md/txt/csv/sh | **0 files** |
| Report + PROJECT_STATUS secret grep (passwords/tokens) | Clean (automated audit, exit 0) |

**Secret scan result: PASS** for everything included in the public copy.

## 9. Sanitization record (steps 4–5)

Applied to the **public copy only** (originals preserved untouched locally):

| Pattern | Replacement | Reason |
|---|---|---|
| `/home/asta/Desktop/project bb` | `<PROJECT_ROOT>` | Machine-specific path + local username |
| `/home/asta` | `<HOME>` | Local username |
| `shoyo` (hostname) | `<HOSTNAME>` | Machine identity |
| `10.45.57.195`, `10.59.163.195` | `<LAN_IP>` | Unnecessary LAN addresses |
| `10.45.57.186` | `<LAN_GATEWAY>` | Unnecessary network detail |
| `10.45.57.0/24` | `<LAN_SUBNET>` | Unnecessary network detail |
| `127.0.0.1` / `localhost` | **kept** | Required to understand/reproduce the authorized target |

Not sanitized (necessary for authenticity/reproduction): Juice Shop seed data
emails (`*@juice-sh.op`), application version strings, HTTP headers, evidence
timestamps.

## 10. Data-quality repair (published copy + source)

Two legacy rows in `evidence/evidence-index.csv` (`RAW-004`, `RAW-018`)
contained unquoted commas inside the Description field, so they parsed with 11
columns instead of 9 (a pre-existing defect). They were repaired by merging the
split Description fragments back into one properly quoted field. **Values are
unchanged**; verification: local index parses as 45 rows × 9 columns, published
index as 45 rows × 10 columns, 0 malformed rows.
