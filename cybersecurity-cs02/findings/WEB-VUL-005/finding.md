# WEB-VUL-005 — Unauthenticated exposure of user feedback

## 1. Finding ID
WEB-VUL-005

## 2. Title
User feedback data returned without authentication

## 3. Affected Component
OWASP Juice Shop feedback API (`GET /api/Feedbacks`), SQLite application database

## 4. URL / Endpoint
`GET http://127.0.0.1:3000/api/Feedbacks`

## 5. HTTP Method
GET

## 6. Security Category
Sensitive Data Exposure / Broken Access Control

## 7. Description
The API endpoint that returns customer feedback (including masked email addresses and
ratings) returns it without requiring authentication. Even though the emails are masked,
the endpoint leaks user-generated content and user IDs to any caller, and the mechanism
is inconsistent: the same API surface that exposes feedback returns 401 for `/api/Users`.

## 8. Technical Details
**Observed request:** `GET /api/Feedbacks` with no Authorization header.
**Observed response** (record 1 retained, email masked):
```json
{"status":"success","data":[{"UserId":1,"id":1,
  "comment":"I love this shop! Best products in town! Highly recommended! (***in@juice-sh.op)",
  "rating":5,...}]}
HTTP 200
```

**Control:** `GET /api/Users` without a token returns HTTP 401.

**Evidence IDs:**
- Historical: `evidence/responses/WEB-VUL-005-feedbacks.json`
- Current-instance validation: `EVID-REVERIFY-C5-feedback.txt`

## 9. Reproduction
1. Open `http://127.0.0.1:3000`.
2. Issue `GET http://127.0.0.1:3000/api/Feedbacks` with no Authentication header.
3. Observe HTTP 200 with records containing `UserId`, a masked email address and a rating.
4. Comparison: the same caller can read feedback but `/api/Users` (also sensitive) is
   locked with 401 — the exposure boundary is inconsistent.

## 10. Observed Behaviour
The endpoint returns feedback records without authentication. User IDs and partially
masked email addresses are exposed.

## 11. Potential Impact
The observed behaviour may allow a visitor to collect user-generated content, user IDs
and email addresses (masked) anonymously. In the laboratory this demonstrates an
unintentional information-disclosure boundary; in production it can amplify
phishing/spam mailing lists and user-profiling.

## 12. Severity
Low

## 13. Severity Justification
- The data exposed is non-critical: masked emails and content, not credentials or full PII
- No special privileges are required beyond being able to reach the endpoint
- The endpoint is read-only and the application is a local, isolated training app
- The finding is a genuine but low-severity misconfiguration/design inconsistency

## 14. Recommendation
Require authentication for `/api/Feedbacks` (or restrict it to the authenticated user's
own feedback). Make the access-control boundary consistent across all `/api/*` read
endpoints, then re-test the request with and without a token.

## 15. Remediation Status
Not Remediated

## 16. Retest Status
Not Retested

## 17. Evidence IDs
- `evidence/responses/WEB-VUL-005-feedbacks.json` (historical response)
- `EVID-REVERIFY-C5-feedback.txt` (current-instance re-verification)
