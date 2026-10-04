# WEB-VUL-008 — Server-side encryption key material served to anonymous clients

## 1. Finding ID
WEB-VUL-008

## 2. Title
`/encryptionkeys/` directory and its key files are downloadable without authentication

## 3. Affected Component
OWASP Juice Shop static file serving (`/encryptionkeys`, `/encryptionkeys/:file` mounted
in `server.ts`), key material in the installation's `encryptionkeys/` directory

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/encryptionkeys/`
`GET http://127.0.0.1:3000/encryptionkeys/premium.key`
`GET http://127.0.0.1:3000/encryptionkeys/jwt.pub`

## 5. HTTP Method
GET

## 6. Security Category
Sensitive Information Exposure / Broken Access Control (A01:2021, A05:2021)

## 7. Description
The application exposes its `encryptionkeys` directory through a static route with no
authentication and no file-type restriction. Any anonymous client can list the directory
and download each file it contains. The directory holds two distinct kinds of key
material:

- `premium.key` (49 bytes) — the shared secret used to decrypt premium-product content
  and coupon codes. This is sensitive secret key material.
- `jwt.pub` (248 bytes) — an RSA **public** key (`-----BEGIN RSA PUBLIC KEY-----`) used
  to verify JWT signatures. It is not a private key, but publishing it exposes the
  token-signing scheme to offline analysis and aids forgery attempts, and it confirms
  the algorithm and key length an attacker should target.

Both are reachable anonymously and neither belongs in a web-served directory.

For contrast, the sibling `/ftp` route in the same application **does** enforce a file
extension allow-list — a request for `/ftp/package.json` returns
`403 Only .md and .pdf files are allowed!`. The encryption-keys route has no equivalent
control, so the two file-serving surfaces have inconsistent protection and the weaker
one carries the more sensitive material.

## 8. Technical Details
Directory listing returned to an anonymous caller:
```
jwt.pub
premium.key
```

Download results with no `Authorization` header:
```
/encryptionkeys/premium.key -> HTTP 200, 50 bytes
/encryptionkeys/jwt.pub     -> HTTP 200, 248 bytes
```

Key material is deliberately **not** reproduced in the evidence file; only the HTTP
status and byte counts are recorded, so the evidence proves reachability without
copying the secret into the report.

Consequences of disclosure:
- `premium.key` allows decryption of the encrypted premium product description and the
  `announcement_encrypted.md` file served under `/ftp`, and defeats the coupon-code
  obfuscation feature.
- `jwt.pub` reveals the algorithm and key material used for token verification,
  weakening the authentication layer that WEB-VUL-007 already shows to be leaking
  secrets.

## 9. Reproduction
1. With no session cookie and no `Authorization` header, request
   `GET http://127.0.0.1:3000/encryptionkeys/` → `200` with a directory listing.
2. Request `GET http://127.0.0.1:3000/encryptionkeys/premium.key` → `200`, 50 bytes.
3. Request `GET http://127.0.0.1:3000/encryptionkeys/jwt.pub` → `200`, 248 bytes.

## 10. Observed Behaviour
Both key files are served in full to an unauthenticated client. No login, no token and
no cookie are required at any point.

## 11. Potential Impact
An attacker with no access to the application gains the symmetric key protecting
premium content and coupon validation, plus the JWT verification key. Anything the
application relies on these keys to keep confidential is no longer confidential, and the
keys cannot be rotated usefully while the same route keeps serving whatever file it
finds in the directory.

## 12. Severity
High

## 13. Severity Justification
- Reachable by a fully anonymous client — no authentication whatsoever
- Discloses cryptographic key material, which is a step change over ordinary data
  disclosure because confidentiality depends on the key remaining secret
- Enables offline decryption of the content and functionality that key protects
- Rated High rather than Critical because exploitation yields decryption of a limited
  body of in-application content, not direct remote code execution or full session
  compromise on its own

## 14. Recommendation
Remove the `/encryptionkeys` route from the static file mounts entirely and load the
key from a location outside any web-served directory. If a listing route is required
for the product, serve only the public key and gate it behind authentication. Add an
automated check that fails the build if any file under `encryptionkeys/` is reachable
over HTTP. Re-test by requesting the directory and both filenames with no token; all
three must return `404` or `403`.

## 15. Remediation Status
**Remediation implemented (2026-10-04)** — REMED-002. The two `/encryptionkeys` routes
were removed from `build/server.js` and `server.ts` in a separate remediation copy
(`lab/juice-shop_20.2.0-remediated`, port 3001). The vulnerable baseline
(`lab/juice-shop_20.2.0`, port 3000) was left unmodified and still runs.

## 16. Retest Status
**RETESTED — REMEDIATED** (2026-10-04, repaired and re-tested again during closeout)

Same unauthenticated `GET` replayed against both instances.

- First re-test: deleting the routes stopped the key disclosure, but the paths then
  answered **HTTP 200** with the SPA shell, because `serveAngularClient()` replies with
  `index.html` for any URL not beginning with `/api` or `/rest`. The key was no longer
  disclosed, so the finding was genuinely fixed, but a secret path answering 200 is
  semantically wrong and makes the status code useless as evidence.
- **Closeout repair (REMED-002b):** an explicit `404` handler was added for
  `/encryptionkeys` and `/encryptionkeys/:file`, so the fall-through no longer occurs.
- Final re-test: all three paths return **HTTP 404 `Not Found`** on the remediated
  instance and **HTTP 200** with key material on the baseline. PEM key block count is
  1 on the baseline and 0 after remediation.

The finding is now demonstrated by status code *and* by content, not content alone.

## 17. Evidence IDs
- `evidence/findings/V-008-validation.txt` (status codes and byte counts, no key material)
- `evidence/remediation/REMED-before.txt` (vulnerable baseline)
- `evidence/remediation/REMED-after.txt` (remediated instance, side-by-side)
- Regenerate with `bash scripts/capture-verification-evidence.sh`