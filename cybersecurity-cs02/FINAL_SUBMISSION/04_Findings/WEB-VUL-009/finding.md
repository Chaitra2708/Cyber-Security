# WEB-VUL-009 — SQL injection in product search with verbose database error disclosure

## 1. Finding ID
WEB-VUL-009

## 2. Title
Boolean-based SQL injection in `/rest/products/search`, with the SQLite engine and
error message returned to the caller

## 3. Affected Component
OWASP Juice Shop product search API (`/rest/products/search`), Sequelize data layer,
SQLite database (`juiceshop.sqlite`)

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/rest/products/search?q=<payload>`

## 5. HTTP Method
GET

## 6. Security Category
Injection — SQL Injection (A03:2021)

## 7. Description
The `q` search parameter is interpolated into the generated SQL statement instead of
being passed as a bound parameter, so a caller controls the WHERE clause. Injection is
demonstrated by a boolean differential: a tautology returns the whole product catalogue
while a contradiction returns nothing. In addition, a malformed payload produces an
HTTP 500 whose rendered page names the database engine and the driver error message,
so the injection point is self-describing to an attacker.

This is a distinct issue from WEB-VUL-001, which covered SQL injection in the login
endpoint. That login endpoint was re-tested during this session and now rejects every
payload with `401`, yet the identical injection class remains reachable through
product search.

## 8. Technical Details
Row-count differential:

| `q` value | Rows returned |
|---|---|
| `apple` | 3 |
| `zzzznotfound` | 0 |
| `' OR '1'='1` | **46** (entire catalogue) |
| `' AND '1'='2` | 0 |

The tautology/contradiction pair is the signature of boolean-based SQL injection: the
attacker controls the truth value of the query and can therefore extract data
condition by condition, one bit at a time, without any error being raised.

Error-based probe with `q=' OR 1=1--`:
```
HTTP 500
Error: SQLITE_ERROR: incomplete input
```
The response discloses the database engine (SQLite), the driver error code, and the
server's internal parse failure. The same endpoint also returns
`Error: Unexpected path: <path>` for unrouted requests, which confirms internal
routing detail is echoed to clients.

## 9. Reproduction
1. `GET http://127.0.0.1:3000/rest/products/search?q=apple` → 3 records.
2. `GET http://127.0.0.1:3000/rest/products/search?q=' OR '1'='1` (URL-encoded) →
   46 records, the whole catalogue.
3. `GET http://127.0.0.1:3000/rest/products/search?q=' AND '1'='2` (URL-encoded) →
   0 records.
4. `GET http://127.0.0.1:3000/rest/products/search?q=' OR 1=1--` (URL-encoded) →
   `500` with `SQLITE_ERROR: incomplete input` in the page body.

## 10. Observed Behaviour
Attacker-supplied boolean logic is evaluated by the database. Row counts change from 3
to 46 on a tautology and to 0 on a contradiction. Malformed input yields HTTP 500 with
the driver error string.

## 11. Potential Impact
Because the injected expression controls the result set, the whole `Products` table is
already enumerable and the same technique extends to any table joined in the query, or
to any table once the schema is inferred. In this application that includes the `Users`
table addressed in WEB-VUL-006, so an attacker who is not authenticated at all could
reach account data that the authenticated API restricts. The verbose SQLite errors
shorten the path by naming the engine and reporting exactly where parsing failed.

## 12. Severity
High

## 13. Severity Justification
- Reachable without any authentication — the endpoint is public
- Injection is proven by differential result, not inferred
- Extends to data the authenticated API treats as protected
- The error oracle accelerates exploitation
- Not rated Critical because the demonstrated extraction is confined to the public
  product catalogue; escalation to other tables was not attempted, to keep testing
  inside the authorised scope

## 14. Recommendation
Pass all search terms as bound parameters through the ORM's parameter binding so user
input is never concatenated into SQL text. Where free-text search is required, use
parameterised `LIKE` with an escaped wildcard or a dedicated full-text index. Return an
empty result for malformed input instead of propagating the driver error, and map
database exceptions to a generic HTTP 500 in a global error handler so engine names
never reach the client. Re-test by repeating the four requests in section 9; the
tautology must return the same 3 records as `apple`.

## 15. Remediation Status
Not Remediated

## 16. Retest Status
Re-tested — STILL OPEN (re-validated 2026-10-04 against the live baseline, port 3000)

The boolean-differential reproduction was re-run unchanged:

| Query | Rows |
|---|---|
| `apple` | 3 |
| `zzzznotfound` | 0 |
| `' OR '1'='1` | **46** |
| `' AND '1'='2` | 0 |

A tautology returning the whole catalogue while the contradicting predicate returns nothing
shows the database is still evaluating attacker-supplied SQL. No remediation was applied.

Evidence: `evidence/findings/V-009-validation.txt`.

## 17. Evidence IDs
- `evidence/findings/V-009-validation.txt` (row-count differential and error output)
- Regenerate with `bash scripts/capture-verification-evidence.sh`