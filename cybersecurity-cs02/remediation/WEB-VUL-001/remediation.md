# Remediation Record — WEB-VUL-001 (Phase 16)

**Finding:** WEB-VUL-001 — SQL injection authentication bypass
**Application:** http://127.0.0.1:3000 (OWASP Juice Shop v20.2.0, local lab)
**Remediation implemented:** 2026-10-04T15:44+05:30
**Remediation Status:** Remediated (retest: Phase 17)

## Root Cause

The login handler built a raw SQL string by embedding the unsanitised request
values directly into the query text:

```js
models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.body.email || ''}' AND password = '${security.hash(req.body.password || '')}' AND deletedAt IS NULL`, { model: UserModel, plain: true })
```

Because `req.body.email` was concatenated into the SQL, the payload
`' OR 1=1--` rewrote the WHERE clause into a tautology and returned the seeded
admin record, which was then signed into an admin-role JWT.

## File(s) Changed

The deployed artifact is the compiled `build/` tree (started with
`node build/app`; the release package contains no `tsconfig.json`, so a full
TypeScript rebuild is not possible). Both the TypeScript source and its compiled
equivalent were changed identically so source and runtime stay in sync:

1. `lab/juice-shop_20.2.0/routes/login.ts` (source, line ~44)
2. `lab/juice-shop_20.2.0/build/routes/login.js` (compiled, line ~64 — the file actually executed)

## Original Behavior

```text
POST /rest/user/login  {"email":"' OR 1=1--","password":"x"}
→ HTTP 200, {"authentication":{"token":"[admin JWT]","bid":1,"umail":"admin@juice-sh.op"}}
```

Before-evidence: `remediation/WEB-VUL-001/before/EVID-REM-001-sqli-before.txt`
(captured 2026-10-04T15:42:55+05:30 on the unmodified instance), plus original
Phase 10 evidence `evidence/reverification/EVID-REVERIFY-C1-sqli.txt`.

## Mitigation Implemented

Replaced the string-concatenated query with a parameterised query using
Sequelize named `replacements`, so request values are always escaped and bound
as data, never parsed as SQL. The query logic (columns, `deletedAt IS NULL`,
password hashing) is unchanged.

Before (source):

```ts
models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.body.email || ''}' AND password = '${security.hash(req.body.password || '')}' AND deletedAt IS NULL`, { model: UserModel, plain: true })
```

After (source):

```ts
models.sequelize.query('SELECT * FROM Users WHERE email = :email AND password = :password AND deletedAt IS NULL', { model: UserModel, plain: true, replacements: { email: req.body.email || '', password: security.hash(req.body.password || '') } })
```

The identical change was applied to `build/routes/login.js`
(`{ model: user_1.UserModel, plain: true, replacements: { ... } }`).

## Why This Mitigates the Finding

With bound replacements, SQLite receives the email/password only as escaped
literal values; a payload such as `' OR 1=1--` is matched (and fails) as a
plain email string instead of altering the query structure, so the
authentication outcome can no longer be forced.

## Expected Secure Behavior

```text
POST /rest/user/login  {"email":"' OR 1=1--","password":"x"}  → HTTP 401
POST /rest/user/login  valid seeded credentials               → HTTP 200
```

## Application Status After Change

- `node --check build/routes/login.js` → syntax OK
- App started via `scripts/start-lab.sh` → `LAB STATUS: PASS`, HTTP 200 on `/`
- Legitimate login control (seeded lab account) → HTTP 200 with token
- Product API, own-basket read, frontend bundle → HTTP 200
- Full safety check: `remediation/safety-check-phase16.txt`

**Note:** the Juice Shop coding-challenge solvability of the login challenges
(`loginAdminChallenge` etc.) is intentionally altered by this mitigation; no
other behavior was changed.
