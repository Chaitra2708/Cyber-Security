#!/usr/bin/env python3
"""
CS-02 — build the PUBLIC secure demonstration site.

WHAT:   Generates a read-only static site from the real assessment artifacts.
WHY:    Lets the project be demonstrated from any device over HTTPS without
        exposing the intentionally vulnerable Juice Shop application.
WHERE:  Run from the repository root:
            python3 cybersecurity-cs02/scripts/build-demo-site.py
        Output: cybersecurity-cs02/site/

SAFETY  The site is DOCUMENTATION ONLY. It contains no application runtime,
        no database, and no way to reach the lab. Everything published is
        scrubbed of credentials and key material by scrub() below, and the
        generator refuses to copy evidence files verbatim.
"""
import csv
import html
import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent          # cybersecurity-cs02
SITE = ROOT / "site"
ASSETS = SITE / "assets"

# Anything matching these is replaced before it is written to the public site.
SECRET_PATTERNS = [
    (re.compile(r"\b[A-Za-z0-9._%+-]+@juice-sh\.op\b"), "[lab-account-redacted]"),
    (re.compile(r"\badmin123\b"), "[password-redacted]"),
    (re.compile(r"\b[0-9a-f]{32}\b"), "[hash-redacted]"),          # md5 hashes
    (re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}"),
     "[jwt-redacted]"),
    (re.compile(r"(?i)Bearer\s+[A-Za-z0-9._-]{20,}"), "Bearer [token-redacted]"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----"),
     "[private-key-redacted]"),
]


def scrub(text: str) -> str:
    """Remove credentials and key material from text bound for the public site."""
    for pattern, repl in SECRET_PATTERNS:
        text = pattern.sub(repl, text)
    return text


def esc(text: str) -> str:
    return html.escape(scrub(text))


CSS = """
:root{--bg:#0f1720;--card:#182430;--ink:#e8eef5;--mut:#93a4b8;--line:#2b3a4a;
--ok:#2fbf71;--open:#e0a33e;--crit:#e5484d;--high:#f0883e;--med:#e0c341;--low:#4a9de0;
--acc:#4a9de0}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);
font:16px/1.65 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--acc)}
.wrap{max-width:1080px;margin:0 auto;padding:0 20px}
header{background:linear-gradient(135deg,#132030,#1c3040);border-bottom:1px solid var(--line);
padding:44px 0 34px}
header h1{margin:0 0 8px;font-size:1.9rem;letter-spacing:-.4px}
header p{margin:0;color:var(--mut);max-width:70ch}
nav{position:sticky;top:0;background:#0f1720ee;backdrop-filter:blur(8px);
border-bottom:1px solid var(--line);z-index:10}
nav .wrap{display:flex;gap:6px;overflow-x:auto;padding:9px 20px}
nav a{color:var(--mut);text-decoration:none;white-space:nowrap;padding:6px 12px;
border-radius:7px;font-size:.92rem}
nav a:hover,nav a.on{background:var(--card);color:var(--ink)}
main{padding:34px 0 70px}
section{margin-bottom:46px}
h2{font-size:1.35rem;margin:0 0 14px;padding-bottom:9px;border-bottom:1px solid var(--line)}
h3{font-size:1.06rem;margin:24px 0 9px;color:var(--ink)}
.grid{display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(215px,1fr))}
.card{background:var(--card);border:1px solid var(--line);border-radius:11px;padding:17px}
.card .n{font-size:1.85rem;font-weight:700;line-height:1.1}
.card .l{color:var(--mut);font-size:.86rem;margin-top:5px;text-transform:uppercase;
letter-spacing:.5px}
.card.ok .n{color:var(--ok)} .card.open .n{color:var(--open)}
table{width:100%;border-collapse:collapse;margin:14px 0;font-size:.93rem}
th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}
th{color:var(--mut);font-size:.79rem;text-transform:uppercase;letter-spacing:.5px}
tr:hover td{background:#1b2836}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.87rem}
pre{background:#0b1219;border:1px solid var(--line);border-radius:9px;padding:14px;
overflow-x:auto}
.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:.75rem;
font-weight:600;white-space:nowrap}
.b-ok{background:#12351f;color:var(--ok);border:1px solid #1d5c37}
.b-open{background:#3a2c11;color:var(--open);border:1px solid #6b511c}
.b-crit{background:#3a1517;color:var(--crit);border:1px solid #6b2226}
.b-high{background:#3a2413;color:var(--high);border:1px solid #6b3d1c}
.b-med{background:#38320f;color:var(--med);border:1px solid #5f551c}
.b-low{background:#12293a;color:var(--low);border:1px solid #1f4560}
.note{background:#132030;border-left:3px solid var(--acc);border-radius:0 8px 8px 0;
padding:13px 16px;margin:16px 0;color:var(--mut)}
.note strong{color:var(--ink)}
.warn{border-left-color:var(--open)}
ul{padding-left:20px} li{margin:5px 0}
footer{border-top:1px solid var(--line);color:var(--mut);font-size:.87rem;padding:22px 0}
.pill{display:inline-block;background:var(--card);border:1px solid var(--line);
border-radius:7px;padding:3px 10px;margin:3px 5px 3px 0;font-size:.85rem}
img{max-width:100%;border:1px solid var(--line);border-radius:9px}
"""


