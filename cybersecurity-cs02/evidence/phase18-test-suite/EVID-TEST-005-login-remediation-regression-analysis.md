# EVID-TEST-005 — Login Remediation Regression Analysis (Test-Suite Verification)

**Phase classification:** Phase 18 (pre-report verification) — this verification is
performed as the first task of the Phase 18 workflow and supports Chapters 8/9 of
the final report. No new project phase was invented.

---

## 1. Test record (per Task 1.2)

```text
Test purpose:      Verify that the login remediation does not break existing
                   application tests.
Target/application: OWASP Juice Shop v20.2.0 (local lab, http://127.0.0.1:3000)
Remediation being verified: WEB-VUL-001 — SQL injection authentication bypass
                   (parameterised query via Sequelize named replacements,
                   implemented Phase 16, 2026-10-04; retested FIXED Phase 17)
Working directory: lab/juice-shop_20.2.0/
```

### Commands — determined from the actual project configuration (not invented)

The project's documented test commands (from `package.json`) are:

```text
npm run test:server  →  node --import ./test/server/helpers/test-env.mjs --import tsx --test --test-force-exit "test/server/**/*.unit.test.ts"
npm run test:api     →  node --import ./test/api/helpers/test-env.mjs --import tsx --test --test-force-exit "test/api/**/*.test.ts"
npm test             →  test:frontend && test:server && test:api
```

**These documented commands cannot run in this packaged release.** Executed as-is
they fail immediately with `Could not find '.../test/server/**/*.unit.test.ts'`
(and the same for `test/api/...`): the official `juice-shop-20.2.0_node22_linux_x64.tgz`
package ships the **compiled** tests under `build/test/` but not the TypeScript
`test/` sources or `test/*/helpers/test-env.mjs`. (Verified by executing both
documented commands; output observed: `Could not find '...test/server/**/*.unit.test.ts'`.)

Commands actually used — the *same* Node.js built-in test runner the project
uses, pointed at the compiled test artifacts that exist in this package
(run under Node **v22.23.3** via nvm, matching the package's supported range 22–26;
`test:frontend`/Vitest was not run — `frontend` unit-test toolchain is out of scope
for the login change, which is backend-only):

```text
node --test --test-force-exit build/test/server/*.unit.test.js     (server unit suite)
node --test --test-force-exit build/test/api/login.test.js         (login API suite)
node --test --test-force-exit build/test/api/*.test.js             (full API suite)
```

No test file, assertion, or configuration was modified at any point.

---

## 2. Run records (per Task 1.3)

| Run | Suite | Command (cwd = lab/juice-shop_20.2.0) | Finished (mtime) | Tests | Pass | Fail | Cancelled | Skipped | Exit |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Server unit (lab running) | `node --test --test-force-exit build/test/server/*.unit.test.js` | 2026-10-04T16:04 | 415 | 392 | 4 | 17 | 2 | 1 |
| 2 | Server unit (lab stopped) | same | 2026-10-04T16:06 | 415 | 410 | 3 | 0 | 2 | 1 |
| 3 | Login API | `node --test --test-force-exit build/test/api/login.test.js` | 2026-10-04T16:07 | 18 | 13 | 5 | 0 | 0 | 1 |
| 4 | Full API suite — **mitigated code** | `node --test --test-force-exit build/test/api/*.test.js` | 2026-10-04T16:10 | 537 | 486 | 38 | 6 | 7 | 1 |
| 5 | Full API suite — **control, original code** | same, with `build/server.js` restored from `build/server.js.orig` and the original login query temporarily restored | 2026-10-04T16:14 | 537 | 492 | 33 | 5 | 7 | 1 |

Raw output (unmodified):
- `evidence/phase18-test-suite/EVID-TEST-001-server-unit-tests.txt`
- `evidence/phase18-test-suite/EVID-TEST-001b-server-unit-tests-lab-stopped.txt`
- `evidence/phase18-test-suite/EVID-TEST-002-login-api-tests.txt`
- `evidence/phase18-test-suite/EVID-TEST-003-api-suite-mitigated-code.txt`
- `evidence/phase18-test-suite/EVID-TEST-004-api-suite-control-original-code.txt`

After run 5 the mitigated files were restored and verified byte-identical
(`md5sum -c` against pre-control backups: both `OK`), the lab was restarted, and
live behaviour re-confirmed: SQLi payload → 401, CSP present, legitimate login → 200.

---

## 3. Failure analysis (per Task 1.4)

### 3.1 Failures caused by the mitigations (exist only in the mitigated run)

Exactly **6 subtests fail only when our code is active, and all 6 pass on the
original code** (name-by-name diff of run 4 vs run 5: 6 unique to mitigated,
0 unique to control, 38 identical failures in both):

