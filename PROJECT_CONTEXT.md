# AutoPièces: PROJECT_CONTEXT

Graduation project (prototype): a local car-parts marketplace. Clients search
parts in nearby shops, scan a part with the camera, read mechanic reports.
Three roles: client, mechanic, shop owner (grossiste). Flutter app.

## 1. Stack
- Flutter (Dart 3.3+), `material_ui` package, `camera`
- Data today: in-memory demo data (`lib/data/repo.dart`)
- Backend (planned): PHP + MySQL on XAMPP, and/or Supabase

## 2. Design system (futuristic dark theme)
- `lib/theme.dart`: `AppColors` (neon cyan `teal`, violet `orange`, magenta), `AppGradients`, `buildTheme()`
- `lib/widgets/futuristic.dart`: `AuroraBackground`, `GlassCard`, `NeonButton`,
  `GradientText`, `NeonIconBadge`, `StatusChip`, `SectionHeader`
- Color names were kept from v1, so old code picks up the new palette automatically.

## 9.7 Backend links: PHP (XAMPP) and Supabase  ← keep this updated every session

### PHP files (copy `/php` to `C:\xampp\htdocs\autopieces\api`)
| Endpoint | File | Status |
|---|---|---|
| Health check | `php/ping.php` | written |
| Register | `php/auth/register.php` | written |
| Login | `php/auth/login.php` | written (token TODO) |
| Shops (+distance) | `php/shops.php` | written |
| Parts search | `php/parts_search.php` | written |
| Config (DB, Supabase, secrets) | `php/config.php` | placeholders |
| PDO connection | `php/database/db.php` | written |
| MySQL schema | `php/database/schema.sql` | written, import in phpMyAdmin |
| Planned | stock, reservations, reports, favorites, reviews | not written |

Flutter side: `lib/config/app_config.dart` (`AppConfig.phpBaseUrl`, `ApiEndpoints`).
URLs: emulator `http://10.0.2.2/autopieces/api`, phone `http://<PC-LAN-IP>/autopieces/api`.

### Supabase items (PLACEHOLDERS, not connected yet)
- `lib/config/app_config.dart`: `supabaseUrl`, `supabaseAnonKey` (use `--dart-define`)
- `php/config.php`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- To do: create project, mirror `php/database/schema.sql` tables, add `supabase_flutter`,
  enable Row Level Security, use Storage for part/report photos.
- Switch backend in `AppConfig.backendMode` (`mock` | `php` | `supabase`).
- Never ship the `service_role` key in the app.

## Session log
- **2026-11-21**: Futuristic dark redesign (theme, glass cards, neon buttons, aurora
  background, restyled home/auth/shops/results/profile). Added backend placeholders:
  `lib/config/app_config.dart`, `php/*`, Backend status card in Profile.
  Links: PHP files and Supabase items listed in 9.7 above.
  Not verified by compile: no Flutter SDK in the build sandbox, run `flutter analyze` locally.