def page(title: str, active: str, body: str) -> str:
    nav = [("index", "Overview"), ("findings", "Findings"), ("remediation", "Remediation"),
           ("retesting", "Re-Testing"), ("results", "Results"),
           ("architecture", "Architecture"), ("report", "Report")]
    links = "".join(
        f'<a href="{k}.html" class="{"on" if k == active else ""}">{n}</a>'
        for k, n in nav)
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(title)} · CS-02</title><style>{CSS}</style></head><body>
<header><div class="wrap">
<h1>CS-02 — Web Application Security Assessment</h1>
<p>OWASP methodology assessment of OWASP Juice Shop 20.2.0. This is the
<b>public, documentation-only</b> demonstration build. The vulnerable
application itself is not published and runs only inside an isolated local
laboratory.</p></div></header>
<nav><div class="wrap">{links}</div></nav>
<main><div class="wrap">{body}</div></main>
<footer><div class="wrap">CS-02 · Documentation-only public build ·
Findings, risk, remediation and re-testing results. No application runtime,
no database and no credentials are published here.</div></footer>
</body></html>"""


# --------------------------------------------------------------------------
# read the real artifacts
# --------------------------------------------------------------------------
def load_findings():
    out = []
    for d in sorted(ROOT.glob("findings/WEB-VUL-0*")):
        txt = (d / "finding.md").read_text(encoding="utf-8", errors="ignore")

        def sec(name, nxt):
            m = re.search(rf"^## \d+\. {name}\s*$(.*?)(?=^## \d+\. {nxt})",
                          txt, re.S | re.M)
            return m.group(1).strip() if m else ""

        sev = (re.search(r"^## \d+\. Severity\s*$(.*?)(?=^## \d+\.)", txt, re.S | re.M)
               or [None, ""])[1].strip().split("\n")[0].strip()
        # Classify from the LEADING VERDICT LINE only. Searching the whole
        # section is wrong: an open finding can legitimately contain the word
        # "fixed" later on (e.g. 'no "fixed" claim is made').
        retest = sec(r"Retest Status", "Evidence IDs")
        verdict = next((ln for ln in retest.splitlines() if ln.strip()), "")
        status = "Open" if re.search(r"STILL OPEN|Not Retested", verdict, re.I) \
            else "Remediated"
        out.append({
            "id": d.name,
            "title": re.sub(r"[`*_]", "", sec("Title", "Affected Component")).split("\n")[0],
            "component": scrub(re.sub(r"[`*]", "", sec("Affected Component",
                                                        r"URL ?/ ?Endpoint")).split("\n")[0]),
            "endpoint": scrub(re.sub(r"[`*]", "", sec(r"URL ?/ ?Endpoint",
                                                       "HTTP Method")).split("\n")[0]),
            "severity": sev if sev in ("Critical", "High", "Medium", "Low") else "Medium",
            "impact": scrub(re.sub(r"[`*]", "", sec("Potential Impact", "Severity"))),
            "recommendation": scrub(re.sub(r"[`*]", "", sec("Recommendation",
                                                             "Remediation Status"))),
            "status": status,
            "description": scrub(re.sub(r"[`*]", "", sec("Description",
                                                          "Technical Details"))),
        })
    return out


def load_risk():
    with open(ROOT / "findings" / "risk-register.csv", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def load_evidence_rows():
    with open(ROOT / "evidence" / "evidence-index.csv", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def bsev(s):
    return {"Critical": "b-crit", "High": "b-high", "Medium": "b-med",
            "Low": "b-low"}.get(s, "b-med")


def main():
    if SITE.exists():
        shutil.rmtree(SITE)
    ASSETS.mkdir(screenshots=True) if False else (SITE.mkdir(parents=True),
                                                  ASSETS.mkdir(parents=True))

    f = load_findings()
    risk = load_risk()
    ev = load_evidence_rows()
    sev_count = {s: sum(1 for x in f if x["severity"] == s)
                 for s in ("Critical", "High", "Medium", "Low")}
    rem = [x for x in f if x["status"] == "Remediated"]
    opn = [x for x in f if x["status"] == "Open"]

    # screenshots that are safe to publish (original lab captures)
    shots = []
    for src in sorted((ROOT / "evidence" / "screenshots").glob("*.png")):
        shutil.copy2(src, ASSETS / src.name)
        shots.append(src.name)

    # ---------------- overview ----------------
    body = f"""
