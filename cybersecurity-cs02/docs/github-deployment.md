# CS-02 — GitHub-Sourced Deployment

> ## ⚠️ AUTHORIZED LOCAL LAB ONLY
>
> OWASP Juice Shop is **intentionally vulnerable**. This deployment is **local and
> isolated** and binds to `127.0.0.1` only.
>
> **Never** publish it to GitHub Pages, Render, Railway, Vercel, a public cloud VM, a
> public tunnel or public DNS. GitHub is used as the **source repository**, not as a
> runtime host. There is **no public URL** for this application, by design.

---

## 1. Repository

| Field | Value |
|---|---|
| **Repository** | https://github.com/Chaitra2708/Cyber-Security |
| **Branch** | `main` |
| **Commit (verified)** | `cf51be0e3191970c3134d8b7ca63372dae6ee1a7` |
| **Local clone** | `/home/asta/Desktop/Cyber-Security` |

## 2. How the repository relates to the application

This trips people up, so it is worth stating plainly.

The repository has **two distinct parts**, and only one of them runs:

```
Cyber-Security/                              <- git repository root
├── server.ts, login.ts, basket.ts, …        Juice Shop 20.2.0 TypeScript SOURCES
├── package.json                             (engines.node=22, start="node build/app")
│
│   These sources are INCOMPLETE as a checkout: there is no tsconfig.json,
│   no build/, no node_modules and no frontend bundle, so this directory is
│   NOT runnable and `npm run build:server` (tsc) cannot run.
│   It must NOT be served as a website and must NOT become a directory listing.
│
├── CS-02-Web-Application-Security-Assessment/   superseded near-duplicate (unused)
│
└── cybersecurity-cs02/                      <- the CS-02 assessment project
    ├── lab/juice-shop-20.2.0_node22_linux_x64.tgz   official distribution archive
    ├── lab/juice.tgz.md5                            its checksum
    ├── lab/juice-shop_20.2.0/                        THE REAL RUNNABLE APPLICATION (:3000)
    ├── lab/juice-shop_20.2.0-remediated/             remediated copy (:3001)
    ├── scripts/    findings/  evidence/  docs/  report/  …
    └── CS-02_FINAL_SUBMISSION.zip
```

**The deployment target is the genuine OWASP Juice Shop application**, served by the
application's own Express server from `cybersecurity-cs02/lab/juice-shop_20.2.0` using the
project's own start command `node build/app`. It is never the project root, a README, a
directory listing or a `file:///` path.

Two instances run side by side so that "before" and "after" can be compared live:

| Instance | Port | Purpose |
|---|---|---|
| `lab/juice-shop_20.2.0` | 3000 | vulnerable baseline — reproduces the findings |
| `lab/juice-shop_20.2.0-remediated` | 3001 | remediated copy — demonstrates the fixes |

## 3. Obtain the project locally

```bash
git clone https://github.com/Chaitra2708/Cyber-Security.git
cd Cyber-Security
```

Requirements: **Git**, **Node 22** (the project declares `engines.node = "22"`), and
~100 MB of disk for the Juice Shop distribution plus its dependencies.

## 4. Start the application

One command performs the whole flow — verify tools, verify the repository, fetch,
prepare dependencies, start Juice Shop, wait for HTTP readiness and verify the response:

```bash
bash cybersecurity-cs02/scripts/deploy-from-github.sh
```

Expected ending:

```
 URL              : http://127.0.0.1:3000/
 DEPLOYMENT STATUS: PASS
```

The script is **non-destructive by design**: it never runs `git reset --hard`,
`git clean`, `git checkout .` or `git push`, and it never edits the vulnerable baseline.

<details>
<summary>Equivalent manual commands</summary>

```bash
cd cybersecurity-cs02/lab/juice-shop_20.2.0
PORT=3000 node build/app
```
</details>

## 5. Actual local URL

| Instance | URL |
|---|---|
| Vulnerable baseline | **http://127.0.0.1:3000/** |
| Remediated copy | http://127.0.0.1:3001/ |

