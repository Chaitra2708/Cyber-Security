# CS-02 — Individual Contribution Record

The work below was carried out end-to-end on one machine. The split is by **phase
ownership**, which is how the project was actually executed. Every student must be able
to explain the **whole** project, not only their own section — see the comprehension
checklist at the end.

---

## Student 1 — Reconnaissance + Application Mapping

**Owned:** Phases 3–4 (environment), 11–13 (lab architecture, reconnaissance,
application mapping).

**What was done**
- Located the real Juice Shop install after establishing that the workspace root was a
  partial source dump with no `node_modules`, `build/`, `routes/`, `models/` or `lib/`.
- Diagnosed the initial `404` as a stale baked absolute path
  (`/home/asta/Desktop/project bb/...`) held by a long-running process, rather than a
  missing build — fixed by restarting from the correct directory. Deliberately did **not**
  modify the application to fit port 5500.
- Port/service reconnaissance (`connect_ex` scan) and HTTP technology fingerprinting.
- Built the route and attack-surface map; probed each route live; registered a customer
  account to observe authenticated behaviour.

**Evidence owned:** `evidence/recon/`, `evidence/scanner-results/`,
`docs/application-map.md`, `docs/architecture-final.md`.

**Key numbers:** Juice Shop 20.2.0 · Express 4.22.2 · Node v22.23.3 · SQLite.

---

## Student 2 — Vulnerability Assessment + Controlled Validation

**Owned:** Phases 14–16 (assessment, findings, controlled validation).

**What was done**
- Assessed ten OWASP-relevant areas, recording *not-confirmed* areas honestly rather than
  claiming coverage.
- Raised ten findings (WEB-VUL-001…010) with component, endpoint, description, evidence,
  impact, severity + justification, and recommendation.
- Validated each with a controlled test: boolean-differential SQLi; a three-token
  access-control matrix; base64 JWT decoding; content-level key inspection.
- **Declined to claim** XSS (not reproduced) and privilege escalation (`PATCH` unrouted).
- Scored risk on four factors with written reasoning; documented the 008 → 007 → 006
  attack chain that determines remediation order.

**Evidence owned:** `findings/WEB-VUL-0*/finding.md`, `evidence/findings/V-0*.txt`,
`docs/risk-analysis.md`, `findings/risk-register.csv`.

---

## Student 3 — Remediation + Re-Testing

**Owned:** Phases 19–21 (risk-driven remediation, re-testing) and closeout.

**What was done**
- Preserved the vulnerable baseline (MD5-verified unmodified, still running on :3000) and
  created a remediation copy on :3001 so before/after is a live side-by-side test.
- Implemented REMED-001 (CORS allow-list), REMED-002 (removed `/encryptionkeys` routes)
  and, during closeout, REMED-002b (explicit 404).
- **Caught its own fixes being wrong twice.** The CORS allow-list passed as a *string* is
  echoed unvalidated by cors@2.8.6; passed as a *function* it broke the preflight into a
  500. Only an *array* is correct. Established by reading `node_modules/cors/lib/index.js`.
- Found that REMED-002 returned HTTP 200 via the SPA catch-all rather than 404, judged it
  a genuine (if minor) routing defect, and repaired it instead of documenting around it.
- Re-tested all five remediated findings; ran regression checks (93 SPA tiles, login,
  search, `/api/Users` 401).

**Evidence owned:** `evidence/remediation/`, `findings/REMEDIATION_REGISTER.md`,
`docs/remediation.md`, `docs/retesting.md`.

---

## Whole-project comprehension checklist

Every student should be able to answer all of these without notes:

| # | Question | Where the answer lives |
|---|---|---|
| 1 | What is the target, and how do we prove it is the real app and not a listing? | `docs/final-state-snapshot.txt`, `check-lab.sh` |
| 2 | Why does the lab run on loopback only? | `docs/architecture-final.md` |
| 3 | Which three tools were actually available, and which were not? | `docs/final-state-snapshot.txt` limitations |
| 4 | How is a finding promoted from a candidate? | `findings/*/finding.md` §17 evidence IDs |
| 5 | Why is severity not the same number as overall risk? | `docs/risk-analysis.md` §2 note |
| 6 | What distinguishes a *recommended* control from an *implemented* one? | `findings/REMEDIATION_REGISTER.md` |
| 7 | How do we prove the baseline was never modified? | `evidence/remediation/REMED-baseline-integrity.txt` |
| 8 | Why must re-test compare content, not just status codes? | `docs/retesting.md` RETEST-002 |
| 9 | Which findings are still open and why were they not fixed? | `findings/REMEDIATION_REGISTER.md` |
| 10 | What is the single most important lesson of the project? | `docs/retesting.md` — a change is not proven until the identical test is replayed side by side |