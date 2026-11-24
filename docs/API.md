# AutoPièces PHP API

Base URL: `http://<server>/autopieces/api/` (copy the `php` folder to `C:\xampp\htdocs\autopieces\api`).
All answers are JSON: `{"ok": true, ...}` or `{"ok": false, "error": "..."}` with an HTTP error code.
Setup, import order and test accounts are in section "Install" below.

## Install
1. XAMPP: start **Apache** and **MySQL**.
2. Copy `php/` to `C:\xampp\htdocs\autopieces\api`.
3. phpMyAdmin: drop the old `autopieces` database if you imported the first version, then import
   `database/schema.sql`, then `database/seed.sql` (demo data).
4. Open `http://localhost/autopieces/api/ping.php` -> `{"ok":true,"db":"connected"}`.
5. Demo accounts (password `demo1234`): `client@demo.dz`, `mechanic@demo.dz` (Garage El Amel), `shop@demo.dz` (Pièces Auto Demo).

## Login and security
- `POST auth/login.php {role, email, password}` -> `{token, user}`. `POST auth/register.php` also returns a token and
  creates the shop or mechanic profile row. `GET auth/me.php` tells who the token belongs to.
- Send the token on every call: `Authorization: Bearer <token>` (signed HS256 token, 7 days).
- `config.php`: `AUTH_REQUIRED = false` is **development mode**: without a token the server accepts `user_id=<id>` in the
  request, so you can test in a browser. For the demo/defense set `AUTH_REQUIRED = true` and change `JWT_SECRET`
  (the server refuses to run with the default secret). Role rules are always enforced: a client cannot call a
  mechanic endpoint, a shop owner can only touch their own shop, and so on.
- Passwords are hashed with `password_hash`. All SQL uses prepared statements. Photos: JPG/PNG/WebP, 5 MB,
  random file names, script files are refused in `uploads/`.

## Endpoints
| File | Who | What |
|---|---|---|
| `ping.php` | anyone | database check |
| `auth/register.php`, `auth/login.php`, `auth/me.php` | anyone / signed in | accounts |
| `shops.php` | anyone | list, `?id=`, `?lat=&lng=` sorted by distance, rating from reviews |
| `my_shop.php` | shop | read or edit own shop (hours, phone, about, open, delivery, low-stock limit) |
| `parts.php` | anyone, POST: shop | catalogue, `?id=`, `?category=`; POST adds a part (reuses the serial number) and stock |
| `parts_search.php` | anyone | `?q=` (name, serial, alternative serial), `&category=`, `&sort=nearest&lat=&lng=` |
| `stock.php` | GET anyone, POST shop | `upsert`, `adjust` (+/-), `delete`, `bulk_price` (percent, category) |
| `reservations.php` | client, shop | client: `create`, `cancel`, history. Shop: `?as=shop`, `confirm`, `decline`, `complete` (stock -1) |
| `mechanics.php` | GET anyone, POST mechanic | list/search/sort, `?id=`, edit own profile and services |
| `reports.php` | GET anyone, POST mechanic | repair reports: `create`, `update`, `delete`; any user: `helpful` toggle |
| `appointments.php` | client | `create` (also creates the mechanic's job), list with job status, photos, invoice; `cancel` |
| `jobs.php` | mechanic | Jobs tab: `accept`, `decline`, `start`, `finish`, `invoice`, `paid`, `photo` (multipart), `remove_photo` |
| `reviews.php` | GET anyone, POST client | reviews with photos (`photos[]`, max 3); shop needs a picked-up order, mechanic needs a finished job; `reply` by the owner |
| `favorites.php` | client | list and toggle shop / part / mechanic hearts |
| `price_alerts.php` | client | `set`, `delete`, list with current price and `triggered` |
| `shop_stats.php`, `mechanic_stats.php` | shop, mechanic | dashboard numbers (sales / earnings today, week, last week, daily) |
| `chat/send.php`, `chat/messages.php`, `chat/inbox.php` | all | chat (see CHAT_SETUP.md); with `AUTH_REQUIRED` only the two sides of a conversation can read or write |

## How the pieces link together
```
client  --appointments.php create-->  appointment + job_requests row  --> mechanic Jobs tab (jobs.php)
mechanic --jobs.php photo/finish/invoice/paid-->  job_photos, status, invoice
client  --appointments.php GET-->  status, progress photos (uploads/jobs/...), invoice   (works on another phone)
client  --reservations.php create--> shop owner confirms and completes --> stock -1 --> client may review (reviews.php)
shop    --stock.php / parts.php-->  parts_search.php  -->  price_alerts.php (triggered when the cheapest price drops)
chat_messages: client e-mail <-> mechanics.id or shops.id
```
Ids in answers are numbers (`shops.id`, `mechanics.id`...). The app's demo ids (`s1`, `m1`) disappear when `Repo`
is switched to this API.

## Tested
`php/` was tested end to end (about 110 checks: login, roles, stock, reservations, reviews with photos, jobs,
photo upload, invoices, reports, favorites, alerts, stats, chat, tokens, tampered / expired tokens) on PHP 8 with a
SQLite stand-in for MySQL, because MySQL was not available where it was written. The SQL uses only plain
standard statements, but run `ping.php` and a login on your XAMPP first and send any error text if something differs.

## Not done yet (planned)
- Flutter side: `Repo` and `AuthService` still use local demo data; the chat is the only feature that already calls the server.
- Push notifications (the chat polls), Supabase Realtime / Storage (placeholders stay in `config.php`).
- Rate limiting and e-mail verification.
