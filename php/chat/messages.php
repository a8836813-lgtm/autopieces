<?php
/**
 * GET messages of ONE conversation (used for polling).
 * ?client_ref=&peer_kind=&peer_id=&reader=client|peer&after_id=0
 * Returns messages with id > after_id and marks the other side's messages as read.
 */
require_once __DIR__ . '/_chat.php';

[$client, $kind, $peer] = conv_from($_GET);
$reader = $_GET['reader'] ?? '';
if (!in_array($reader, ['client', 'peer'], true)) json_error('reader must be client or peer');
$after = max(0, (int) ($_GET['after_id'] ?? 0));

$other = $reader === 'client' ? 'peer' : 'client';
db()->prepare('UPDATE chat_messages SET read_at = NOW()
               WHERE client_ref = ? AND peer_kind = ? AND peer_id = ?
                 AND sender = ? AND read_at IS NULL')
    ->execute([$client, $kind, $peer, $other]);

$st = db()->prepare('SELECT * FROM chat_messages
                     WHERE client_ref = ? AND peer_kind = ? AND peer_id = ? AND id > ?
                     ORDER BY id LIMIT 200');
$st->execute([$client, $kind, $peer, $after]);
json_out(['ok' => true, 'messages' => array_map('chat_row', $st->fetchAll())]);
