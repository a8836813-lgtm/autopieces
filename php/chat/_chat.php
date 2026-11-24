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

/**
 * With AUTH_REQUIRED the signed-in account must be a side of this conversation:
 * the client with this e-mail, or the shop / mechanic whose profile id is $peer.
 * In development mode (AUTH_REQUIRED = false) the app is trusted.
 */
function chat_guard(string $client, string $kind, string $peer, string $side): void {
    if (!AUTH_REQUIRED) return;
    $u = actor();
    if ($side === 'client') {
        if ($u['role'] !== 'client' || strtolower($u['email']) !== $client) json_error('Not your conversation', 403);
        return;
    }
    if ($u['role'] !== $kind) json_error('Not your conversation', 403);
    $row = $kind === 'shop' ? my_shop($u) : my_mechanic($u);
    if ((string) $row['id'] !== $peer) json_error('Not your conversation', 403);
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
