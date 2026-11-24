<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Client price alerts ("tell me when this part costs X DZD or less").
// GET  price_alerts.php                     each alert with the cheapest price in stock now and "triggered"
// POST {action:"set", part_id, target_price}      creates or changes the alert
// POST {action:"delete", part_id}
$pdo = db();
$u = actor(['client']);

if (method() === 'GET') {
    $st = $pdo->prepare(
        'SELECT a.part_id, a.target_price, a.created_at, p.name AS part_name, p.oem,
                (SELECT MIN(s.price) FROM stock s WHERE s.part_id = a.part_id AND s.quantity > 0) AS current_price
         FROM price_alerts a JOIN parts p ON p.id = a.part_id
         WHERE a.user_id = ? ORDER BY a.id DESC');
    $st->execute([$u['id']]);
    $rows = $st->fetchAll();
    foreach ($rows as &$r) {
        $r['target_price'] = (int) $r['target_price'];
        $r['current_price'] = $r['current_price'] === null ? null : (int) $r['current_price'];
        $r['triggered'] = $r['current_price'] !== null && $r['current_price'] <= $r['target_price'];
    }
    json_out(['ok' => true, 'alerts' => $rows, 'triggered_count' => count(array_filter($rows, fn($r) => $r['triggered']))]);
}

$action = input_str('action', 10);
$partId = input_int('part_id');
if ($action === 'set') {
    $price = input_int('target_price');
    if ($price <= 0) json_error('target_price must be above 0');
    $chk = $pdo->prepare('SELECT id FROM parts WHERE id = ?');
    $chk->execute([$partId]);
    if (!$chk->fetch()) json_error('Part not found', 404);
    $st = $pdo->prepare('SELECT id FROM price_alerts WHERE user_id = ? AND part_id = ?');
    $st->execute([$u['id'], $partId]);
    if ($row = $st->fetch()) {
        $pdo->prepare('UPDATE price_alerts SET target_price = ? WHERE id = ?')->execute([$price, $row['id']]);
    } else {
        $pdo->prepare('INSERT INTO price_alerts (user_id, part_id, target_price, created_at) VALUES (?,?,?,?)')
            ->execute([$u['id'], $partId, $price, now_sql()]);
    }
    json_out(['ok' => true]);
}
if ($action === 'delete') {
    $pdo->prepare('DELETE FROM price_alerts WHERE user_id = ? AND part_id = ?')->execute([$u['id'], $partId]);
    json_out(['ok' => true]);
}
json_error('Unknown action');
