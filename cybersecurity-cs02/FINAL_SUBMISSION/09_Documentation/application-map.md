# Application Map

## 1. Scope

Application mapping of the authorised laboratory target `http://127.0.0.1:3000`
(OWASP Juice Shop v20.2.0). Mapping is based on **actual observation only** — rendered
DOM via headless Chrome, HTTP response headers, live API probing, and application storage
inspection. Routes or APIs were added only when observed.

**Authorized target:** `http://127.0.0.1:3000`
**Authorized scope:** `127.0.0.1:3000` ONLY.

## 2. Application Entry Point

| Field | Value |
|---|---|
| Application | OWASP Juice Shop (deliberately vulnerable training application) |
| URL | `http://127.0.0.1:3000/` |
| Protocol | HTTP |
| Host | `127.0.0.1` |
| Port | `3000` |
| Main page / title | `<title>OWASP Juice Shop</title>` |
| Observed behaviour | SPA shell populated by an Angular app; product grid, nav, and login/register UI rendered on `/` plus every hash route |
| Technology | Node.js Express backend (served by a `node build/app` process) + Angular SPA frontend |
| Application storage | `data/juiceshop.sqlite` (SQLite, see Section 7) |

**Isolation:** the server listens on `127.0.0.1:3000` only. The LAN IP
(`10.45.57.195`) is unreachable from the host (`HTTP 000`) — the lab is loopback-isolated.

## 3. Technology Identification

| Category | Confirmed |
|---|---|
| Frontend framework | **Angular** SPA (rendered via `main.js`; `app-root` present) |
| Backend framework | Node.js + Express (`node build/app`) |
| Application database | SQLite (`data/juiceshop.sqlite`); users table has a `password` column (plaintext-md5, see Assessment) |
| Web server | Express/Node process (no separate Apache/nginx) |
| API style | JSON REST under `/api/` and `/rest/` |
| Session mechanism | JWT bearer token returned by `/rest/user/login`; stored by the client |
| Authentication | Custom JSON login; seeded user table with `password` field (md5 of seeded values) |
| External assets | Google Fonts (loaded by the SPA; do not confuse with application security) |

> Exact third-party dependency versions (Express, Angular, sqlite3, etc.) are NOT
> CONFIRMED during this assessment from the available evidence.

## 4. Route / Page Map

| Route | Function | Authentication | Observed behaviour | Evidence |
|---|---|---|---|---|
| `/#/` (Home) | Product catalog + hero | Public | Renders `All Products`, `Apple Juice`, nav | EVID-MAP-002 |
| `/#/login` | Login form (`Email`, `Password`) | Public | 211 KB page with login form | EVID-MAP-002 |
| `/#/register` | Registration form (`Email`, `Password`, `PasswordRepeat`, security question) | Public | 236 KB page with register form | EVID-MAP-002 |
| `/#/search` | Product search | Public | Same rendered size as Home | EVID-MAP-002 |
| `/#/basket` | Shopping basket | Public (shows anonymous basket) | `Your Basket (anonymous)` | EVID-MAP-002 |
| `/#/about` | About / company | Public | Rendered | EVID-MAP-002 |
| `/#/contact` | Feedback / contact form (`Author Comment`, `Rating`, CAPTCHA) | Public | 204 KB page | EVID-MAP-002 |
| `/#/score-board` | CTF score board | Public | 600 KB page, verbose | EVID-MAP-002 |
| `/#/administration` | Admin area (login-gated) | **403** for unauthorised | `403 You are not allowed to access this page` | EVID-MAP-002 |
| `/#/profile` | Profile view | Redirects when not authenticated | Same bytes as Home | EVID-MAP-002 |
| `/#/order-history` | Order history | Public (shows "No results found") | 185 KB page | EVID-MAP-002 |
| `/#/recycle` | Recycle / trash | Public | Rendered, limited items | EVID-MAP-002 |
| `/#/premium-wallet` | Premium wallet UI | Public | Same size as Home (likely gated) | EVID-MAP-002 |
| `/#/track-result` | Order tracking | Public | Rendered | EVID-MAP-002 |

## 5. Functional Map

| Function | Location | Input | Expected purpose | Authentication requirement | Evidence |
|---|---|---|---|---|---|
| Login | `/#/login` form → `POST /rest/user/login` | Email, Password | Sign in | Public | EVID-MAP-002; run separately |
| Registration | `/#/register` form → `POST /api/Users` | Email, Password, confirm, security question | Self-signup | Public | EVID-MAP-002 |
| Logout | app UI (server-side JWT logout) | none | clear session | authenticated | app UI |
| Products | `/#/search`, product cards | category/search/filter | catalogue view | Public | EVID-MAP-002 |
| Product details | `/#/products/:id` → `GET /api/Products/:id` | product id | details | Public | EVID-MAP-002; API table |
| Basket | `/#/basket` | none (anonymous) | view cart | Public | EVID-MAP-002 |
| Checkout | app UI → `POST /rest/basket/:id/order` | address / coupon | purchase flow | authenticated | app UI |
| Feedback / contact | `/#/contact` form → feedback API | Author, Comment, Rating, CAPTCHA | leave feedback | Public | EVID-MAP-002 |
| Score board | `/#/score-board` | none | CTF scoreboard | Public | EVID-MAP-002 |
| Administration login | `/#/administration` → admin API | credentials | admin area | Admin only | EVID-MAP-002 |
| Profile | `/#/profile` | none | my account | **redirects unauthenticated** | EVID-MAP-002 |
| Order history | `/#/order-history` | none | my orders | Public (empty) | EVID-MAP-002 |
| API backend | `/api/*`, `/rest/*` | JSON | programmatic access | varies (see API map) | Section 8 |

