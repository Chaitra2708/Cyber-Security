# CS-02 — Web Application Security Assessment Using OWASP Methodology

**Application under test:** OWASP Juice Shop 20.2.0
**Laboratory:** Authorised isolated local security laboratory (single host, loopback-only)

---

## Quick start

```bash
cd /home/asta/Desktop/Cyber-Security/cybersecurity-cs02

# start the vulnerable baseline
bash scripts/start-lab.sh

# verify lab health (expect: LAB STATUS: PASS, 10/10)
bash scripts/check-lab.sh

# stop
bash scripts/stop-lab.sh
```

Requires **Node 22** (`engines.node = "22"`). The scripts select it via `nvm` automatically.

## Application URL

| Instance | URL | State |
|---|---|---|
| Vulnerable **baseline** | `http://127.0.0.1:3000` | unmodified, intentionally insecure |
| **Remediation** build | `http://127.0.0.1:3001` | 5 fixes applied |

Both bind **loopback only**; the LAN address `10.59.163.195` is verified unreachable.

Baseline integrity: verified byte-for-byte against the original distribution archive
(`lab/juice-shop-20.2.0_node22_linux_x64.tgz`, MD5 `b9c1827299595e264e0bd7a9ccb470a7`,
matching its `lab/juice.tgz.md5` sidecar), apart from a documented loopback-only bind used
for laboratory isolation. See `03_Evidence/remediation/REMED-baseline-integrity.txt`.

---

## Results at a glance

| Item | Value |
|---|---|
| **Findings** | **10** (WEB-VUL-001 … WEB-VUL-010) |
| Severity spread | 1 Critical · 5 High · 3 Medium · 1 Low |
| **Remediated and re-tested** | **5** — 001, 002, 003, 008, 010 |
| **Open** | **5** — 004, 005, 006, 007, 009 (recommendations only) |
| Controlled validations | 10 |
| Evidence index | 78 rows · 0 broken paths · 0 duplicate IDs |
| Lab health | `LAB STATUS: PASS` (10/10) |

**This assessment is not clean and is not presented as clean.** Five findings remain
open; the reasons are recorded per finding in `04_Findings/REMEDIATION_REGISTER.md`.

---

## Package contents

| Folder | Contents |
|---|---|
| `01_Report/` | Final technical report (10 chapters, references, appendix) |
| `02_Presentation/` | 15-slide presentation |
| `03_Evidence/` | Evidence index, validation files, recon, remediation, logs, screenshots |
| `04_Findings/` | All 10 findings (17 sections each) + remediation register |
| `05_Risk_Analysis/` | Risk analysis and risk register (10 rows) |
| `06_Remediation/` | Remediation plan, recommended vs implemented |
| `07_Retesting/` | Before/after re-testing record |
| `08_Laboratory/` | Architecture, final state snapshot, lab scripts |
| `09_Documentation/` | Traceability, demo checklist, app map, security assessment, README |
| `10_Viva/` | Viva preparation (25 spec questions + extras) |
| `09_Documentation/github-deployment.md` | Git-sourced deployment guide (local lab only) |

---

## Key documents

| Purpose | Path |
|---|---|
| Final report | `01_Report/CS-02_Final_Security_Assessment_Report.md` |
| Presentation | `02_Presentation/CS-02_Presentation.md` |
| Evidence index | `03_Evidence/evidence-index.csv` |
| Remediation register | `04_Findings/REMEDIATION_REGISTER.md` |
| Risk analysis | `05_Risk_Analysis/risk-analysis.md` |
| Re-testing record | `07_Retesting/retesting.md` |
| Architecture | `08_Laboratory/architecture-final.md` |
| Demo checklist | `09_Documentation/practical-demo-checklist.md` |
| Traceability | `09_Documentation/traceability.md` |
| Viva | `10_Viva/viva.md` |

---

## Honest limitations

1. **No security scanners were executed.** nmap, Nikto, ZAP, WhatWeb, Nuclei and Burp are
   **not installed**, and `sudo` requires a password, so they could not be installed
   non-interactively. All findings were validated with `curl`, Python `socket`/`sqlite3`,
   headless Chrome and direct source analysis. **No scanner output or scanner severity is
   presented anywhere in this project.**
2. **TypeScript was not recompiled.** The Juice Shop distribution ships without a
   `tsconfig.json`, so `npm run build:server` (`tsc`) cannot run. Remediation was applied
   to `build/*.js` (the runtime artefact) and mirrored in `*.ts`; the TypeScript was not
   type-checked.
3. **XSS was not reproduced.** Payloads did not reflect on the endpoints tested and the
   CSP restricts `script-src` without `'unsafe-inline'`. It is therefore **not** reported
   as a finding.
4. **Privilege escalation was not demonstrated.** `PATCH /api/Users/:id` is unrouted, so
   WEB-VUL-006 is scoped as unauthorized **read** access only, and rated High rather than
   Critical.
5. **Five findings remain open** (004, 005, 006, 007, 009), each with a documented reason:
   authorization-middleware blast radius (006), a coupled JWT + password-hash migration
   (007), a challenge-relevant query path (009), and a shared access boundary (004, 005).
   They were **deliberately not over-remediated**.
6. **Excluded from the package:** `node_modules`, the Juice Shop install, build caches,
   the previous session's unused `backend/`, `frontend/` and `database/` directories (an
   unrelated custom app, not referenced by any lab script), and `PROJECT_STATUS.md`
   (a **superseded** working log of an earlier phase — it is internally inconsistent,
   claiming both "2 of 5" and "3 findings" remediated, and its counts are obsolete. It
   remains in the project directory for history, marked with a SUPERSEDED banner, and is
   deliberately **not** part of the submission because it would contradict this README).
   Empty directories `tests/` and `reports/` are also excluded.

---

## Methodological note

The most important outcome of this project is not a finding but a lesson: **a change is
not proven until the identical test is replayed against both the vulnerable baseline and
the fixed build, side by side.** That discipline is what caught two wrong
implementations of the CORS remediation (a string `origin` is echoed unvalidated by
cors@2.8.6; a falsy callback breaks the preflight into a 500) and a remediation that
returned HTTP 200 via the SPA catch-all instead of a 404.