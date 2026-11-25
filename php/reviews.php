<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET  reviews.php?target_kind=shop|mechanic&target_id=1     reviews with photos, replies and the average
// GET  reviews.php?all=1                                     every review (the app loads them at start)
// POST (client, multipart/form-data so photos can be attached):
//        target_kind, target_id, stars (1-5), comment, photos[] (up to 3 images),
//        reservation_id   (required for a shop: a Completed reservation of yours, one review each)
//   A mechanic review needs a Done job with that mechanic (see MECHANIC_REVIEW_NEEDS_JOB in config.php).
// POST {action:"reply", review_id, reply}   the shop / mechanic answers a review of their own profile
$pdo = db();

function review_list(PDO $pdo, string $kind, int $id): array {
    $st = $pdo->prepare('SELECT id, author_name, stars, comment, reply, created_at FROM reviews
                         WHERE target_kind = ? AND target_id = ? ORDER BY id DESC LIMIT 200');
    $st->execute([$kind, $id]);
    $rows = $st->fetchAll();
    foreach ($rows as &$r) {
        $ph = $pdo->prepare('SELECT path FROM review_photos WHERE review_id = ? ORDER BY id');
        $ph->execute([$r['id']]);
        $r['photos'] = array_map(fn($p) => photo_url('reviews', $p['path']), $ph->fetchAll());
        $r['stars'] = (int) $r['stars'];
    }
    return $rows;
}

if (method() === 'GET' && input('all')) {
    $st = $pdo->query('SELECT id, target_kind, target_id, author_name, stars, comment, reply, created_at
                       FROM reviews ORDER BY id DESC LIMIT 1000');
    $rows = $st->fetchAll();
    foreach ($rows as &$r) {
        $ph = $pdo->prepare('SELECT path FROM review_photos WHERE review_id = ? ORDER BY id');
        $ph->execute([$r['id']]);
        $r['photos'] = array_map(fn($p) => photo_url('reviews', $p['path']), $ph->fetchAll());
        $r['stars'] = (int) $r['stars'];
    }
    json_out(['ok' => true, 'reviews' => $rows]);
}

if (method() === 'GET') {
    $kind = input_str('target_kind', 10);
    $tid = input_int('target_id');
    if (!in_array($kind, ['shop', 'mechanic'], true) || $tid <= 0) json_error('target_kind and target_id required');
    $list = review_list($pdo, $kind, $tid);
    $avg = $list ? round(array_sum(array_column($list, 'stars')) / count($list), 1) : null;
    json_out(['ok' => true, 'average' => $avg, 'count' => count($list), 'reviews' => $list]);
}

if (input_str('action', 10) === 'reply') {
    $u = actor(['shop', 'mechanic']);
    $st = $pdo->prepare('SELECT * FROM reviews WHERE id = ?');
    $st->execute([input_int('review_id')]);
    $rev = $st->fetch() ?: json_error('Review not found', 404);
    $mine = $u['role'] === 'shop' ? my_shop($u) : my_mechanic($u);
    if ($rev['target_kind'] !== $u['role'] || (int) $rev['target_id'] !== (int) $mine['id']) {
        json_error('You can only answer reviews of your own profile', 403);
    }
    $text = input_str('reply', 1000);
    $pdo->prepare('UPDATE reviews SET reply = ? WHERE id = ?')->execute([$text === '' ? null : $text, $rev['id']]);
    json_out(['ok' => true]);
}

require_post();
$u = actor(['client']);
$kind = input_str('target_kind', 10);
$tid = input_int('target_id');
$stars = input_int('stars');
if (!in_array($kind, ['shop', 'mechanic'], true) || $tid <= 0) json_error('target_kind and target_id required');
if ($stars < 1 || $stars > 5) json_error('stars must be between 1 and 5');
$files = uploaded_files('photos');
if (count($files) > 3) json_error('3 photos at most');

$reservationId = null;
if ($kind === 'shop') {
    $st = $pdo->prepare("SELECT r.id FROM reservations r JOIN stock s ON s.id = r.stock_id
                         WHERE r.id = ? AND r.client_id = ? AND s.shop_id = ? AND r.status = 'Completed' AND r.reviewed = 0");
    $st->execute([input_int('reservation_id'), $u['id'], $tid]);
    if (!$st->fetch()) json_error('You can review a shop after you picked up a part there (one review per order)', 403);
    $reservationId = input_int('reservation_id');
} else {
    $st = $pdo->prepare('SELECT id FROM mechanics WHERE id = ?');
    $st->execute([$tid]);
    if (!$st->fetch()) json_error('Mechanic not found', 404);
    if (MECHANIC_REVIEW_NEEDS_JOB) {
        $st = $pdo->prepare("SELECT COUNT(*) FROM job_requests WHERE client_id = ? AND mechanic_id = ? AND status = 'Done'");
        $st->execute([$u['id'], $tid]);
        $done = (int) $st->fetchColumn();
        $st = $pdo->prepare("SELECT COUNT(*) FROM reviews WHERE author_id = ? AND target_kind = 'mechanic' AND target_id = ?");
        $st->execute([$u['id'], $tid]);
        if ($done === 0 || (int) $st->fetchColumn() >= $done) {
            json_error('You can review a mechanic after a finished job (one review per job)', 403);
        }
    }
}

$pdo->beginTransaction();
$pdo->prepare('INSERT INTO reviews (target_kind, target_id, author_id, author_name, stars, comment, reservation_id, created_at)
               VALUES (?,?,?,?,?,?,?,?)')
    ->execute([$kind, $tid, $u['id'], $u['name'], $stars, input_str('comment', 1000), $reservationId, now_sql()]);
$rid = (int) $pdo->lastInsertId();
foreach ($files as $f) {
    $pdo->prepare('INSERT INTO review_photos (review_id, path) VALUES (?,?)')->execute([$rid, save_image($f, 'reviews')]);
}
if ($reservationId) $pdo->prepare('UPDATE reservations SET reviewed = 1 WHERE id = ?')->execute([$reservationId]);
$pdo->commit();
json_out(['ok' => true, 'id' => $rid], 201);
