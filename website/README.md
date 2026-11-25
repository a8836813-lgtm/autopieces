# AutoPièces website (React)

The website uses the same PHP / MySQL API as the phone app, so both share the same accounts and data.
Pages: client (search, shops, mechanics, reports, orders, appointments, saved, messages), shop owner
(dashboard, stock, orders, reviews, messages, my shop) and mechanic (dashboard, jobs with photos and invoice,
reports, reviews, messages, profile).

## Run it
1. Start Apache and MySQL in XAMPP, with the API installed (see `docs/API.md`).
2. Install Node.js (LTS) from https://nodejs.org.
3. In a terminal, in this `website` folder:
   ```
   npm install
   copy .env.example .env
   npm run dev
   ```
4. Open http://localhost:5173 and log in with a demo account (password `demo1234`): `client@demo.dz`, `mechanic@demo.dz`, `shop@demo.dz`.

## Settings (`.env`)
| Name | Meaning | Default |
|---|---|---|
| `VITE_API_BASE` | PHP API address | `http://localhost/autopieces/api` |
| `VITE_SUPABASE_URL` | Supabase project URL (placeholder) | `YOUR_SUPABASE_URL` |
| `VITE_SUPABASE_ANON_KEY` | Supabase anon key (placeholder) | `YOUR_SUPABASE_ANON_KEY` |

To open the site from a phone on the same Wi-Fi, set `VITE_API_BASE=http://<PC-IP>/autopieces/api`, run `npm run dev`
and open `http://<PC-IP>:5173`.

## Put it on XAMPP
`npm run build`, then copy the content of `dist` to `C:\xampp\htdocs\autopieces\site` and open `http://localhost/autopieces/site/`.
Before a public demo, set `ALLOWED_ORIGIN` in `php/config.php` to the website address.

## Files
- `src/api.js` requests with the login token (kept in the browser), `src/auth.jsx` login and sign-up, `src/config.js` settings.
- `src/pages/` one file per page, `src/App.jsx` menus by role.
