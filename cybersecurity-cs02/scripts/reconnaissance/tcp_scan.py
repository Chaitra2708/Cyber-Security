#!/usr/bin/env python3
"""
CS-02 Lab Reconnaissance - TCP Connect Scanner
==============================================

Authorized use ONLY against the local OWASP Juice Shop laboratory target.

This is a dependency-free TCP connect scanner used because the lab host has
no Nmap installed (sudo requires a password - documented lab constraint).

It performs a true TCP three-way handshake (connect scan) against an explicit
target host and an explicit list of ports, then records:
  - port state (open/closed/filtered)
  - service banner (if the service sends one on connect)
  - HTTP response metadata for web ports

Usage:
    python3 tcp_scan.py <target> [--ports <spec>] [--json <outfile>]

Port spec examples:
    22,80,443,3000
    1-1024
    top100   (built-in common port list)
"""

import argparse
import json
import socket
import sys
import time
from datetime import datetime

# Common web/infrastructure ports used when --ports top100 is requested.
TOP_PORTS = [
    21, 22, 23, 25, 53, 80, 81, 110, 111, 135, 139, 143, 389, 443, 445,
    465, 587, 631, 993, 995, 1080, 1433, 1521, 2049, 2082, 2083, 2086,
    2087, 2095, 2096, 2121, 3000, 3001, 3306, 3389, 4443, 4444, 5000,
    5432, 5900, 5901, 6379, 6666, 6667, 7001, 8000, 8008, 8080, 8081,
    8088, 8443, 8888, 9000, 9001, 9090, 9200, 9300, 10000, 11211,
    15672, 27017, 28017, 50000,
]

CONNECT_TIMEOUT = 1.5   # seconds to wait for TCP handshake
BANNER_TIMEOUT = 1.5    # seconds to wait for an on-connect banner


def parse_ports(spec):
    """Parse a port specification into a sorted, de-duplicated list."""
    if spec == "top100":
        return sorted(set(TOP_PORTS))
    ports = set()
    for chunk in spec.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            lo, hi = chunk.split("-", 1)
            lo, hi = int(lo), int(hi)
            if not (1 <= lo <= hi <= 65535):
                raise ValueError(f"Invalid port range: {chunk}")
            ports.update(range(lo, hi + 1))
        else:
            p = int(chunk)
            if not (1 <= p <= 65535):
                raise ValueError(f"Invalid port: {chunk}")
            ports.add(p)
    return sorted(ports)


def grab_banner(host, port):
    """Attempt to read an on-connect banner. Returns text or None."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(BANNER_TIMEOUT)
        s.connect((host, port))
        try:
            s.sendall(b"\r\n")          # nudge chatty services
        except OSError:
            pass
        try:
            data = s.recv(256)
        except socket.timeout:
            data = b""
        s.close()
        if data:
            return data.decode("utf-8", "replace").strip()[:200]
    except (OSError, socket.timeout):
        return None
    return None


def probe_http(host, port):
    """For a port that answered, check whether it speaks HTTP."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(BANNER_TIMEOUT)
        s.connect((host, port))
        req = (
            f"HEAD / HTTP/1.1\r\nHost: {host}\r\n"
            "User-Agent: CS02-Lab-Recon/1.0\r\nConnection: close\r\n\r\n"
        )
        s.sendall(req.encode())
        raw = b""
        while True:
            chunk = s.recv(1024)
            if not chunk:
                break
            raw += chunk
            if len(raw) > 4096:
                break
        s.close()
        text = raw.decode("utf-8", "replace")
        if text.startswith("HTTP/"):
            first = text.splitlines()[0]
            server = ""
            powered = ""
            for line in text.splitlines():
                low = line.lower()
                if low.startswith("server:"):
                    server = line.split(":", 1)[1].strip()
                elif low.startswith("x-powered-by:"):
                    powered = line.split(":", 1)[1].strip()
            return {"status_line": first, "server": server, "x_powered_by": powered}
    except (OSError, socket.timeout):
        return None
    return None


def scan(target, ports):
    results = []
    for port in ports:
        entry = {"port": port}
        t0 = time.time()
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(CONNECT_TIMEOUT)
            rc = s.connect_ex((target, port))
            elapsed = round((time.time() - t0) * 1000, 1)
            if rc == 0:
                entry["state"] = "open"
                entry["latency_ms"] = elapsed
                banner = grab_banner(target, port)
                if banner:
                    entry["banner"] = banner
                http = probe_http(target, port)
                if http:
                    entry["http"] = http
            else:
                entry["state"] = "closed"
            s.close()
        except socket.timeout:
            entry["state"] = "filtered"
        except OSError as exc:
            entry["state"] = "error"
            entry["error"] = str(exc)
        # Only keep interesting results to keep output readable.
        if entry.get("state") == "open":
            results.append(entry)
    return results


def main():
    ap = argparse.ArgumentParser(description="CS-02 authorized lab TCP scanner")
    ap.add_argument("target", help="Target IP or hostname (lab only)")
    ap.add_argument("--ports", default="top100", help="Port spec or 'top100'")
    ap.add_argument("--json", help="Write full JSON results to this file")
    args = ap.parse_args()

    try:
        ports = parse_ports(args.ports)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)

    # Resolve once so evidence records the actual IP.
    try:
        resolved = socket.gethostbyname(args.target)
    except OSError as exc:
        print(f"ERROR: cannot resolve {args.target}: {exc}", file=sys.stderr)
        sys.exit(2)

    started = datetime.now().isoformat(timespec="seconds")
    print(f"[+] Target   : {args.target} -> {resolved}")
    print(f"[+] Ports    : {len(ports)} specified")
    print(f"[+] Started  : {started}")
    print("-" * 60)

    t0 = time.time()
    open_ports = scan(resolved, ports)
    dur = round(time.time() - t0, 2)

    print(f"{'PORT':<8}{'STATE':<8}{'SERVICE / BANNER'}")
    print("-" * 60)
    if not open_ports:
        print("(no open ports found in the specified range)")
    for e in open_ports:
        detail = ""
        if "http" in e:
            detail = e["http"].get("status_line", "")
            if e["http"].get("server"):
                detail += f"  server={e['http']['server']}"
            if e["http"].get("x_powered_by"):
                detail += f"  x-powered-by={e['http']['x_powered_by']}"
        elif "banner" in e:
            detail = e["banner"]
        print(f"{e['port']:<8}{e['state']:<8}{detail}")
    print("-" * 60)
    print(f"[+] Open ports: {len(open_ports)}   duration: {dur}s")

    if args.json:
        payload = {
            "tool": "cs02-tcp-scan",
            "version": "1.0",
            "target_requested": args.target,
            "target_resolved": resolved,
            "port_spec": args.ports,
            "ports_scanned": len(ports),
            "started": started,
            "duration_s": dur,
            "open_ports": open_ports,
        }
        with open(args.json, "w") as fh:
            json.dump(payload, fh, indent=2)
        print(f"[+] JSON written to {args.json}")


if __name__ == "__main__":
    main()
