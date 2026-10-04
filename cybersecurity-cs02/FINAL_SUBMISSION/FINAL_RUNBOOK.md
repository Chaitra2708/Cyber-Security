# CS-02 — Final Runbook

**Repository:** https://github.com/Chaitra2708/Cyber-Security
**Branch:** `main` · **Verified commit:** `553606e`

> **Authorized local lab only.** OWASP Juice Shop is intentionally vulnerable. It binds to
> `127.0.0.1` and must never be published to GitHub Pages, Vercel, Render, Railway, a public
> VM, a tunnel or public DNS. GitHub is the **source repository**, not the runtime host.

---

## 1. Prerequisites

| Tool | Version | Note |
|---|---|---|
| Git | any | `git --version` |
| Node | **22** (tested v22.23.3) | project declares `engines.node = "22"`; `nvm use 22` |
| npm | 10.x | bundled with Node 22 |
| Network | needed once | to fetch the official Juice Shop distribution (~95 MB) |

Disk: ~1 GB free (distribution + `node_modules`).

## 2. Clone

```bash
git clone https://github.com/Chaitra2708/Cyber-Security.git
cd Cyber-Security
```

## 3. Enter the project directory

```bash
cd cybersecurity-cs02
```

## 4–7. Deploy, start both instances, verify

**Everything in one command** (downloads + verifies the official OWASP Juice Shop 20.2.0
distribution, installs dependencies if missing, starts the baseline, waits for HTTP and
verifies the response is the real app):

```bash
bash scripts/deploy-from-github.sh          # baseline  -> http://127.0.0.1:3000/
PORT=3001 bash scripts/deploy-from-github.sh # remediation -> http://127.0.0.1:3001/
```

Expected: `DEPLOYMENT STATUS: PASS`.

<details>
<summary>Equivalent manual commands (the ACTUAL ones discovered from the repository)</summary>

```bash
# baseline
cd cybersecurity-cs02/lab/juice-shop_20.2.0
PORT=3000 node build/app

# remediation (separate shell)
cd cybersecurity-cs02/lab/juice-shop_20.2.0-remediated
PORT=3001 node build/app
```
</details>

## 8. Open the browser

| Instance | URL | Expect |
|---|---|---|
| Baseline | <http://127.0.0.1:3000/> | real Juice Shop UI, 93 product tiles |
| Remediation | <http://127.0.0.1:3001/> | same UI, fixes applied |

A correct page has `<title>OWASP Juice Shop</title>` and shows real products
(*Apple Juice*, *Banana Juice*, *Basil Smoothie*). If you see `Index of /`, a directory
listing, `package.json`, a README or a blank page, the wrong thing is being served.

## 9. Health check

```bash
bash scripts/check-lab.sh        # expect: exit 0, "LAB STATUS: PASS" (10/10)
bash scripts/check-git-deployment.sh   # expect: "STATUS : PASS"
```

## 10. Stop

```bash
bash scripts/stop-lab.sh         # stops both instances
```

To stop only the remediation instance (its `PORT` is an environment variable and is **not**
in the process command line, so `pkill -f "PORT=3001"` does not work):

```bash
for p in $(pgrep -x node); do
  [ "$(readlink -f /proc/$p/cwd)" = "$PWD/lab/juice-shop_20.2.0-remediated" ] && kill "$p"
done
```

## 11. Regenerate the finding evidence

```bash
bash scripts/capture-verification-evidence.sh
```

Remediated findings are verified on `:3001` with the vulnerable `:3000` shown side by side;
open findings are verified on `:3000`, where they still reproduce.

---

## Expected assessment state

| Item | Value |
|---|---|
| Findings | **10** — WEB-VUL-001 … WEB-VUL-010 |
| Remediated + re-tested | **5** — 001, 002, 003, 008, 010 |
| Open (recommended only) | **5** — 004, 005, 006, 007, 009 |
| Evidence index | 78 rows, 0 broken paths, 0 duplicate IDs |
| Submission package | `cybersecurity-cs02/CS-02_FINAL_SUBMISSION.zip` |

Do **not** remediate the remaining five findings to make the numbers look better.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Node 22 is required` | `nvm use 22` |
| `download failed (no network?)` | download the archive manually to `cybersecurity-cs02/lab/juice-shop-20.2.0_node22_linux_x64.tgz` and re-run |
| `archive checksum mismatch` | archive deleted automatically; re-run with a good connection |
| Port already in use | `bash scripts/stop-lab.sh` first |
| Page shows a directory listing | something else is bound to the port; stop it and use `node build/app` |
| `BROWSER: BLOCKED` | no Chrome/Chromium on the host; HTTP checks still apply |