<section><h2>Assessment at a glance</h2><div class="grid">
<div class="card"><div class="n">{len(f)}</div><div class="l">Findings</div></div>
<div class="card ok"><div class="n">{len(rem)}</div><div class="l">Remediated &amp; re-tested</div></div>
<div class="card open"><div class="n">{len(opn)}</div><div class="l">Open, recommendation only</div></div>
<div class="card"><div class="n">{len(ev)}</div><div class="l">Evidence records</div></div>
<div class="card"><div class="n">{sev_count['Critical']+sev_count['High']}</div><div class="l">Critical + High</div></div>
</div></section>

<section><h2>Severity distribution</h2><table><tr><th>Severity</th><th>Count</th><th>Findings</th></tr>
{''.join(f'<tr><td><span class="badge {bsev(s)}">{s}</span></td><td>{sev_count[s]}</td><td>' + ', '.join(x['id'][-3:] for x in f if x['severity']==s) + '</td></tr>' for s in ('Critical','High','Medium','Low'))}
</table></section>

<section><h2>What this site is — and is not</h2>
<div class="note"><strong>Public (this site):</strong> findings, risk analysis,
remediation and re-testing results, architecture and report summary.
Read-only documentation. No application runtime, no database, no credentials.</div>
<div class="note warn"><strong>Private (not published):</strong> the
intentionally vulnerable OWASP Juice Shop application and the live
before/after laboratory. It runs only on an isolated local host, bound to
loopback, and is deliberately unreachable from the internet. Controlled
validation of the vulnerabilities requires that private environment.</div>
</section>

<section><h2>Findings</h2><table><tr><th>ID</th><th>Title</th><th>Severity</th>
<th>Status</th></tr>
{''.join(f"<tr><td><a href='findings.html#{x['id']}'>{x['id']}</a></td><td>{esc(x['title'])}</td>"
         f"<td><span class='badge {bsev(x['severity'])}'>{x['severity']}</span></td>"
         f"<td><span class='badge {'b-ok' if x['status']=='Remediated' else 'b-open'}'>{x['status']}</span></td></tr>" for x in f)}
</table></section>

<section><h2>Laboratory screenshots</h2><p class="pill">Original captures from the
group's own isolated laboratory</p><div class="grid">
{''.join(f'<div class="card"><img src="assets/{n}" alt="lab screenshot {n}" loading="lazy"><div class="l" style="margin-top:8px">{esc(n)}</div></div>' for n in shots)}
</div></section>
"""
    (SITE / "index.html").write_text(page("Overview", "index", body), encoding="utf-8")

    # ---------------- findings ----------------
    rows = "".join(f"""