A correct response has `<title>OWASP Juice Shop</title>`, contains `app-root`, is roughly
9 KB, and the REST API answers:

```bash
curl -s http://127.0.0.1:3000/rest/products/search?q=apple   # -> 3 products
```

A **wrong** response — any of these means you are serving the wrong thing — is a
directory listing (`Index of /`), a raw `package.json`/`README.md`/`server.ts`, or a blank
page.

## 6. Verify the deployment

```bash
bash cybersecurity-cs02/scripts/check-git-deployment.sh
```

It prints `REPOSITORY`, `BRANCH`, `COMMIT`, `WORKTREE`, `NODE`, `NPM`, `APPLICATION`,
`PORT`, `URL`, `HTTP`, `BROWSER` and `STATUS` (`PASS` / `FAIL` / `BLOCKED`). Every value
is observed at runtime; a field that cannot be observed is reported `BLOCKED`, never
guessed. Exit codes: `0` PASS, `1` FAIL, `2` BLOCKED.

## 7. Check the lab

```bash
bash cybersecurity-cs02/scripts/check-lab.sh      # expect: LAB STATUS: PASS  (10/10)
```

This verifies both instances, the ports, HTTP, that the served page is Juice Shop (not a
directory listing), the frontend bundle, the REST API, the SQLite store and that the LAN
address `10.59.163.195` **cannot** reach the application (loopback isolation).

## 8. Regenerate the finding evidence

```bash
bash cybersecurity-cs02/scripts/capture-verification-evidence.sh
```

Re-validates all ten findings against the running lab: remediated findings on `:3001`
with the vulnerable `:3000` shown side by side, open findings on `:3000`.

## 9. Stop the application

```bash
bash cybersecurity-cs02/scripts/stop-lab.sh
```

To stop only the remediated instance, select it by working directory — its `PORT` is an
environment variable and does **not** appear in the process command line, so
`pkill -f "PORT=3001"` does **not** work:

```bash
pkill -f 'build/app' # stops both; to target one, find its pid first:
for p in $(pgrep -x node); do
  [ "$(readlink -f /proc/$p/cwd)" = "$PWD/lab/juice-shop_20.2.0-remediated" ] && kill "$p"
done
```

## 10. Safety notes

- The application binds **loopback only**. `scripts/check-lab.sh` fails if the LAN address
  becomes reachable.
- The vulnerable baseline under `lab/juice-shop_20.2.0` is verified byte-for-byte against
  the distribution archive (MD5 `b9c1827299595e264e0bd7a9ccb470a7`, matching
  `lab/juice.tgz.md5`), apart from a documented loopback-only bind used for isolation.
  Do not "fix" anything in it — that would destroy the before/after evidence.
- Key material lives at `lab/juice-shop_20.2.0/ctf.key`,
  `lab/juice-shop_20.2.0/encryptionkeys/premium.key` and
  `lab/juice-shop_20.2.0/encryptionkeys/jwt.pub`. These are **excluded from the submission
  ZIP** and must never be committed or shared.
- The evidence files contain the application seed account
  `admin@juice-sh.op` / `admin123`, which is OWASP Juice Shop's own published default and
  is reproduced only as proof for finding WEB-VUL-007. No lab-generated secret, session
  token or private key appears anywhere in the submission.

## 11. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `ERROR: Node 22 is required` | wrong Node active | `nvm use 22` |
| `origin not set` | clone made without origin | script adds it automatically |
| `fetch FAILED` | host offline | script continues on the local checkout |
| `application not extracted` | lab install missing | script extracts it and verifies the MD5 |
| HTTP 200 but "not recognised as Juice Shop" | a static server is answering | stop it; use port 3000 via `node build/app` |
| `BROWSER: BLOCKED` | no Chrome/Chromium on host | install one; HTTP checks still apply |
| Port already in use | another instance running | `bash scripts/stop-lab.sh` first |