<?php
/**
 * GET the list of conversations with last message and unread count.
 *   Client: ?as=client&client_ref=<email>
 *   Mechanic/shop: ?as=peer&peer_kind=mechanic|shop&peer_id=m1
 * "unread" = messages written by the OTHER side that are not read yet.
 */
require_once __DIR__ . '/_chat.php';

$as = $_GET['as'] ?? '';
if ($as === 'client') {
    $client = strtolower(trim((string) ($_GET['client_ref'] ?? '')));
    if ($client === '') json_error('client_ref required');
    $where = 'client_ref = ?';
    $args = [$client];
    $other = 'peer';
} elseif ($as === 'peer') {
    $kind = (string) ($_GET['peer_kind'] ?? '');
    $peer = trim((string) ($_GET['peer_id'] ?? ''));
    if ($peer === '' || !in_array($kind, ['mechanic', 'shop'], true)) {
        json_error('peer_kind and peer_id required');
    }
    $where = 'peer_kind = ? AND peer_id = ?';
    $args = [$kind, $peer];
    $other = 'client';
} else {
    json_error('as must be client or peer');
}

// Latest message id per conversation, then fetch those rows.
$st = db()->prepare(
    "SELECT m.* FROM chat_messages m
       JOIN (SELECT MAX(id) AS last_id FROM chat_messages WHERE $where
             GROUP BY client_ref, peer_kind, peer_id) t ON t.last_id = m.id
      ORDER BY m.id DESC LIMIT 100");
$st->execute($args);
$rows = $st->fetchAll();

$un = db()->prepare(
    "SELECT client_ref, peer_kind, peer_id, COUNT(*) AS n FROM chat_messages
      WHERE $where AND sender = ? AND read_at IS NULL
      GROUP BY client_ref, peer_kind, peer_id");
$un->execute(array_merge($args, [$other]));
$unread = [];
foreach ($un->fetchAll() as $u) {
    $unread[$u['client_ref'] . '|' . $u['peer_kind'] . '|' . $u['peer_id']] = (int) $u['n'];
}

$threads = [];
foreach ($rows as $r) {
    $key = $r['client_ref'] . '|' . $r['peer_kind'] . '|' . $r['peer_id'];
    $threads[] = [
        'client_ref'  => $r['client_ref'],
        'client_name' => $r['client_name'],
        'peer_kind'   => $r['peer_kind'],
        'peer_id'     => $r['peer_id'],
        'peer_name'   => $r['peer_name'],
        'last'        => chat_row($r),
        'unread'      => $unread[$key] ?? 0,
    ];
}
json_out(['ok' => true, 'threads' => $threads]);