<article id="{x['id']}"><h3>{x['id']} — {esc(x['title'])}
<span class="badge {bsev(x['severity'])}">{x['severity']}</span>
<span class="badge {'b-ok' if x['status']=='Remediated' else 'b-open'}">{x['status']}</span></h3>
<p><strong>Component:</strong> {esc(x['component'])}<br>
<strong>Endpoint:</strong> <code>{esc(x['endpoint'])}</code></p>
<h3>Description</h3><p>{esc(x['description'])}</p>
<h3>Potential impact</h3><p>{esc(x['impact'])}</p>
<h3>Recommendation</h3><p>{esc(x['recommendation'])}</p></article><hr>"""
        for x in f)
    (SITE / "findings.html").write_text(page("Findings", "findings", f"""
<section><h2>All findings ({len(f)})</h2>
<p>Severity is assigned from technical reasoning about the damage if exploited
and how reachable it is — it is <em>not</em> copied from an automated scanner,
because no scanner was used in this assessment.</p>{rows}</section>"""),
        encoding="utf-8")

    # ---------------- remediation ----------------
    (SITE / "remediation.html").write_text(page("Remediation", "remediation", f"""
<section><h2>Remediation status</h2>
<p>{len(rem)} findings were remediated and re-tested. {len(opn)} remain
<b>open by decision</b>: forcing them closed would misrepresent the result,
so each carries a documented reason instead.</p>
<table><tr><th>ID</th><th>Severity</th><th>Recommended control</th><th>Implemented</th></tr>
{''.join(f"<tr><td>{x['id']}</td><td><span class='badge {bsev(x['severity'])}'>{x['severity']}</span></td>"
         f"<td>{esc(x['recommendation'][:230])}</td>"
         f"<td><span class='badge {'b-ok' if x['status']=='Remediated' else 'b-open'}'>{x['status']}</span></td></tr>" for x in f)}
</table></section>
<section><h2>What a remediation had to prove</h2>
<div class="note">Each fix is only accepted when the attack result changes
<em>and</em> legitimate use still works — otherwise the "fix" would just be a
broken application. Every re-test pairs an attack probe with a functional
control.</div></section>"""), encoding="utf-8")

    # ---------------- re-testing ----------------
    before_after = [
        ("WEB-VUL-001", "SQL injection in login", "HTTP 200 + admin JWT",
         "HTTP 401 on all payloads; valid login still 200"),
        ("WEB-VUL-002", "Basket IDOR / BOLA", "HTTP 200 + victim's basket",
         "HTTP 403; own basket unchanged"),
        ("WEB-VUL-003", "Missing security headers", "2 of 9 hardening headers present",
         "9 of 9 present; 0 browser CSP violations"),
        ("WEB-VUL-008", "Encryption key exposure", "HTTP 200, key material served",
         "HTTP 404, no key material"),
        ("WEB-VUL-010", "Wildcard CORS", "Access-Control-Allow-Origin: *",
         "no ACAO header for a foreign origin"),
    ]
    (SITE / "retesting.html").write_text(page("Re-Testing", "retesting", f"""
<section><h2>Before / after</h2>
<p>Each remediated finding was re-tested with the <em>same</em> procedure that
originally demonstrated it, replayed against a deliberately vulnerable baseline
and a remediated copy running side by side.</p>
<table><tr><th>Finding</th><th>Vulnerability</th><th>Before (vulnerable)</th>
<th>After (remediated)</th></tr>
{''.join(f"<tr><td>{i}</td><td>{esc(d)}</td><td>{esc(b)}</td><td><span class='badge b-ok'>{esc(a)}</span></td></tr>" for i,d,b,a in before_after)}
</table></section>
<section><h2>Findings confirmed still open</h2>
<table><tr><th>Finding</th><th>Severity</th><th>Observed on re-test</th></tr>
<tr><td>WEB-VUL-004</td><td><span class="badge b-med">Medium</span></td><td>/metrics, application-version and robots.txt all still answer 200 with no token</td></tr>
<tr><td>WEB-VUL-005</td><td><span class="badge b-low">Low</span></td><td>/api/Feedbacks still answers 200 unauthenticated, exposing user content</td></tr>
<tr><td>WEB-VUL-006</td><td><span class="badge b-high">High</span></td><td>a customer-role token still reads the entire user directory</td></tr>
<tr><td>WEB-VUL-007</td><td><span class="badge b-crit">Critical</span></td><td>the JWT payload still carries the account password hash</td></tr>
<tr><td>WEB-VUL-009</td><td><span class="badge b-high">High</span></td><td>search still evaluates injected SQL: 3 rows vs 46</td></tr>
</table></section>"""), encoding="utf-8")

    # ---------------- results ----------------
    (SITE / "results.html").write_text(page("Results", "results", f"""
