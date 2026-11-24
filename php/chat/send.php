<?php
/**
 * POST (multipart/form-data) one chat message, optional photo.
 * Fields: client_ref, client_name, peer_kind, peer_id, peer_name,
 *         sender (client|peer), body, photo (file, optional)
 */
require_once __DIR__ . '/_chat.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') json_error('POST only', 405);

[$client, $kind, $peer] = conv_from($_POST);
$sender = $_POST['sender'] ?? '';
if (!in_array($sender, ['client', 'peer'], true)) json_error('sender must be client or peer');

$body = trim((string) ($_POST['body'] ?? ''));
if (mb_strlen($body) > 2000) json_error('Message too long (2000 characters max)');

// ── optional photo ──
$photoName = null;
if (!empty($_FILES['photo']) && $_FILES['photo']['error'] !== UPLOAD_ERR_NO_FILE) {
    $f = $_FILES['photo'];
    if ($f['error'] !== UPLOAD_ERR_OK) json_error('Photo upload failed');
    if ($f['size'] > 5 * 1024 * 1024) json_error('Photo too large (5 MB max)');
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
    $ext = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'][$mime] ?? null;
    if ($ext === null) json_error('Only JPG, PNG or WebP photos are allowed');
    $dir = __DIR__ . '/../uploads/chat';
    if (!is_dir($dir) && !mkdir($dir, 0775, true)) json_error('Cannot create upload folder', 500);
    $photoName = bin2hex(random_bytes(12)) . '.' . $ext;   // never use the client file name
    if (!move_uploaded_file($f['tmp_name'], $dir . '/' . $photoName)) json_error('Cannot save photo', 500);
}

if ($body === '' && $photoName === null) json_error('Empty message');

$st = db()->prepare(
    'INSERT INTO chat_messages
       (client_ref, client_name, peer_kind, peer_id, peer_name, sender, body, photo_path)
     VALUES (?,?,?,?,?,?,?,?)');
$st->execute([
    $client, mb_substr(trim((string) ($_POST['client_name'] ?? '')), 0, 120),
    $kind, $peer, mb_substr(trim((string) ($_POST['peer_name'] ?? '')), 0, 140),
    $sender, $body, $photoName,
]);
$id = (int) db()->lastInsertId();
$row = db()->query('SELECT * FROM chat_messages WHERE id = ' . $id)->fetch();
json_out(['ok' => true, 'message' => chat_row($row)]);