| Test | Expected (test's assertion) | Actual (mitigated) | Related to login remediation | Evidence |
|---|---|---|---|---|
| `POST login with WHERE-clause disabling SQL injection attack` | HTTP 200 (injection logs the attacker in) | HTTP 401 | **YES** — this is the fixed vulnerability | EVID-TEST-002 vs EVID-TEST-004 (passes on original code) |
| `POST login with known email "admin@juice-sh.op" in SQL injection attack` | HTTP 200 | HTTP 401 | **YES** | same |
| `POST login with known email "jim@juice-sh.op" in SQL injection attack` | HTTP 200 | HTTP 401 | **YES** | same |
| `POST login with known email "bender@juice-sh.op" in SQL injection attack` | HTTP 200 | HTTP 401 | **YES** | same |
| `POST login with non-existing email ... via UNION SELECT injection attack` | HTTP 200 | HTTP 401 | **YES** | same |
| `response must not contain XSS protection header` (http.test.js) | header `undefined` (absent) | `'1; mode=block'` | **NO for login; YES for WEB-VUL-003** — the test asserts the header hardening gap that finding WEB-VUL-003 documents | EVID-TEST-003 vs EVID-TEST-004 (passes on original code) |

These 6 upstream tests encode the **intentionally vulnerable behaviour** the
project set out to fix (Juice Shop ships deliberately insecure; its suite asserts
that). They fail *because the remediation works*, not because functionality broke.
Per instructions: tests were **not** modified, **not** disabled, and the
remediation was **not** reverted.

### 3.2 Pre-existing / environmental failures (identical in both runs — 38 subtests)

| Group (failing tests) | Cause | Related to login remediation | Evidence |
|---|---|---|---|
| `/rest/chat` (10 tests) | `Chatbot stream error: LLM API is not reachable` — no LLM backend on localhost:11434 in this lab | **NO** | same failures in EVID-TEST-004 (original code) |
| `/file-upload` (14), `/profile/image/*`, `/rest/memories`, `/rest/user/data-export`, `/metrics` file-upload (multipart tests) | `Aborted` multipart transfers — reproduce identically with the original code (environment/package related) | **NO** | identical failure names in EVID-TEST-004 |
| Server unit: `antiCheat` | `ENOENT .../infrastructure/docker-compose.yml` — `infrastructure/` not shipped in the release tarball | **NO** | EVID-TEST-001/001b |
| Server unit: `blueprint` | `Could not read EXIF data from frontend/src/assets/.../3d_keychain.jpg` — frontend sources not shipped | **NO** | EVID-TEST-001/001b |
| Server unit: `challengeTag` (file crash) | `ENOENT build/data/static/challenges.yml` — not shipped | **NO** | EVID-TEST-001/001b |
| Server unit run 1 only: `preconditionValidation` + 17 cancelled | `EADDRINUSE :::3000` — the running lab instance occupied the test's port; disappears when lab is stopped | **NO** | EVID-TEST-001 (4 fail) vs EVID-TEST-001b (3 fail, 0 cancelled) |

### 3.3 Verdict

```text
Login remediation regression check: FAIL
```

Stated precisely: 5 of 18 login API tests fail, **all 5 being the tests that
assert the SQL-injection authentication bypass succeeds** — i.e. the failures are
the intended, control-proven effect of the WEB-VUL-001 remediation.
**Functional regressions: 0** — all 13 functional login tests pass (new user,
invalid credentials, no credentials, all seeded accounts, 2FA flow,
login-IP handling), and the same identity holds for the full suite: the only
differences vs. original code are the 6 vulnerability-assertion tests above.

Broader-suite regression picture (full API suite):

```text
Original code (control):  537 tests, 492 pass, 33 fail, 5 cancelled, 7 skipped
Mitigated code:           537 tests, 486 pass, 38 fail, 6 cancelled, 7 skipped
Delta:                    exactly the 6 tests that assert the fixed
                          vulnerabilities (5× SQLi bypass, 1× missing XSS header);
                          0 other behavioural difference
Server unit suite:        415 tests, 410 pass, 3 fail (all 3 = files absent from
                          the release package), 0 login-related failures
```

No test was modified, disabled, deleted, or reworded; no assertion was weakened;
no suppression of any kind was added.

---

## 4. Limitations

- `test:frontend` (Vitest) was not executed; the login change is backend-only and
  frontend test tooling was out of scope. Recorded as *not run*, not as *passing*.
- The control run used `build/server.js.orig` as the original baseline; it differs
  from the pristine package only by the pre-existing loopback-only `listen` binding
  from an earlier project phase (a documented, unrelated hardening).
- The documented `npm run test:server` / `test:api` commands cannot run in this
  release (missing `test/` sources); the compiled equivalents were used instead.
- Multipart-upload (`Aborted`) failures were attributed to the environment via the
  control run, not root-caused further; they are identical with and without our code.
