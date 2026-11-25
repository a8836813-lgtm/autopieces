<?php
require_once __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') { http_response_code(204); exit; }

function json_out($data, int $status = 200): void {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function json_error(string $message, int $status = 400): void {
    json_out(['ok' => false, 'error' => $message], $status);
}

/** JSON body of the request (read once). */
function json_body(): array {
    static $data = null;
    if ($data === null) {
        $raw = file_get_contents('php://input');
        $d = json_decode($raw ?: '[]', true);
        $data = is_array($d) ? $d : [];
    }
    return $data;
}

/** One input value: JSON body, then form fields, then the query string. */
function input(string $key, $default = null) {
    $b = json_body();
    if (array_key_exists($key, $b)) return $b[$key];
    if (array_key_exists($key, $_POST)) return $_POST[$key];
    if (array_key_exists($key, $_GET)) return $_GET[$key];
    return $default;
}

function input_int(string $key, int $default = 0): int {
    return (int) input($key, $default);
}

function input_str(string $key, int $max = 255): string {
    return mb_substr(trim((string) input($key, '')), 0, $max);
}

function now_sql(): string { return date('Y-m-d H:i:s'); }

/** "2026-11-24T10:30" or "2026-11-24 10:30" -> "2026-11-24 10:30:00", or null. */
function parse_datetime($v): ?string {
    $t = strtotime(str_replace('T', ' ', (string) $v));
    return $t === false ? null : date('Y-m-d H:i:s', $t);
}

// ───────────────────────────── tokens (HS256, like a JWT) ─────────────────────────────

function b64u(string $s): string { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }
function b64u_dec(string $s): string { return (string) base64_decode(strtr($s, '-_', '+/')); }

function make_token(int $userId, string $role): string {
    $head = b64u(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $body = b64u(json_encode([
        'sub' => $userId, 'role' => $role,
        'exp' => time() + TOKEN_TTL_DAYS * 86400,
    ]));
    return "$head.$body." . b64u(hash_hmac('sha256', "$head.$body", JWT_SECRET, true));
}

/** User id inside a valid token, or null. */
function token_user_id(string $token): ?int {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    $good = b64u(hash_hmac('sha256', "$parts[0].$parts[1]", JWT_SECRET, true));
    if (!hash_equals($good, $parts[2])) return null;
    $p = json_decode(b64u_dec($parts[1]), true);
    if (!is_array($p) || ($p['exp'] ?? 0) < time()) return null;
    return (int) ($p['sub'] ?? 0) ?: null;
}

function bearer_token(): string {
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if ($h === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strcasecmp($k, 'Authorization') === 0) $h = $v;
        }
    }
    return stripos($h, 'Bearer ') === 0 ? trim(substr($h, 7)) : '';
}

/**
 * The signed-in account (users row) or exits with 401/403.
 * $roles limits which account types may call the endpoint.
 */
function actor(array $roles = []): array {
    require_once __DIR__ . '/database/db.php';
    if (AUTH_REQUIRED && str_starts_with(JWT_SECRET, 'CHANGE_ME')) {
        json_error('Server not ready: change JWT_SECRET in php/config.php', 500);
    }
    $id = null;
    $tok = bearer_token();
    if ($tok !== '') $id = token_user_id($tok);
    if ($id === null && !AUTH_REQUIRED) $id = input_int('user_id') ?: null;   // development only
    if ($id === null) json_error('Login required', 401);

    $st = db()->prepare('SELECT * FROM users WHERE id = ?');
    $st->execute([$id]);
    $u = $st->fetch();
    if (!$u) json_error('Login required', 401);
    if ($roles && !in_array($u['role'], $roles, true)) json_error('Not allowed for this account type', 403);
    return $u;
}

/** The actor if one is signed in, otherwise null (for public endpoints that personalise). */
function actor_optional(): ?array {
    $tok = bearer_token();
    if ($tok === '' && (AUTH_REQUIRED || !input('user_id'))) return null;
    require_once __DIR__ . '/database/db.php';
    $id = $tok !== '' ? token_user_id($tok) : (AUTH_REQUIRED ? null : input_int('user_id'));
    if (!$id) return null;
    $st = db()->prepare('SELECT * FROM users WHERE id = ?');
    $st->execute([$id]);
    return $st->fetch() ?: null;
}

