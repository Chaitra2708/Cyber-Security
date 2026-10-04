# CS-02 — Public Demonstration Deployment

## Purpose

The CS-02 assessment needs to be viewable from **any device** — phone, tablet, laptop —
without requiring anyone to start a local server.

What is published is a **read-only documentation site** presenting the findings, risk
analysis, remediation and re-testing results.

**What is deliberately NOT published: the application.** The "secure/remediated" instance
was evaluated as a candidate for public exposure and **rejected**, because it still carries
five open findings, verified live at the time of this deployment:

| Finding | Severity | Verified behaviour on the remediated instance |
|---|---|---|
| WEB-VUL-007 | **Critical** | the JWT payload still contains the account password hash and `totpSecret` |
| WEB-VUL-009 | **High** | SQL injection live — `' OR '1'='1` returns 46 rows vs 3 |
| WEB-VUL-006 | **High** | a customer-role token still reads the entire user directory |
| WEB-VUL-004 | Medium | `/metrics` answers 200 unauthenticated |
| WEB-VUL-005 | Low | `/api/Feedbacks` answers 200 unauthenticated |

Publishing that would place an application with unauthenticated SQL injection and
credential disclosure on the public internet — effectively the vulnerable target, which the
project's security rules forbid. A documentation site demonstrates the assessment fully
while exposing nothing exploitable.

## Deployment platform

| Field | Value |
|---|---|
| Provider | **GitHub Pages** (static hosting) |
| Public URL | **https://chaitra2708.github.io/Cyber-Security/** |
| Health check | **https://chaitra2708.github.io/Cyber-Security/health.html** |
| Source repository | https://github.com/Chaitra2708/Cyber-Security |
| Site branch | `gh-pages` |
| Main branch | `main` |
| Deployment timestamp | 2026-10-04 |
| HTTPS | yes — GitHub Pages issues a TLS certificate automatically |
| Cost | free |

GitHub Pages is used **only as a static host for documentation**. It is not the runtime for
the Juice Shop application, which never leaves the laboratory.

## Architecture

```
  Any device (phone / tablet / laptop)
            |
         HTTPS (TLS)
            |
  GitHub Pages (static CDN)
            |
  read-only HTML + PNG screenshots
            |
  NO application runtime
  NO database
  NO credentials
  NO path to the vulnerable lab
```

The private laboratory remains entirely separate:

```
  Local lab host (loopback only)
     baseline    http://127.0.0.1:3000/   vulnerable, never published
     remediation http://127.0.0.1:3001/   private, never published
```

## Build and start commands

Static site — there is no server process and no start command.

```bash
# regenerate the site from the project artifacts
python3 cybersecurity-cs02/scripts/build-demo-site.py

# publish (creates/updates the gh-pages branch)
rm -rf /tmp/ghp && mkdir -p /tmp/ghp
cp -r cybersecurity-cs02/site/. /tmp/ghp/
cd /tmp/ghp && git init -q -b gh-pages && touch .nojekyll
git add -A && git commit -m "CS-02 public secure demonstration site"
git push https://github.com/Chaitra2708/Cyber-Security.git gh-pages:gh-pages
```

## Private laboratory (unchanged)

```bash
bash cybersecurity-cs02/scripts/deploy-from-github.sh           # baseline    :3000
PORT=3001 bash cybersecurity-cs02/scripts/deploy-from-github.sh  # remediation :3001
bash cybersecurity-cs02/scripts/check-lab.sh                     # expect PASS 10/10
bash cybersecurity-cs02/scripts/stop-lab.sh                      # stop both
```

## Environment variables

None. The published site is static and requires no runtime configuration, no secrets and
no database connection.

## Health check

```bash
curl -s https://chaitra2708.github.io/Cyber-Security/health.html
```

Expected HTTP 200 with:

```json
{"status":"ok","service":"CS-02 secure demonstration site","type":"static-documentation",
 "findings":10,"remediated":5,"open":5,"vulnerable_app_exposed":false}
```

## Security controls applied

- **Documentation only** — no application runtime, database, session handling or
  authentication surface is exposed.
- **Automated scrubbing** — `build-demo-site.py` replaces lab account names, passwords,
  32-character hashes, JWTs, bearer tokens and private keys with redaction markers before
  any text is written. Verified: the published tree contains none of them.
- **No secrets in the repository** — `lab/` is gitignored, so key material
  (`ctf.key`, `premium.key`, `jwt.pub`) is never committed.
- **HTTPS with HSTS** — GitHub Pages serves `Strict-Transport-Security`.
- **No credentials of any kind** are required to view the site.
- **Isolation preserved** — the lab binds to `127.0.0.1`; `check-lab.sh` fails if the LAN
  address can reach it.

## Rollback procedure

```bash
# restore the previously published site
cd /tmp/ghp && git log --oneline
git checkout <previous-commit> -- .
git commit -m "revert demo site" 
git push https://github.com/Chaitra2708/Cyber-Security.git gh-pages:gh-pages
```

To remove the public site entirely, delete the branch in GitHub, or disable Pages in the
repository settings.

## Limitations

1. **The public site is documentation, not the application.** It demonstrates the
   assessment results but cannot be used to re-run controlled validation — that requires
   the private laboratory, which is intentionally not reachable from the internet.
2. **Cross-device testing was performed over the public HTTPS URL from an
   internet-facing host**, not from a physical phone on a cellular connection. The site is
   plain responsive HTML with a viewport meta tag and no device-specific behaviour, but a
   literal phone test was not performed.
3. **No live application metrics** — the published counts are generated at build time from
   the project artifacts, not fetched at runtime.
4. **Screenshots are static images** captured from the private lab; they are not live.
5. All the substantive assessment limitations remain as recorded in the report: no Kali/VM
   environment, no automated scanners, no TypeScript recompilation, XSS not reproduced,
   privilege escalation not demonstrated, and five findings still open.

## PUBLIC vs PRIVATE

| | Contents |
|---|---|
| **PUBLIC** | secure/documentation-only demonstration of findings, risk, remediation, re-testing, architecture and report summary |
| **PRIVATE** | the intentionally vulnerable assessment laboratory, its evidence capture and controlled validation |