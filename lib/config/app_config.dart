/// Backend connection settings for AutoPièces.
///
/// The app currently runs on local demo data (see lib/data/repo.dart).
/// When the database is ready, fill the two PLACEHOLDER blocks below (or pass
/// them with --dart-define so nothing secret lands in Git), then switch
/// [AppConfig.backendMode].
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=PHP_BASE_URL=http://10.0.2.2/autopieces/api
///
/// Never put the Supabase *service_role* key in the app. Only the anon key.
library;

enum BackendMode {
  /// Built-in demo data, no network. This is the current behaviour.
  mock,

  /// PHP API running on XAMPP (MySQL / MariaDB).
  php,

  /// Supabase (Postgres, Auth, Storage).
  supabase,
}

class AppConfig {
  AppConfig._();

  /// Change to [BackendMode.php] or [BackendMode.supabase] once connected.
  static const BackendMode backendMode = BackendMode.mock;

  // ───────────────────────── SUPABASE (PLACEHOLDER) ─────────────────────────
  // Dashboard → Project Settings → API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL', // e.g. https://abcdxyz.supabase.co
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ─────────────────────── PHP + XAMPP LINK (PLACEHOLDER) ───────────────────
  // Copy the /php folder of this repo to C:\xampp\htdocs\autopieces\api
  // Android emulator  → http://10.0.2.2/autopieces/api
  // Real phone (Wi-Fi) → http://<PC-LAN-IP>/autopieces/api   (e.g. 192.168.1.20)
  // Flutter web / Windows → http://localhost/autopieces/api
  static const String phpBaseUrl = String.fromEnvironment(
    'PHP_BASE_URL',
    defaultValue: 'http://10.0.2.2/autopieces/api',
  );

  static const Duration requestTimeout = Duration(seconds: 12);

  static bool get supabaseConfigured =>
      !supabaseUrl.startsWith('YOUR_') && !supabaseAnonKey.startsWith('YOUR_');

  static bool get phpConfigured => !phpBaseUrl.contains('YOUR_');

  /// Short text for the status card in the profile screen.
  static String get statusLabel => switch (backendMode) {
        BackendMode.mock => 'Local demo data',
        BackendMode.php => 'PHP / XAMPP',
        BackendMode.supabase => 'Supabase',
      };
}

/// Endpoint names of the PHP API (files in /php). Build a URL with
/// `ApiEndpoints.url(ApiEndpoints.login)`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String ping = 'ping.php';
  static const String login = 'auth/login.php';
  static const String register = 'auth/register.php';
  static const String shops = 'shops.php';
  static const String searchParts = 'parts_search.php';

  // Planned (not written yet): stock.php, reservations.php, reports.php,
  // favorites.php, reviews.php

  static String url(String endpoint) {
    final base = AppConfig.phpBaseUrl.endsWith('/')
        ? AppConfig.phpBaseUrl.substring(0, AppConfig.phpBaseUrl.length - 1)
        : AppConfig.phpBaseUrl;
    return '$base/$endpoint';
  }
}