/** Shop row owned by this shop account (exits 404 when there is none). */
function my_shop(array $user): array {
    $st = db()->prepare('SELECT * FROM shops WHERE owner_id = ?');
    $st->execute([$user['id']]);
    $s = $st->fetch();
    if (!$s) json_error('No shop is linked to this account', 404);
    return $s;
}

/** Mechanic row owned by this mechanic account (exits 404 when there is none). */
function my_mechanic(array $user): array {
    $st = db()->prepare('SELECT * FROM mechanics WHERE owner_id = ?');
    $st->execute([$user['id']]);
    $m = $st->fetch();
    if (!$m) json_error('No mechanic profile is linked to this account', 404);
    return $m;
}

function distance_km(float $lat1, float $lng1, float $lat2, float $lng2): float {
    $r = 6371.0;
    $dLat = deg2rad($lat2 - $lat1);
    $dLng = deg2rad($lng2 - $lng1);
    $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
    return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
}

const PAYMENT_OPTIONS = ['Cash', 'CIB card', 'Edahabia', 'Bank transfer'];

function clean_payments($v): string {
    $list = is_array($v) ? $v : explode(',', (string) $v);
    $out = [];
    foreach ($list as $p) {
        $p = trim((string) $p);
        if (in_array($p, PAYMENT_OPTIONS, true) && !in_array($p, $out, true)) $out[] = $p;
    }
    return implode(', ', $out ?: ['Cash']);
}

function method(): string { return $_SERVER['REQUEST_METHOD'] ?? 'GET'; }

function require_post(): void {
    if (method() !== 'POST') json_error('POST only', 405);
}

// ───────────────────────────── image uploads ─────────────────────────────

/**
 * Saves one uploaded image ($_FILES entry) in uploads/<folder>/ with a random name.
 * Returns the file name. Exits with an error when the file is not a JPG/PNG/WebP under 5 MB.
 */
function save_image(array $f, string $folder): string {
    if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) json_error('Photo upload failed');
    if ($f['size'] > 5 * 1024 * 1024) json_error('Photo too large (5 MB max)');
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
    $ext = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'][$mime] ?? null;
    if ($ext === null) json_error('Only JPG, PNG or WebP photos are allowed');
    $dir = __DIR__ . '/uploads/' . $folder;
    if (!is_dir($dir) && !mkdir($dir, 0775, true)) json_error('Cannot create upload folder', 500);
    $name = bin2hex(random_bytes(12)) . '.' . $ext;
    if (!move_uploaded_file($f['tmp_name'], $dir . '/' . $name)) json_error('Cannot save photo', 500);
    return $name;
}

/** Relative address of a stored photo, e.g. uploads/jobs/ab12.jpg (the app adds the base URL). */
function photo_url(string $folder, string $name): string { return "uploads/$folder/$name"; }

/** Normalises the files of a field sent as photos[] (or a single photo) into a list. */
function uploaded_files(string $field): array {
    if (empty($_FILES[$field])) return [];
    $f = $_FILES[$field];
    if (!is_array($f['name'])) {
        return $f['error'] === UPLOAD_ERR_NO_FILE ? [] : [$f];
    }
    $out = [];
    foreach (array_keys($f['name']) as $i) {
        if ($f['error'][$i] === UPLOAD_ERR_NO_FILE) continue;
        $out[] = ['name' => $f['name'][$i], 'type' => $f['type'][$i], 'tmp_name' => $f['tmp_name'][$i],
                  'error' => $f['error'][$i], 'size' => $f['size'][$i]];
    }
    return $out;
}

/** Public view of a users row, with the id of its shop or mechanic profile. */
function user_json(array $u): array {
    require_once __DIR__ . '/database/db.php';
    $out = [
        'id' => (int) $u['id'], 'role' => $u['role'], 'name' => $u['name'],
        'email' => $u['email'], 'phone' => $u['phone'],
        'profile' => json_decode($u['profile_json'] ?: '{}', true) ?: new stdClass(),
        'shop_id' => null, 'mechanic_id' => null,
    ];
    if ($u['role'] === 'shop') {
        $st = db()->prepare('SELECT id FROM shops WHERE owner_id = ?');
        $st->execute([$u['id']]);
        $out['shop_id'] = ($r = $st->fetch()) ? (int) $r['id'] : null;
    } elseif ($u['role'] === 'mechanic') {
        $st = db()->prepare('SELECT id FROM mechanics WHERE owner_id = ?');
        $st->execute([$u['id']]);
        $out['mechanic_id'] = ($r = $st->fetch()) ? (int) $r['id'] : null;
    }
    return $out;
}
