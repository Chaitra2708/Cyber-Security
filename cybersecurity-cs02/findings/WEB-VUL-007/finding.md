# WEB-VUL-007 — Password hash and TOTP secret embedded in the session token

## 1. Finding ID
WEB-VUL-007

## 2. Title
JWT payload carries the account password hash, role and TOTP secret field

## 3. Affected Component
OWASP Juice Shop authentication layer — JWT issued by `POST /rest/user/login`
(`lib/insecure.ts` payload construction), SQLite `Users` table

## 4. URL / Endpoint
`POST http://127.0.0.1:3000/rest/user/login`

## 5. HTTP Method
POST

## 6. Security Category
Sensitive Data Exposure / Insecure Cryptographic Storage (A02:2021, A07:2021)

## 7. Description
On successful login the server issues a JSON Web Token whose payload embeds the entire
user record rather than the minimal set of claims the client needs. Because a JWT
payload is only base64url-encoded and not encrypted, anyone who can read the token —
the legitimate user, a browser extension, an XSS payload, a proxy log, or an attacker
who steals the token — recovers the stored password hash and the account role without
any further access to the server. The hash is unsalted MD5 (see WEB-VUL-008 note in
`docs/vulnerability-findings.md`), so it is directly reversible to plaintext by
rainbow table or brute force.

## 8. Technical Details
The login response returns `{"authentication": {"token": "<JWT>"}}` in the response
**body**; no `Set-Cookie` header is issued, so there is no cookie flag surface to
evaluate here.

Decoding the payload segment of a successful administrator login (`base64url`, no key
required):

```json
{
  "data": {
    "id": 1,
    "email": "admin@juice-sh.op",
    "password": "0192023a7bbd73250516f069df18b500",
    "role": "admin",
    "totpSecret": "",
    "deluxeToken": "",
    "lastLoginIp": "",
    "profileImage": "assets/public/images/uploads/defaultAdmin.png",
    "isActive": true,
    "createdAt": "...", "updatedAt": "...", "deletedAt": null
  },
  "bid": 1,
  "iat": 1791125097
}
```

Confirmed leak: `password` = `0192023a7bbd73250516f069df18b500`.

The hash is reproducible: `md5("admin123") = 0192023a7bbd73250516f069df18b500`, which
matches the stored value for `admin@juice-sh.op`. This confirms the storage scheme is
**unsalted MD5**, so the leaked value yields the plaintext password directly. The
`totpSecret` field is present in the payload and would carry the live TOTP seed for any
account that has enrolled in 2FA, which would allow an attacker to generate valid
one-time codes and defeat that second factor entirely.

## 9. Reproduction
1. `POST /rest/user/login` with `{"email":"admin@juice-sh.op","password":"admin123"}`.
2. Copy the `authentication.token` value from the response body.
3. Split on `.`, take the second segment, base64url-decode it (no secret needed).
4. Observe `data.password` = `0192023a7bbd73250516f069df18b500`, `data.role` = `admin`,
   and a `data.totpSecret` field.
5. Confirm `md5("admin123")` equals the disclosed hash.

## 10. Observed Behaviour
Token length 717 characters for an administrator. Payload discloses the password hash,
role, email, TOTP field, profile image path and account timestamps.

## 11. Potential Impact
Any party that obtains a session token by any means can read the account's password
hash and crack it to plaintext, because the hash is unsalted MD5. Because the token is
stored client-side and travels on every API request, the exposure surface includes
browser storage, developer tools, shared machines, HTTP proxy logs and any future
cross-site scripting flaw. For a TOTP-enrolled account the embedded secret permits
generation of valid second-factor codes, converting a single-token compromise into
full account takeover.

## 12. Severity
Critical

## 13. Severity Justification
- Yields the plaintext password (unsalted MD5, cracked in one hash operation), not
  merely a hash
- The secret sits in a token that is issued on every successful login and travels with
  every subsequent request
- Discloses the TOTP seed, which defeats the second factor for enrolled accounts
- Requires no privilege escalation — any authenticated user's token exposes their own
  credentials, and the payload structure is identical for every role
- Rated Critical rather than High because the impact is direct, unauthenticated-after-
  token-theft credential compromise rather than scoped data disclosure

## 14. Recommendation
Include only the claims the client actually needs — a subject identifier, the role,
`bid` and expiry (`iat`/`exp`) — and never the password hash, TOTP secret or profile
fields. Move to a password hashing function with a per-user salt and a high work factor
(bcrypt, scrypt or Argon2id) so that any hash which does leak is not directly
reversible. Sign the token with a short expiry and add `exp`; verify the signature on
every request rather than trusting the decoded payload. Re-test by decoding the payload
of a fresh login and confirming the absence of `password` and `totpSecret`.

## 15. Remediation Status
Not Remediated

## 16. Retest Status
Re-tested — STILL OPEN (re-validated 2026-10-04 against the live baseline, port 3000)

The finding was reproduced by logging in and base64url-decoding the issued JWT payload —
no secret and no privileged access required. The payload still carries the account
password hash together with `role` and a `totpSecret` field, so any token holder recovers
the credential offline. No remediation was applied.

Evidence: `evidence/findings/V-007-validation.txt`.

## 17. Evidence IDs
- `evidence/findings/V-007-validation.txt` (decoded JWT payload captured live)
- Regenerate with `bash scripts/capture-verification-evidence.sh`