<?php
/** Shared helpers for the chat endpoints. */
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';

function chat_row(array $r): array {
    return [
        'id'         => (int) $r['id'],
        'sender'     => $r['sender'],
        'body'       => (string) ($r['body'] ?? ''),
        'photo'      => $r['photo_path'] ? 'uploads/chat/' . $r['photo_path'] : null,
        'created_at' => $r['created_at'],
        'read'       => $r['read_at'] !== null,
    ];
}

/** Reads and validates the three fields that identify one conversation. */
function conv_from(array $src): array {
    $client = strtolower(trim((string) ($src['client_ref'] ?? '')));
    $kind   = (string) ($src['peer_kind'] ?? '');
    $peer   = trim((string) ($src['peer_id'] ?? ''));
    if ($client === '' || $peer === '' || !in_array($kind, ['mechanic', 'shop'], true)) {
        json_error('client_ref, peer_kind (mechanic|shop) and peer_id are required');
    }
    return [$client, $kind, $peer];
}