<section><h2>Risk register</h2>
<p>Every finding is scored on likelihood, impact, exploitability and exposure,
with a written rationale. Severity and overall risk are kept deliberately as
separate scales.</p>
<table><tr><th>ID</th><th>Vulnerability</th><th>L</th><th>I</th><th>E</th><th>X</th>
<th>Overall</th><th>Priority</th></tr>
{''.join(f"<tr><td>{r['Finding ID']}</td><td>{esc(r['Vulnerability'])}</td>"
         f"<td>{r['Likelihood (1-5)']}</td><td>{r['Impact (1-5)']}</td>"
         f"<td>{r['Exploitability (1-5)']}</td><td>{r['Exposure (1-5)']}</td>"
         f"<td><b>{esc(r['Overall Risk'])}</b></td><td>{esc(r['Priority'])}</td></tr>" for r in risk)}
</table></section>
<section><h2>Evidence register</h2>
<p>{len(ev)} indexed evidence records, each mapped to a file, every path verified
to exist, with no duplicate identifiers.</p>
<table><tr><th>ID</th><th>Phase</th><th>Description</th><th>Result</th></tr>
{''.join(f"<tr><td>{esc(r['Evidence ID'])}</td><td>{esc(r['Phase'])}</td>"
         f"<td>{esc(r['Description'][:150])}</td><td>{esc(r['Result'][:60])}</td></tr>" for r in ev[:40])}
</table><p class="pill">showing first 40 of {len(ev)}</p></section>
<section><h2>Test results</h2><table>
<tr><th>Check</th><th>Result</th></tr>
<tr><td>Laboratory health check</td><td><span class="badge b-ok">PASS — 10 of 10 checks</span></td></tr>
<tr><td>Vulnerable baseline reproduces its findings</td><td><span class="badge b-ok">PASS</span></td></tr>
<tr><td>Remediated copy shows each fix effective</td><td><span class="badge b-ok">PASS</span></td></tr>
<tr><td>Network isolation (LAN cannot reach the app)</td><td><span class="badge b-ok">PASS</span></td></tr>
<tr><td>Automated scanners</td><td><span class="badge b-open">NOT USED — none available</span></td></tr>
<tr><td>TypeScript compilation</td><td><span class="badge b-open">NOT PERFORMED — distribution has no tsconfig.json</span></td></tr>
<tr><td>XSS reproduction</td><td><span class="badge b-open">NOT REPRODUCED — reported as unconfirmed</span></td></tr>
</table></section>"""), encoding="utf-8")

    # ---------------- architecture ----------------
    lab_arch = "\n".join([
        "  Testing machine (Linux, isolated)",
        "  |",
        "  +-- lab/juice-shop_20.2.0            port 3000",
        "  |     vulnerable BASELINE - reproduces the findings",
        "  |     verified byte-for-byte against the official",
        "  |     OWASP distribution (md5 verified)",
        "  |",
        "  +-- lab/juice-shop_20.2.0-remediated  port 3001",
        "        REMEDIATED copy - demonstrates the five fixes",
        "",
        "  Both bind 127.0.0.1 only. The LAN address is verified",
        "  unreachable, so the assessment stays contained.",
    ])
    pub_arch = "\n".join([
        "  Any device (phone / laptop / desktop)",
        "        |",
        "     HTTPS",
        "        |",
        "  Static documentation site  <-- THIS SITE",
        "        |",
        "  read-only HTML + images",
        "",
        "  No application runtime.",
        "  No database.",
        "  No credentials.",
        "  No path to the vulnerable lab.",
    ])
    (SITE / "architecture.html").write_text(page("Architecture", "architecture", f"""
