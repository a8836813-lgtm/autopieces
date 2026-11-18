# PROJECT_CONTEXT.md (version 5, 2026-11-18)

> Replaces version 4. Upload to the Claude Project and start every new chat with:
> "Read PROJECT_CONTEXT.md, today we work on X."
> End each session with: "Update PROJECT_CONTEXT.md: what we did, decisions, next task."
> **Standing rule: every update must include the links to the PHP files and the Supabase items touched or planned (section 9.7 and the session log). If there is nothing yet, write `none yet`, never skip it.**
> Sections marked **[PLACEHOLDER]** are reserved for the PHP and Supabase work: fill them in as decisions are made.

## 1. The project in one paragraph
Graduation project (PFE) of Aymen (Master, Networks and Security, University of Jijel) with teammates. A **local marketplace for car parts**: shops that sell mechanical parts register and publish their stock; a client searches for a part (by text, serial number, vehicle, or camera scan) and gets the **shops that have that exact part in stock, with price, distance, rating and opening hours**. The platform also has a **mechanics directory** with ratings, reviews and detailed **repair reports** that clients can search by problem.

## 2. Important decisions (and why)
| Decision | Reason |
|---|---|
| **Prototype only, not a working product** (confirmed by a teacher) | The college only needs a prototype to graduate. |
| **Local shops instead of international markets** (teacher's advice) | Real data, no customs/shipping, fits Algeria, easier to defend. International search stays a roadmap item. |
| **Keep the camera scanner** | The standout feature. Multi-photo scan, used by clients and shop owners. |
| **Mobile app in Flutter** | Chosen by Aymen. |
| **Payments simulated**, never store card numbers | Avoids PCI DSS issues, good security talking point. |
| **Three separate account types: client, mechanic, shop owner** (new) | Each has its own login, sign-up fields and home screen. |
| **Part serial number search is universal** (new) | A serial number identifies the part regardless of brand, so it works alone or combined with a vehicle. |
| **Backend: PHP API + Supabase** (new, **to confirm**, replaces the earlier FastAPI + PostgreSQL idea) | The team will use PHP to link the app to the database. Supabase is hosted PostgreSQL, so the data model in section 8 does not change. See section 9. |

## 3. Team and supervision
- Supervisor: **Dr Hilali**. He has no PFE subject of his own yet and offered to meet to discuss a student idea.
- Team: a group of 4 was discussed. Suggested split: backend and security / web frontend / mobile app and scan / data, admin and testing, with one owner for the thesis.
- Emails drafted (not confirmed sent): presentation to Dr Hilali (French) and a reply proposing a meeting (English). Placeholders still to fill: last names, phone, teammates' names and roles.
- Questions to ask him: can the project have 4 members, which diagram notation (UML), what the jury expects, defense date.

## 4. Features
**Client**
- Home with a "Shops near you" slider and a search bar.
- **Search by serial number, by vehicle (brand and model), or by text** (e.g. "front brake Golf 7"). Results show piece, shop, price, distance, stock, rating, hours, with Call and Reserve. Sort by best match, nearest, cheapest.
- **Multi-photo camera scan**: 3 to 6 photos, OCR reads part numbers or tire sizes, top 3 candidates, user confirms, then the shops list.
- Profile (simulated payment), mechanics directory with map, ratings, comments, repair reports searchable by problem.

**Shop owner ("shop mode")**: scan a part on the shelf to update quantity, price and condition, or add a listing; stock list; incoming reservations (confirm).

**Mechanic**: publishes repair reports (problem, diagnosis, work done, parts, cost, photos), has a profile with ratings.

## 5. Business model
- Shop subscription plus paid featured placement.
- Pay-per-lead or small fee per confirmed reservation (count every Call and Reserve click).
- Mechanic subscription about 10 USD per month (consider a free tier).
- Ads.
- The old "1% commission" only works when the platform handles payment, so it is weak for local sales.
- **Leakage risk** (users take the phone number and leave): charge shops instead of transactions, log contact reveals, "reserve and pay at pickup", reviews only for completed reservations, fitment checks.

## 6. Scanner design
- Several photos per part, results combined by voting or averaging confidence.
- OCR on every photo for part numbers and tire sizes (e.g. 205/55 R16) gives an exact match when found.
- Visual matching against reference photos (image embeddings, nearest neighbor) to tell which brake disc.
- Honest limits: only parts in the seeded catalog (30-50 for the demo), lighting matters, used parts look different.
- In the prototype the scanner is a **mock** behind the `PartScanner` interface.

## 7. Flutter app (project `autopieces`)
**Source of truth: GitHub, private repo `a8836813-lgtm/autopieces`.** Claude clones it, works on a separate branch and pushes; Aymen fetches and pulls in GitHub Desktop, tests, then merges into `main`. Keep the repo folder outside OneDrive. Never commit `.env`, keys or passwords.

**Branches:** `main` (Aymen's original working version, untouched by Claude), `feature/vehicle-search-wiring` (vehicle and serial search wired in), `feature/roles-and-polish` (everything in 7.5 and the start of 7.6, built on top of the previous branch; this is the branch to test and continue on). Claude never pushes to `main`.

**Status: written but never compiled by Claude** (Flutter is not available in the build environment). Aymen runs it on his Android phone and pastes errors back. Expect small errors on the first `flutter analyze`.

**Important rule:** this project imports Material from `package:material_ui/material_ui.dart` (not `package:flutter/material.dart`) in every Dart file. Mixing the two causes "No MaterialLocalizations found" at runtime (seen 2026-11-17 on `VehicleSearchScreen`, fixed by using `material_ui` in all new files). `package:flutter/foundation.dart` is fine to import.

### 7.1 Delivered earlier (`autopieces.zip`, 22 files)
Home, results, multi-photo scan, confirm the part, mechanics and reports, profile, shop mode, mock data in `lib/data/repo.dart`.

### 7.2 Added this session: login and sign-up (`autopieces_auth.zip`)
| File | Purpose |
|---|---|
| `lib/services/auth_service.dart` | `UserRole` (client, mechanic, shop), `AppUser`, in-memory mock `AuthService` with demo accounts |
| `lib/services/validators.dart` | email, Algerian phone (05/06/07), password (8+ chars, letters and digits), confirm, years |
| `lib/widgets/auth_widgets.dart` | `AuthScaffold`, text/password/dropdown fields, error banner, submit button, role icons and titles |
| `lib/screens/auth/role_select_screen.dart` | "I am a client / mechanic / shop owner" |
| `lib/screens/auth/login_screen.dart` | per-role login, "Use demo account", wrong-role hint |
| `lib/screens/auth/signup_screen.dart` | per-role sign-up fields |
| `lib/screens/auth/home_router.dart` | `homeForUser()` by role, `logoutToRoleSelect()`, placeholder home for mechanic and shop |
| `lib/main.dart` | now starts on the role screen |

- **Sign-up fields.** Common: name, email, phone, password, confirm, terms. Client adds wilaya. Mechanic adds garage name, specialty, years of experience, wilaya. Shop owner adds shop name, shop type, address, wilaya, optional commercial register number.
- **Demo accounts** (password `demo1234`): `client@demo.dz`, `mechanic@demo.dz`, `shop@demo.dz`.
- **Still to do:** point the shop role to the existing shop mode screen, build the mechanic dashboard, add a Log out button in Profile calling `logoutToRoleSelect(context)`.

### 7.3 Added this session: vehicle and serial search (`autopieces_vehicle_search.zip`)
| File | Purpose |
|---|---|
| `lib/data/vehicles.dart` | 24 car brands and 15 truck brands with models (starter list) |
| `lib/models/search_query.dart` | `SearchQuery` (type, brand, model, serial) and serial normalization and validation |
| `lib/widgets/brand_logo.dart` | shows `assets/brands/<id>.png`, falls back to brand initials |
| `lib/widgets/vehicle_search_panel.dart` | serial field, Cars/Trucks switch, brand grid, model chips |
| `lib/screens/vehicle_search_screen.dart` | full screen that returns a `SearchQuery` |

- **Logos are not included.** Download official PNGs from each brand's press kit, name them by id (`renault.png`, `volvo_trucks.png`, `mercedes_trucks.png`), put them in `assets/brands/` and declare `assets/brands/` in `pubspec.yaml`.
- **Serial normalization:** uppercase letters and digits only, 4 to 30 characters.
- **Not wired yet:** the results screen must filter inventory by `q.serial`, `q.brand`, `q.model`.

### 7.5 Added 2026-11-18 (branch `feature/roles-and-polish`)
- **Mechanic dashboard** (`screens/mechanic_shell.dart`, `report_edit_screen.dart`): My reports list, "New report" form (title, car, problem, diagnosis, work done, parts used, cost), profile with rating and client reviews, log out. Mechanic role now lands here.
- **Client Saved tab** (`screens/saved_screen.dart`): reservations with status (Pending, Confirmed, Completed, Cancelled), cancel, rate the shop after pickup; favorite shops and favorite parts. `ClientShell` now has 4 tabs: Search, Mechanics, Saved, Profile.
- **Reviews and ratings** (`widgets/review_widgets.dart`): stars, review sheet, review list. Shop reviews only after a completed reservation (leakage rule); mechanics can be rated from the mechanics list. Shop page has a favorite heart and reviews.
- **Nearby map** (`screens/nearby_map_screen.dart`): radar-style prototype (distance and direction), opened from the "Map" button on Home. Replace with a real map package once GPS exists.
- **Shop dashboard upgrade** (`screens/shop_shell.dart`, `add_part_screen.dart`): add a part by serial number (existing catalog part is found, a new part gets name, category and fitment), Insights tab (page views, calls, reservations, rating, low stock, reviews), "Confirm" then "Picked up" on reservations (stock drops by one).
- **Polish:** Home and Profile show the logged-in user; "OEM" label renamed "Serial"; every Call click is logged (`Repo.logCall`, the future CONTACT_REVEALS lead); logout in Profile, shop mode and mechanic space.
- **Data layer** (`data/models.dart`, `data/repo.dart`): `Review`, `Fitment`, `Shop.bearing`, `RepairReport.parts`, `Reservation.status/reviewed`; `Repo` has favorites, reviews, reservation lifecycle, stats counters, `addReport`, `addPart`, `partBySerial`, `searchVehicle`. All still in memory: this is what gets replaced by the PHP + Supabase API.

### 7.6 Mechanic page redesign (futuristic) **IN PROGRESS**
Request (2026-11-18): make the mechanic page much more appealing and futuristic, with as many features as possible.

**Done (written, in `lib/`, not yet used by any screen):**
- `theme_mechanic.dart`: dark neon palette `MechColors` (navy background, cyan, violet, lime, amber) and `buildMechanicTheme()`.
- `widgets/mech_widgets.dart`: `GlowCard`, `NeonButton`, `PulseDot` (radar-style pulse), `AnimatedNumber` (count-up), `RingGauge` (animated glowing ring), `Sparkline` (self-drawing line chart), `GridBackdrop` (grid and glows), `MechSectionTitle`, `JobStepper` (Requested, Accepted, Working, Done).

**Not done yet (planned design, build in this order):**
1. **Data:** `JobRequest` model (client, car, problem, distance, price, slot, status New / Accepted / In progress / Done / Declined) and `Repo` methods: `jobs` (seed 5 to 6), `acceptJob`, `declineJob`, `startJob`, `finishJob` (adds the price to today's earnings), `mechanicAvailable`, `mechanicPro`, `weeklyEarnings` (7 days) and `weekEarnings`.
2. **Rebuilt `mechanic_shell.dart`** (wrapped in the dark theme, 4 tabs):
   - **Dashboard:** time-based greeting, availability switch with pulse dot, animated stat tiles (reports, jobs done, rating, week earnings), weekly earnings sparkline with change versus last week, three ring gauges (rating, response rate, completion rate, computed from real jobs), quick-action grid (New report, Diagnose, Estimate, Find a part, Scan a part with the existing camera scanner, Jobs), "Up next" schedule, and a tip pointing at the next locked badge.
   - **Jobs:** New / Active / Done filter, job cards with stepper and Accept, Decline, Start, Mark as done.
   - **Reports:** search box over own reports, restyled cards, New report button.
   - **Profile:** level and XP bar (XP from reports, jobs and reviews), badges (First report, Storyteller, Top rated, 5-star, Trusted, Pro member), Pro plan card (demo upgrade, about 10 USD per month, simulated), reviews, log out.
3. **`mechanic_diagnostic_screen.dart`:** OBD-II trouble code lookup (about 15 common codes with meaning and likely causes, in a new `data/obd_codes.dart`) and symptom search over existing repair reports. Label it a rule-based demo, not real AI.
4. **`estimate_screen.dart`:** labor hours times rate, parts cost, discount percent, optional TVA 19%, total, copy summary.
5. Restyle `report_edit_screen.dart` for the dark theme (field fill and border colors, wrap in `buildMechanicTheme()`).
6. Small link to the client side: in `mechanics_screen.dart`, show "Premium" when the mechanic is Pro and "Available now" when the switch is on.

### 7.4 How to run
1. Install Flutter and Android Studio (or a phone with USB debugging).
2. In the project folder: `flutter create .`, delete the generated `test/widget_test.dart`, keep our `lib/`.
3. Android: `minSdk` 21+ and CAMERA permission. iOS: `NSCameraUsageDescription` in `Info.plist`.
4. `flutter pub get`, then `flutter run`.

## 8. Data model (local-shop version; DATA_MODEL.md v1 is OUT OF DATE)
- Remove `SELLERS`, `LISTINGS`, `source_market`, `ORDERS.commission`.
- `USERS` with a `role` (client, mechanic, shop). Role-specific profile data (see sign-up fields in 7.2).
- `SHOPS` (name, type, address, wilaya, location, hours, phone, rating, subscription, commercial register no.).
- `MECHANIC_PROFILES` (garage, specialty, years, wilaya, rating).
- `PARTS` (**serial number / part number**, name, category) and a **compatibility table** `PART_FITMENT` (part, brand, model, optional years). Needed for serial and vehicle search.
- `BRANDS` (id, name, type car or truck) and `MODELS` (brand, name), mirroring `vehicles.dart`.
- `INVENTORY` (shop, part, price, quantity, condition, last_checked_at).
- `RESERVATIONS` (client, inventory item, status, fee).
- `PART_IMAGES` (reference photos plus embedding), `SCAN_SESSIONS` (photos, combined result, who scanned), `CONTACT_REVEALS` (lead logging).
- Keep: vehicles, repair reports (full-text search), reviews, subscriptions, ads, cross-references.
- Distance: Haversine on latitude and longitude.

## 9. Backend: PHP + Supabase **[PLACEHOLDER]**
Decision status: the team will use **PHP to link the app and the database** and **Supabase** as the database host. Supabase is PostgreSQL, so section 8 applies as is.

### 9.1 Architecture (to confirm)
- [ ] **Option A (recommended for security):** Flutter app -> **PHP API** -> Supabase PostgreSQL (PDO `pgsql`). All business rules and role checks live in PHP.
- [ ] Option B: Flutter app -> Supabase directly (REST/Auth/RLS), PHP only for extra jobs.
- Chosen option: `TODO`
- PHP hosting (local XAMPP/Laragon for the demo, or a free host): `TODO`
- PHP framework or plain PHP: `TODO`

### 9.2 Supabase project **[PLACEHOLDER]**
- Project name: `TODO`
- Region: `TODO`
- Project URL: `TODO` (kept in `.env`, never committed)
- Keys: the **anon/public key** may be used in the app only if Row Level Security is on. The **service_role key and the database password must never be in the Flutter app or in git.**
- Auth: use Supabase Auth or own `users` table with hashed passwords in PHP: `TODO`
- Row Level Security policies per role: `TODO`
- Storage buckets (part photos, reference images, report photos): `TODO`

### 9.3 PHP configuration **[PLACEHOLDER]**
`.env` (not committed; commit only `.env.example` with empty values):
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
DB_HOST=
DB_PORT=5432
DB_NAME=postgres
DB_USER=
DB_PASSWORD=
JWT_SECRET=
```
Suggested PHP layout:
```
api/
  config/        env loader, database connection (PDO)
  auth/          register.php, login.php, logout.php, me.php
  parts/         search.php (q, serial, brand, model, lat, lng)
  shops/         list.php, inventory.php, reserve.php
  mechanics/     list.php, reports.php
  scan/          upload.php
  lib/           helpers, validators, role middleware
```

### 9.4 API contract **[PLACEHOLDER]**
| Endpoint | Method | Role | Notes |
|---|---|---|---|
| `/auth/register` | POST | public | body: role plus role-specific fields (see 7.2) |
| `/auth/login` | POST | public | returns token and user |
| `/parts/search` | GET | any | params: `serial`, `brand`, `model`, `q`, `lat`, `lng`, `sort` |
| `/shops/{id}/inventory` | GET/POST/PATCH | shop | owner only |
| `/reservations` | POST/PATCH | client / shop | |
| `/mechanics/{id}/reports` | GET/POST | any / mechanic | |
| `TODO` | | | |

### 9.5 Security checklist for the thesis
- Passwords hashed server-side (`password_hash` with Argon2/bcrypt), never stored in plain text.
- Prepared statements only (PDO) to prevent SQL injection.
- Role checked on every endpoint in PHP, not only in the app.
- Short-lived token (JWT or session), HTTPS in any deployment.
- Rate-limit login, validate and sanitize all input, limit upload size and type.
- Secrets in `.env`, outside the web root, out of git.

### 9.6 Flutter side **[PLACEHOLDER]**
- Replace `AuthService` mock bodies (`login`, `signUp`) with HTTP calls: `TODO` (package such as `http` or `dio`).
- Replace `lib/data/repo.dart` with API calls: `TODO`.
- API base URL setting: `TODO`.
- Secure token storage (e.g. `flutter_secure_storage`): `TODO`.

### 9.7 Backend links (UPDATE EVERY SESSION) **[PLACEHOLDER]**
Rule: whenever a session touches the backend or the Flutter-to-backend link, update this table and add the same links to the session log. Use full GitHub links (branch `feature/roles-and-polish` unless merged) and mark status: `planned`, `written`, `tested`.

**PHP (API between the app and the database)**
| Item | Link or path | Status |
|---|---|---|
| PHP API folder | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend (not created yet) | planned |
| Database connection (PDO to Supabase PostgreSQL) | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend/config/database.php | planned |
| Auth endpoints (register, login, me) | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend/auth/ | planned |
| Parts search endpoint | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend/parts/search.php | planned |
| Shops, inventory, reservations | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend/shops/ | planned |
| Mechanics, reports, jobs | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/backend/mechanics/ | planned |
| `.env.example` (no real keys) | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/.env.example | planned |
| Hosting / base URL of the PHP API | `TODO` | planned |

**Supabase**
| Item | Link or path | Status |
|---|---|---|
| Supabase project dashboard | `TODO` (paste the project URL here) | planned |
| API URL (public, safe to write here) | `TODO` | planned |
| SQL schema file (tables from section 8) | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/supabase/schema.sql | planned |
| Row Level Security policies | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/supabase/policies.sql | planned |
| Seed data (demo shops, parts, fitments) | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/supabase/seed.sql | planned |
| Storage buckets (part photos, report photos) | `TODO` | planned |

**Flutter side of the link**
| Item | Link or path | Status |
|---|---|---|
| API base URL config | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/lib/config/app_config.dart | planned |
| HTTP client for the PHP API | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/lib/services/api_client.dart | planned |
| In-memory fake data to replace | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/lib/data/repo.dart | exists (fake data) |
| Mock login to replace | https://github.com/a8836813-lgtm/autopieces/blob/feature/roles-and-polish/lib/services/auth_service.dart | exists (mock) |

Never write the Supabase service key, database password or any secret in this file or in GitHub. Public links and the public API URL are fine.

## 10. Costs
- Prototype about 0 USD (Supabase free tier, local PHP, free tools). Optional domain 10-15 USD per year.
- Real costs only with real users (server, SMS, catalog license, payments through CIB/Edahabia and SATIM).

## 11. Side idea: AI-assisted firewall
Alternative PFE topic: classic ML in the path, an LLM beside it to explain alerts and propose rules, with human approval. About 2-3 months for one person, roughly 0-50 USD. Not chosen.

## 12. Next steps
0. Fetch and pull branch `feature/roles-and-polish`, stop the app completely and run it again, test all three roles with the demo accounts, paste any errors, then merge into `main`. Aymen has not reported the result of this test yet.
0b. Finish the mechanic page redesign (section 7.6, steps 1 to 6).
1. Fix compile errors (always import `package:material_ui/material_ui.dart`), add brand logos to `assets/brands/`.
2. Wire the results screen to `SearchQuery`; add part serial and fitment to the data.
3. Decide the PHP and Supabase architecture (9.1), create the Supabase project, write the SQL schema from section 8.
4. Build the PHP API skeleton returning fake data first (9.3 and 9.4), so teammates can work in parallel.
5. Done: mechanic dashboard, shop role routing, reviews, favorites, map prototype (see 7.5). Still missing: Arabic/French/English and RTL, real GPS map, real login backend.
6. Update `DATA_MODEL.md` to the local-shop version with a Mermaid ER diagram.
7. Meet Dr Hilali with the mockups and this file; confirm team size and expectations.
8. Collect real sample data from 2-3 shops in Jijel.
9. Thesis plan: problem analysis, requirements, UML, architecture, security chapter (roles, leakage, payment tokenization, PHP and Supabase hardening), business model, roadmap.

## 13. Open questions
- PHP and Supabase architecture: Option A or B? Supabase Auth or own auth tables?
- Final team members and roles; who owns the thesis.
- Exact name of the wholesaler shown as "Hamid Grossiste Auto" in the mockups.
- Web frontend technology (the app is Flutter).
- Interface language (English, French or Arabic).
- Required thesis structure and diagram notation.
- Is the demo on the same day as the defense?

## 14. Session log
> Every entry must end with `Backend links:` followed by the PHP and Supabase links touched (or `none yet`).
- 2026-11-18: GitHub repo connected; vehicle and serial search wired into Home and Results; polish pass; mechanic dashboard, Saved tab (reservations and favorites), reviews, nearby map prototype, shop dashboard upgrade (branch `feature/roles-and-polish`). Not compiled yet.
- 2026-11-17: login and sign-up by role (client, mechanic, shop owner); vehicle search with car and truck brands, models and universal serial number field; backend direction set to PHP + Supabase (placeholders added, architecture not yet chosen).
- 2026-11-18 (latest): added standing rule and the table 9.7 for PHP and Supabase links. Code placeholders (`backend/`, `supabase/`, `lib/config`, `lib/services/api_client.dart`) are still only planned. Backend links: none yet (see 9.7, all planned).
- 2026-11-18 (later): found that `main.dart` still started on `VehicleSearchScreen` (a temporary test line committed by mistake), restored `RoleSelectScreen` as the start screen. Mechanic page futuristic redesign started: theme and widgets written (7.6), the rest still to do.

## 15. Working with Claude and GitHub (how to continue in a new chat)
**Does a new chat erase the repo?** No. The code is on GitHub, so it is never lost. What a new chat does not keep is Claude's memory of the conversation, and Claude has to attach the repo again at the start of each session. A short summary of the project and the repo name is also kept in Claude's memory, but this file is the reliable source.

**Start every new chat with:**
> Read PROJECT_CONTEXT.md from my GitHub repo a8836813-lgtm/autopieces (branch feature/roles-and-polish). Today we work on X.

If Claude says it cannot access the repo: in claude.ai go to Settings, Connectors, GitHub, reconnect, allow the `autopieces` repository, then ask again. As a fallback, attach `PROJECT_CONTEXT.md` and a zip of the `lib` folder.

**End every session with:** "Update PROJECT_CONTEXT.md: what we did, decisions, next task, and the PHP and Supabase links", then push it to the repo.

**Get Claude's changes (GitHub Desktop):** Fetch origin, then Current branch, choose `feature/roles-and-polish` (first time), or Pull origin (later). Stop the app completely and run it again, not hot reload. Run `flutter pub get` when `pubspec.yaml` changed.

**Rules and lessons**
- Always import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- Claude cannot compile Flutter. Only Aymen can run the app. Paste errors back and Claude fixes them on the same branch.
- Keep the repo folder outside OneDrive. Do not edit the same file as Claude without committing first.
- Never commit `.env`, Supabase service key or database password.
- "N unpushed commits" warnings from an automatic check were false alarms: compare the commit ids on GitHub instead.
- Brand logos are not included: add PNGs named by brand id to `assets/brands/`.
