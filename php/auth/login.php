<?php
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';

$in = json_body();
$role  = $in['role'] ?? '';
$email = strtolower(trim($in['email'] ?? ''));
$pass  = $in['password'] ?? '';

$st = db()->prepare('SELECT * FROM users WHERE email = ? AND role = ?');
$st->execute([$email, $role]);
$u = $st->fetch();

if (!$u || !password_verify($pass, $u['password_hash'])) json_error('Wrong email or password', 401);

// TODO: replace with a signed token (JWT_SECRET) before real use.
json_out(['ok' => true, 'user' => [
    'id' => (int) $u['id'], 'role' => $u['role'], 'name' => $u['name'],
    'email' => $u['email'], 'phone' => $u['phone'],
    'profile' => json_decode($u['profile_json'] ?: '{}', true),
]]);
