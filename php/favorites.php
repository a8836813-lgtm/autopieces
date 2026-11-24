<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Client favourites (the heart buttons).
// GET  favorites.php                          {shops:[ids], parts:[ids], mechanics:[ids]}
// POST {kind:"shop"|"part"|"mechanic", target_id}   toggles; answers {favorite: true|false}
$pdo = db();
$u = actor(['client']);

if (method() === 'GET') {
    $st = $pdo->prepare('SELECT kind, target_id FROM favorites WHERE user_id = ? ORDER BY created_at DESC');
    $st->execute([$u['id']]);
    $out = ['shops' => [], 'parts' => [], 'mechanics' => []];
    foreach ($st->fetchAll() as $r) $out[$r['kind'] . 's'][] = (int) $r['target_id'];
    json_out(['ok' => true] + $out);
}

$kind = input_str('kind', 10);
$tid = input_int('target_id');
$table = ['shop' => 'shops', 'part' => 'parts', 'mechanic' => 'mechanics'][$kind] ?? null;
if ($table === null || $tid <= 0) json_error('kind (shop|part|mechanic) and target_id required');
$chk = $pdo->prepare("SELECT id FROM $table WHERE id = ?");
$chk->execute([$tid]);
if (!$chk->fetch()) json_error('Not found', 404);

$has = $pdo->prepare('SELECT 1 FROM favorites WHERE user_id = ? AND kind = ? AND target_id = ?');
$has->execute([$u['id'], $kind, $tid]);
if ($has->fetch()) {
    $pdo->prepare('DELETE FROM favorites WHERE user_id = ? AND kind = ? AND target_id = ?')->execute([$u['id'], $kind, $tid]);
    json_out(['ok' => true, 'favorite' => false]);
}
$pdo->prepare('INSERT INTO favorites (user_id, kind, target_id, created_at) VALUES (?,?,?,?)')
    ->execute([$u['id'], $kind, $tid, now_sql()]);
json_out(['ok' => true, 'favorite' => true]);