## 6. Input / Attack-Surface Map

| Input ID | Location | Input type | Parameter / field | Purpose | Authentication |
|---|---|---|---|---|---|
| INP-01 | Login form | text | `Email` | identify user | Public |
| INP-02 | Login form | text | `Password` | authenticate | Public |
| INP-03 | Register form | email | `Email` | create account | Public |
| INP-04 | Register form | text | `Password` | set password | Public |
| INP-05 | Register form | text | `PasswordRepeat` | confirm password | Public |
| INP-06 | Register form | text | `SecurityQuestion` | CAPTCHA-like second factor | Public |
| INP-07 | Search box | text | `q` (GET param) | product search | Public |
| INP-08 | Basket | id | `basketId` (path) | item selection | none (public) |
| INP-09 | Checkout | address / coupon | order fields | purchase | authenticated |
| INP-10 | Feedback form | text | `author`, `comment`, `rating`, `captcha` | send feedback | Public |
| INP-11 | API | JSON body | arbitrary body to `/api/*` and `/rest/*` | programmatic | varies |

## 7. Authentication / Authorization Surface

**Authentication (observed):**

- Registration: public, via `/api/Users` (with confirmation + security question).
- Login: public, via `POST /rest/user/login` → returns a JWT bearer token.
- Logout: UI-level (server-side JWT revocation is app-specific, not confirmed).
- Session: JWT stored on the client; authenticated pages redirect when no token is
  present (`/#/profile` and `/#/premium-wallet` render the public Home page when
  unauthenticated).

**Authorization (observed):**

- `/#/administration` returns **403** to unauthenticated users.
- `/api/Users` returns **401** when unauthenticated.
- `/rest/basket/*` returns **401** when unauthenticated.
- Certain admin-only and user-only functionality was **not** probed for role/ownership
  enforcement during this phase — that is a Phase 13 assessment item, not Phase 9.

> The **existence of administrative routes does not by itself prove broken
> authorization**. This section records only what was observed.

## 8. API / Backend Map

| Method | Endpoint | Purpose | Authentication | Observed response | Evidence |
|---|---|---|---|---|---|
| GET | `/api/Products` | product catalogue | Public | 200 JSON | EVID-MAP-002, API table |
| GET | `/api/Products/:id` | single product | Public | 200 JSON | API table |
| GET | `/api/Feedbacks` | user feedback | **none reported** | 200 JSON | EVID-VAL-005 |
| GET | `/api/Users` | user list | required (401) | 401 HTML | API table |
| GET | `/api/Challenges` | challenge list | Public | 200 JSON (66 KB) | API table |
| POST | `/api/Users` | register | none | 201 / 409 | app UI |
| POST | `/rest/user/login` | authenticate | none | 401 or 200 + JWT | EVID-MAP-002 |
| GET | `/rest/user/whoami` | current user | JWT | 200 | API table |
| GET | `/rest/captcha` | captcha payload | none | 200 | API table |
| GET | `/rest/languages` | languages | none | 200 | API table |
| GET | `/rest/admin/application-version` | version | JWT | 200 `{"version":"20.2.0"}` | EVID-VAL-004 |
| GET | `/metrics` | Prometheus metrics | none | 200 telemetry | EVID-VAL-004 |
| GET | `/rest/basket/:id` | one basket | JWT | 200 or 401 | EVID-VAL-002 |
| GET | `/rest/basket` | own basket | JWT | varies | app UI |
| GET | `/rest/products/search` | search | none | 200 JSON | API table |
| GET | `/rest/memories` | memories feature | JWT | 200 | API table |
| GET | `/rest/captcha` | captcha | none | 200 | API table |
| GET | `/rc/` | static SPA route | none | 200 | (confirmed) |
| GET | `/sitemap.xml` | sitemap | none | redirects to SPA | (confirmed) |
| GET | `/robots.txt` | crawl hints | none | 200 | EVID-VAL-004 |

## 9. Data Flow / Trust Boundaries

```
Browser (Chrome / headless)
   |
   | HTTP/JSON
   v
Web Application  (Express on 127.0.0.1:3000)
   |
   | SQLite reads/writes
   v
Application database  (data/juiceshop.sqlite - users, products, baskets, orders, feedback)
```

- **User-controlled data enters** at the HTML forms (login, register, search, feedback),
  the JSON APIs (`/api/*`, `/rest/*`), and URL parameters (`basket/:id`, `q`).
- **Where it is processed** is not fully mapped here — exact query construction and
  session handling would be a Phase 16 source-review task.

> The database/backend relationship is observed as: the app process reads and writes a
> **locally bundled SQLite file**. The raw SQL layer is **NOT CONFIRMED** from the
> available evidence.

## 10. Evidence References

| Evidence ID | Description | File |
|---|---|---|
| EVID-MAP-001 | Application entry point (headers + title) | evidence/scanner-results/ |
| EVID-MAP-002 | Route/page observation via headless Chrome | evidence/scanner-results/ |
| EVID-SCREENSHOT-001 | Running app screenshot | evidence/screenshots/ |
| RECON-001 / RECON-002 | Reconnaissance | evidence/scanner-results/ |

## 11. Limitations

- Routes are Angular hash routes (`/#/...`); the server serves the SPA on any hash
  route, so a plain `/login` URL would return the SPA shell.
- Only the most significant UI routes were rendered and text-extracted.
- API endpoints were probed; unmapped `/rest/*`/`/api/*` paths were not exhaustively
  tested.
- Resource-exhaustion, file-upload, and WebSocket-style channels were not assessed here.
