# CS-02 — Practical Demonstration Runbook

**Duration:** ~15 minutes. All commands are verified working in this project.
**Narrative to convey:** WHAT WAS VULNERABLE → WHY IT MATTERED → WHAT CHANGED →
HOW IT WAS RETESTED → FINAL RESULT.

---

## Step 1 — Show the laboratory architecture

```bash
echo "host: $(hostname)  ip: $(ip -4 addr show wlo1 | awk '{print $4}')"
ss -ltn | grep -E ':3000|:3001'
```

Explain: baseline on **3000**, remediated build on **3001**, both loopback-only. The LAN
IP `10.59.163.195` must **not** reach the app.

---

## Step 2 — Start / verify Juice Shop

```bash
cd /home/asta/Desktop/Cyber-Security/cybersecurity-cs02
bash scripts/check-lab.sh
```

Expect: **`LAB STATUS: PASS`** — 10/10 checks. If it is down: `bash scripts/start-lab.sh`.

---

## Step 3 — Show the actual application

Open `http://127.0.0.1:3000` in a browser: Juice Shop UI, product tiles, navigation.

```bash
curl -s http://127.0.0.1:3000/ | grep -oE '<title>[^<]*</title>'   # OWASP Juice Shop
```

---

## Step 4 — Show reconnaissance evidence

```bash
cat evidence/recon/RECON-001-port-scan.txt
cat evidence/recon/RECON-002-technology.txt | head -25
```

Point out the tooling limitation stated in the file: no nmap/Nikto/ZAP available.

---

## Step 5 — Show application mapping

```bash
grep -oE "app\.use\('[^']+'" lab/juice-shop_20.2.0/server.ts | sort -u | head -20
ls findings/                       # 10 finding directories
```

---

## STEPS 6–10 — Finding 1: WEB-VUL-010 Wildcard CORS

### 6. Show the original evidence (vulnerable)

```bash
cat evidence/remediation/REMED-before.txt | sed -n '/REMED-001/,/REMED-002/p'
```
Or live against the baseline:
```bash
curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3000/rest/user/login \
  -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: POST' \
  | grep -i 'access-control-allow-origin'
```
→ `Access-Control-Allow-Origin: *` for an attacker origin.

### 7. Show the remediation

```bash
grep -n -A12 'REMED-001' lab/juice-shop_20.2.0-remediated/build/server.js | head -25
```

Point out: allow-list **array** of own origins; the baseline file is untouched.

### 8–9. Show the retest

```bash
echo "BASELINE :3000 ->"; curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3000/rest/user/login \
  -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: POST' | grep -i 'access-control-allow-origin'
echo "REMEDIATED :3001 ->"; curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3001/rest/user/login \
  -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: POST' | grep -i 'access-control-allow-origin'
echo "(empty = blocked)"
```

### 10. Final result

`REMEDIATED — RETESTED`. Same-origin control still works, so no regression.

---

## STEPS 11–15 — Finding 2: WEB-VUL-008 Encryption key exposure

### 11. Show the original evidence

```bash
curl -s http://127.0.0.1:3000/encryptionkeys/jwt.pub | sed -n '1p;$p'
# -----BEGIN RSA PUBLIC KEY-----
# -----END RSA PUBLIC KEY-----
```

`jwt.pub` is the RSA **public** key used to verify JWT signatures. It is not a private
key, so do not grep for `PRIVATE KEY` — that returns 0 on both instances and proves
nothing.

### 12. Show the remediation

```bash
grep -n 'encryptionkeys' lab/juice-shop_20.2.0-remediated/build/server.js
```
The two serving routes are commented out (`REMED-002`) and replaced with an explicit
404 handler (`REMED-002b`).

### 13–14. Show the retest — status code AND content

```bash
for p in premium.key jwt.pub; do
  echo "$p  baseline=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/encryptionkeys/$p)" \
       "remediated=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3001/encryptionkeys/$p)"
done
# correct content marker (verified: baseline=1, remediated=0)
echo "baseline   key blocks: $(curl -s http://127.0.0.1:3000/encryptionkeys/jwt.pub | grep -c 'BEGIN RSA PUBLIC KEY')"
echo "remediated key blocks: $(curl -s http://127.0.0.1:3001/encryptionkeys/jwt.pub | grep -c 'BEGIN RSA PUBLIC KEY')"
```

Expected: baseline `200` / remediated `404`; key blocks `1` / `0`.

**This is the teaching moment.** The *first* version of this fix simply deleted the
routes, and the paths then answered **HTTP 200** with the SPA shell — because
`serveAngularClient()` serves `index.html` for any URL not starting with `/api` or
`/rest`. The key was no longer disclosed, so the vulnerability was fixed, but a status
code alone could not show it. The explicit 404 (REMED-002b) makes the status code
meaningful, so the fix is now proven twice over: by status **and** by content.

### 15. Final result

`REMEDIATED — RETESTED`, with the documented 404 follow-up noted honestly.

---

## Step 16 — Show the honest final state

```bash
grep -A16 'Final Findings Summary Table' report/CS-02_Final_Security_Assessment_Report.md
```

> **5 remediated** (001, 002, 003, 008, 010). **5 still open** (004, 005, 006, 007, 009).
> The project does not claim a clean assessment.

---

## Step 17 — Prove the baseline was never destroyed

```bash
cat evidence/remediation/REMED-baseline-integrity.txt
```
Baseline MD5s unchanged; baseline still returns `ACAO: *` live.

---

## Step 18 — Reproduce all evidence on demand

```bash
bash scripts/capture-verification-evidence.sh   # regenerates V-001 … V-010
```