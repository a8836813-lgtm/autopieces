<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET  mechanics.php                 list. Optional: q, verified=1, available=1, sort=rating|nearest|reports, lat, lng
// GET  mechanics.php?id=2            one mechanic with services
// POST mechanics.php                 (mechanic) update own profile, e.g.
//        {about, phone, hours, address, specialties, years_experience, response_time, languages,
//         mobile_service, available, services:[{name, price_from}]}   (services replace the old list)
$pdo = db();

$rating  = "(SELECT ROUND(AVG(stars),1) FROM reviews r WHERE r.target_kind='mechanic' AND r.target_id=m.id)";
$reviews = "(SELECT COUNT(*) FROM reviews r WHERE r.target_kind='mechanic' AND r.target_id=m.id)";
$reports = "(SELECT COUNT(*) FROM mechanic_reports mr WHERE mr.mechanic_id=m.id)";
$SEL = "m.id, m.name, m.specialties, m.years_experience, m.address, m.phone, m.hours, m.about, m.response_time,
        m.languages, m.mobile_service, m.premium, m.verified, m.available, m.lat, m.lng,
        COALESCE($rating, m.rating) AS rating, $reviews AS reviews_count, $reports AS reports_count";

function with_services(PDO $pdo, array $rows): array {
    foreach ($rows as &$m) {
        $st = $pdo->prepare('SELECT name, price_from FROM mechanic_services WHERE mechanic_id = ? ORDER BY id');
        $st->execute([$m['id']]);
        $m['services'] = $st->fetchAll();
    }
    return $rows;
}

if (method() === 'POST') {
    $u = actor(['mechanic']);
    $m = my_mechanic($u);
    $set = []; $args = [];
    foreach (['name' => 140, 'specialties' => 300, 'address' => 200, 'phone' => 30, 'hours' => 80,
              'about' => 600, 'response_time' => 60, 'languages' => 120] as $col => $max) {
        if (input($col) !== null) {
            $v = input_str($col, $max);
            if ($col === 'name' && $v === '') json_error('Name cannot be empty');
            $set[] = "$col = ?"; $args[] = $v;
        }
    }
    if (input('years_experience') !== null) { $set[] = 'years_experience = ?'; $args[] = max(0, input_int('years_experience')); }
    foreach (['mobile_service', 'available'] as $col) {
        if (input($col) !== null) { $set[] = "$col = ?"; $args[] = input($col) ? 1 : 0; }
    }
    foreach (['lat', 'lng'] as $col) {
        if (input($col) !== null) { $set[] = "$col = ?"; $args[] = (float) input($col); }
    }
    $pdo->beginTransaction();
    if ($set) {
        $args[] = $m['id'];
        $pdo->prepare('UPDATE mechanics SET ' . implode(', ', $set) . ' WHERE id = ?')->execute($args);
    }
    $services = input('services');
    if (is_array($services)) {
        $pdo->prepare('DELETE FROM mechanic_services WHERE mechanic_id = ?')->execute([$m['id']]);
        $ins = $pdo->prepare('INSERT INTO mechanic_services (mechanic_id, name, price_from) VALUES (?,?,?)');
        foreach ($services as $s) {
            $n = trim((string) ($s['name'] ?? ''));
            if ($n !== '') $ins->execute([$m['id'], mb_substr($n, 0, 120), max(0, (int) ($s['price_from'] ?? 0))]);
        }
    }
    $pdo->commit();
    $_GET['id'] = $m['id'];   // answer with the updated profile
}

if (isset($_GET['id'])) {
    $st = $pdo->prepare("SELECT $SEL FROM mechanics m WHERE m.id = ?");
    $st->execute([(int) $_GET['id']]);
    $row = $st->fetch() ?: json_error('Mechanic not found', 404);
    json_out(['ok' => true, 'mechanic' => with_services($pdo, [$row])[0]]);
}

$where = ['1=1']; $args = [];
$q = trim($_GET['q'] ?? '');
if ($q !== '') {
    $where[] = '(m.name LIKE ? OR m.specialties LIKE ? OR m.address LIKE ?)';
    array_push($args, "%$q%", "%$q%", "%$q%");
}
if (!empty($_GET['verified'])) $where[] = 'm.verified = 1';
if (!empty($_GET['available'])) $where[] = 'm.available = 1';

$lat = isset($_GET['lat']) ? (float) $_GET['lat'] : null;
$lng = isset($_GET['lng']) ? (float) $_GET['lng'] : null;
$dist = '';
if ($lat !== null && $lng !== null) {
    $dist = ', (6371 * ACOS(LEAST(1, COS(RADIANS(' . $lat . ')) * COS(RADIANS(m.lat)) * COS(RADIANS(m.lng) - RADIANS(' . $lng . ')) + SIN(RADIANS(' . $lat . ')) * SIN(RADIANS(m.lat))))) AS distance_km';
}
$order = match ($_GET['sort'] ?? 'rating') {
    'nearest' => $dist !== '' ? 'distance_km ASC' : 'm.name ASC',
    'reports' => 'reports_count DESC, m.name ASC',
    default   => 'rating DESC, m.name ASC',
};
$st = $pdo->prepare("SELECT $SEL $dist FROM mechanics m WHERE " . implode(' AND ', $where) . " ORDER BY $order LIMIT 100");
$st->execute($args);
json_out(['ok' => true, 'mechanics' => with_services($pdo, $st->fetchAll())]);
