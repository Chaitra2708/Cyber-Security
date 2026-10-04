# CS-02 — FINAL SUBMISSION CHECKLIST

Verified at closeout on 2026-10-04. Every item marked ✅ was checked against a file
that exists on disk or a command that was actually run — not asserted from memory.

| # | Requirement | Status | Verified by |
|---|---|---|---|
| 1 | Working web-security laboratory | ✅ | `scripts/check-lab.sh` → `LAB STATUS: PASS` (10/10) |
| 2 | Juice Shop deployed | ✅ | `:3000` HTTP 200, `<title>OWASP Juice Shop</title>`, 93 SPA tiles |
| 3 | Network architecture documented | ✅ | `docs/architecture-final.md` |
| 4 | IP addressing documented | ✅ | host `10.59.163.195/24`, gw `10.59.163.213`, app loopback-only |
| 5 | Web-server identification completed | ✅ | `evidence/recon/RECON-002-technology.txt` (Express 4.22.2, Node v22.23.3) |
| 6 | Technology identification completed | ✅ | same file; `X-Powered-By` confirmed absent |
| 7 | Application mapping completed | ✅ | `docs/application-map.md`, route inventory probed live |
| 8 | Security assessment completed | ✅ | `docs/security-assessment.md` (10 areas; not-confirmed areas recorded) |
| 9 | **10 findings documented** | ✅ | `findings/WEB-VUL-001…010/finding.md`, 17 sections each |
| 10 | At least 2 controlled validations completed | ✅ | 10 validations, `evidence/findings/V-001…V-010` |
| 11 | Risk analysis completed | ✅ | `docs/risk-analysis.md`, `findings/risk-register.csv` (10 rows) |
| 12 | Authentication / access-control assessment completed | ✅ | `V-001`, `V-002`, `V-006`, `V-007` |
| 13 | Security configuration assessment completed | ✅ | `V-003`, `V-004`, `V-009`, `V-010` |
| 14 | Remediation recommendations completed | ✅ | `findings/REMEDIATION_REGISTER.md` (recommended vs implemented separated) |
| 15 | **5 findings remediated and re-tested** | ✅ | WEB-VUL-001, 002, 003, 008, 010 |
| 16 | Before/after comparison completed | ✅ | `evidence/remediation/REMED-before.txt` / `REMED-after.txt` (live side-by-side) |
| 17 | Evidence index complete | ✅ | 78 rows, 0 ragged, 0 broken paths, 0 duplicate IDs |
| 18 | Technical report complete | ✅ | 10 chapters + references + appendix |
| 19 | Architecture diagram complete | ✅ | `docs/architecture-final.md` (observed values only) |
| 20 | Presentation complete | ✅ | `presentation/CS-02_Presentation.md`, 15 slides |
| 21 | Practical demonstration prepared | ✅ | `docs/practical-demonstration.md`, 18 steps, commands spot-checked live |
| 22 | Individual contribution prepared | ✅ | `docs/individual-contribution.md` (3 students + comprehension checklist) |
| 23 | Viva prepared | ✅ | `viva/CS-02_Viva_Preparation.md`, 24 questions |
| 24 | Traceability complete | ✅ | `docs/traceability.md`, 26 requirements mapped |
| 25 | Baseline preserved unmodified | ✅ | Verified byte-for-byte against the distribution archive (MD5 `b9c1827299595e264e0bd7a9ccb470a7`); baseline still returns `ACAO: *` |
| 26 | Evidence free of secrets | ✅ | 0 JWT tokens, 0 plaintext passwords, 0 real key bodies |

## Submission honesty statement

- **10 findings identified.**
- **5 findings remediated and re-tested:** WEB-VUL-001, 002, 003, 008, 010.
- **5 findings remain OPEN with recommendations only:** WEB-VUL-004, 005, 006, 007, 009.
- **No open finding is presented as fixed.** Reasons for not remediating them are
  recorded per finding in `findings/REMEDIATION_REGISTER.md`.
- **No scanner severity is quoted anywhere.** nmap, Nikto, ZAP, WhatWeb and Nuclei are not
  installed and `sudo` requires a password. Every finding was validated with `curl`,
  Python `socket`/`sqlite3`, headless Chrome, and direct source analysis.
- **No fabricated evidence.** All screenshots are original headless-Chrome captures of
  this laboratory; no internet screenshots are used; no missing evidence was back-filled
  with invented artifacts.