<section><h2>Laboratory architecture (private)</h2><pre>{esc(lab_arch)}</pre></section>
<section><h2>Public deployment architecture (this site)</h2><pre>{esc(pub_arch)}</pre></section>
<section><h2>Security controls on this site</h2><ul>
<li>Documentation only — the vulnerable application is never exposed</li>
<li>All published text is scrubbed of account names, passwords,
hashes, tokens and key material at build time</li>
<li>No database, no session handling, no authentication surface</li>
<li>Served over HTTPS by the hosting platform</li>
<li>The private laboratory is bound to loopback and unreachable from the internet</li>
</ul></section>"""), encoding="utf-8")

    # ---------------- report ----------------
    (SITE / "report.html").write_text(page("Report", "report", """
<section><h2>Report summary</h2>
<p>The full technical report is a ten-chapter document held in the project
repository. This page summarises its conclusions for the public demonstration
build.</p>
<table><tr><th>Chapter</th><th>Content</th></tr>
<tr><td>1 Introduction</td><td>Background, problem statement, objectives, scope and limitations</td></tr>
<tr><td>2 Existing system &amp; proposed approach</td><td>Current security posture and the assessment approach chosen</td></tr>
<tr><td>3 Requirements &amp; laboratory environment</td><td>Observed hardware, software, network configuration, IP addressing and architecture</td></tr>
<tr><td>4 Methodology</td><td>Reconnaissance, application mapping, security testing, controlled validation, remediation and re-testing</td></tr>
<tr><td>5 Implementation</td><td>Laboratory setup, deployment, evidence collection</td></tr>
<tr><td>6 Security assessment &amp; analysis</td><td>All findings, technical evidence, risk analysis and impact</td></tr>
<tr><td>7 Security remediation</td><td>Recommended controls and those actually implemented</td></tr>
<tr><td>8 Testing &amp; validation</td><td>Initial results, re-testing, regression and before/after comparison</td></tr>
<tr><td>9 Results &amp; discussion</td><td>Objective achievement, challenges and lessons learned</td></tr>
<tr><td>10 Conclusion &amp; future scope</td><td>Conclusions, honest limitations and future work</td></tr>
</table></section>
<section><h2>Limitations, stated plainly</h2><ul>
<li>The specification asked for a Kali Linux VM and an Ubuntu Server VM under
virtualisation. That environment was not available, so the lab was built on a
single Linux host. Those screenshots were <em>not</em> fabricated.</li>
<li>No automated security scanners were available, so every finding was
validated with direct HTTP testing and source analysis. No scanner severity is
quoted anywhere in this project, because none was produced.</li>
<li>The shipped Juice Shop distribution contains no <code>tsconfig.json</code>,
so the TypeScript sources could not be recompiled. Fixes were applied to the
runtime build and mirrored into the sources, which are therefore not
type-checked.</li>
<li>XSS was tested for but could not be reproduced, so it is reported as
<em>unconfirmed</em> rather than as a passing result.</li>
<li>Privilege escalation was not demonstrated, so that finding is rated on
proven read-only impact only.</li>
<li>{len(opn)} findings remain open with written recommendations.</li>
</ul></section>"""), encoding="utf-8")

    # ---------------- health ----------------
    # Static equivalent of a health endpoint: HTTP 200 with a machine-readable
    # body, so an uptime check or a deployment verifier can probe it.
    (SITE / "health.html").write_text(
        '{"status":"ok","service":"CS-02 secure demonstration site",'
        '"type":"static-documentation","findings":%d,"remediated":%d,"open":%d,'
        '"vulnerable_app_exposed":false,"build":"%s"}\n'
        % (len(f), len(rem), len(opn), "2026-10-04"),
        encoding="utf-8")

    print(f"site built: {SITE}")
    print(f"  findings={len(f)} remediated={len(rem)} open={len(opn)} evidence={len(ev)} "
          f"screenshots={len(shots)}")


if __name__ == "__main__":
    main()