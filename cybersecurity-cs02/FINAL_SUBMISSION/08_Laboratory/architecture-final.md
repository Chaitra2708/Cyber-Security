# CS-02 — Final Laboratory Architecture

All values below are **observed on the actual machine**, not a textbook diagram. No VM
or IP address has been invented.

## Diagram

```
  ┌──────────────────────────────────────────────────────────────┐
  │  TESTING MACHINE  (single host — no separate VM was used)    │
  │  Hostname : shoyo                                              │
  │  OS       : Linux Mint 22.3 · kernel 6.17.0-35-generic x86_64  │
  │  LAN IP   : 10.59.163.195/24   (wlo1)                          │
  │  Gateway  : 10.59.163.213                                      │
  │  Loopback : 127.0.0.1                                           │
  │                                                              │
  │  Operators: curl · python3 (socket / sqlite3) ·                │
  │             Google Chrome --headless (render + screenshot)   │
  └───────────────────────────┬──────────────────────────────────┘
                              │
                              │  Authorised local HTTP traffic ONLY
                              │  (no public or third-party target was
                              │   contacted at any point in this project)
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  WEB / APPLICATION SERVER                                     │
  │  Runtime : Node.js v22.23.3   (engines.node = "22")           │
  │  Framework: Express 4.22.2     Frontend: Angular SPA (bundled) │
  │  Storage : SQLite via Sequelize → data/juiceshop.sqlite       │
  │  Binds   : 127.0.0.1 ONLY (loopback)                           │
  │                                                              │
  │  ┌────────────────────────────────────────────────────────┐  │
  │  │  OWASP JUICE SHOP 20.2.0                               │  │
  │  │  (official node22_linux_x64 distribution)               │  │
  │  │                                                        │  │
  │  │  ├── BASELINE (vulnerable)                             │  │
  │  │  │     lab/juice-shop_20.2.0            port 3000      │  │
  │  │  │     PRISTINE · server.ts md5 ba10fa21169fa8ba... │  │
  │  │  │     serves BEFORE evidence and stays exploitable    │  │
  │  │  │                                                      │  │
  │  │  └── REMEDIATION / TEST INSTANCE                       │  │
  │  │        lab/juice-shop_20.2.0-remediated  port 3001      │  │
  │  │        REMED-001 (CORS allow-list)                     │  │
  │  │        REMED-002 (encryptionkeys routes removed)       │  │
  │  │        REMED-002b (explicit 404 for /encryptionkeys)   │  │
  │  │        serves AFTER evidence                            │  │
  │  └────────────────────────────────────────────────────────┘  │
  └──────────────────────────────────────────────────────────────┘
```

## Why baseline and remediation run side by side

Because both instances stay live at once, the **identical HTTP request** can be replayed
against each. Every before/after pair in this project is therefore a live side-by-side
comparison, not a remembered earlier state. This is what allowed two defects to be caught
that a status-code-only check would have missed (see `docs/retesting.md`).

## Isolation

`scripts/check-lab.sh` verifies that the application is **not** reachable via the LAN
address `10.59.163.195`; only `127.0.0.1` is bound. This confines testing to the local
machine, as required by the engagement scope.

## Other listening services on the host (not part of this lab)

| Port | Service | Relationship to CS-02 |
|---|---|---|
| 80 | Apache 2.4.58 (Ubuntu) | Pre-existing, serves an unrelated "Cloud Computing Lab" page. **Out of scope, untouched.** |
| 3306 / 33060 | MySQL 8.0.46 | Pre-existing, unrelated to Juice Shop (which uses SQLite). Out of scope. |
| 631 | CUPS 2.4 | Pre-existing printing service. Out of scope. |
| 5500 | *(free)* | Formerly occupied by a VS Code Live Server that served a **directory listing** instead of the application. It is unused by this project, and the lab scripts actively reject any directory-listing server. |

## Port summary for the lab

| Port | Role | Command |
|---|---|---|
| 3000 | Vulnerable baseline | `cd lab/juice-shop_20.2.0 && node build/app` |
| 3001 | Remediation instance | `cd lab/juice-shop_20.2.0-remediated && PORT=3001 node build/app` |