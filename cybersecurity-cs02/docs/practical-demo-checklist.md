# CS-02 — Practical Demo Checklist

12 steps. Every command is verified working in this project. Working directory:
`/home/asta/Desktop/Cyber-Security/cybersecurity-cs02`

**Narrative goal:** WHAT WAS FOUND → WHY IT MATTERED → HOW IT WAS VALIDATED →
WHAT WAS CHANGED → HOW IT WAS RETESTED → WHAT THE RESULT WAS.

---

### 1. Show laboratory architecture
```bash
cat docs/architecture-final.md | head -40
```
Point out: single host, app binds loopback only, **baseline :3000** and
**remediation :3001** running side by side so before/after is a live comparison.

### 2. Start / verify baseline Juice Shop
```bash
bash scripts/check-lab.sh          # expect: LAB STATUS: PASS  (10/10)
```
If down: `bash scripts/start-lab.sh`

### 3. Open the actual application
Browser → `http://127.0.0.1:3000` — real Juice Shop UI, product tiles, navigation.
```bash
curl -s http://127.0.0.1:3000/ | grep -oE '<title>[^<]*</title>'   # OWASP Juice Shop
```

### 4. Show reconnaissance
```bash
cat evidence/recon/RECON-001-port-scan.txt
cat evidence/recon/RECON-002-technology.txt | head -25
```
State the limitation explicitly: **no nmap/Nikto/ZAP available**, raw socket calls used.

### 5. Show application mapping
```bash
ls findings/                                   # 10 finding dirs
grep -oE "app\.use\('[^']+'" lab/juice-shop_20.2.0/server.ts | sort -u | head -15
```

### 6. Select finding 1 — WEB-VUL-010 (Wildcard CORS)
```bash
sed -n '/^## 2. Title/,/^## 3/p' findings/WEB-VUL-010/finding.md
```

### 7. Show original evidence
```bash
cat evidence/findings/V-010-validation.txt
```
**Why it matters:** any website could read the API cross-site.

### 8. Show controlled validation (live, against the vulnerable baseline)
```bash
curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3000/rest/user/login \
  -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: POST' \
  | grep -i 'access-control-allow-origin'
# → Access-Control-Allow-Origin: *
```

### 9. Show the remediation
```bash
grep -n -B2 -A14 'REMED-001' lab/juice-shop_20.2.0-remediated/build/server.js | head -30
```
Emphasise: the **baseline file is untouched**; fixes live only in the copy.

### 10. Show retest + final result
```bash
echo "BASELINE  :3000 ->"; curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3000/rest/user/login -H 'Origin: https://evil.example' | grep -i 'allow-origin'
echo "REMEDIATED:3001 ->"; curl -s -D - -o /dev/null -X OPTIONS http://127.0.0.1:3001/rest/user/login -H 'Origin: https://evil.example' | grep -i 'allow-origin'
echo "(empty = blocked)"
# own-origin control still allowed -> no regression
```
**Result: REMEDIATED — RE-TESTED.**

---

### 11. Repeat with finding 2 — WEB-VUL-008 (Encryption key exposure)
**Original evidence:**
```bash
curl -s http://127.0.0.1:3000/encryptionkeys/jwt.pub | sed -n '1p;$p'
# -----BEGIN RSA PUBLIC KEY-----
# -----END RSA PUBLIC KEY-----
```
**Remediation:**
```bash
grep -n 'encryptionkeys' lab/juice-shop_20.2.0-remediated/build/server.js
# routes REMED-002 removed; explicit 404 handler REMED-002b added
```
**Retest + final result:**
```bash
for p in premium.key jwt.pub; do
  echo "$p  baseline=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/encryptionkeys/$p)" \
       "remediated=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3001/encryptionkeys/$p)"
done
# baseline 200 / remediated 404
echo "key blocks: $(curl -s http://127.0.0.1:3000/encryptionkeys/jwt.pub | grep -c 'BEGIN RSA PUBLIC KEY') / $(curl -s http://127.0.0.1:3001/encryptionkeys/jwt.pub | grep -c 'BEGIN RSA PUBLIC KEY')"
# 1 / 0
```
**Result: REMEDIATED — RE-TESTED.**

---

### 12. Show final honest status
```bash
cat findings/REMEDIATION_REGISTER.md | sed -n '1,20p'
bash scripts/check-lab.sh | tail -5
md5sum lab/juice-shop_20.2.0/server.ts     # ba10fa21… pristine
```
Say plainly: **10 findings · 5 remediated and re-tested · 5 open with recommendations.**
The assessment is **not** clean and is not presented as clean.

**Closing line (the real lesson):** a change is not proven until the identical test is
replayed against the vulnerable baseline and the fixed build side by side. That is how
two wrong implementations of REMED-001 were caught.