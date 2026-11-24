<?php
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';
require_post();

$role  = input_str('role', 20);
$email = strtolower(input_str('email', 160));
$pass  = (string) input('password', '');

$st = db()->prepare('SELECT * FROM users WHERE email = ? AND role = ?');
$st->execute([$email, $role]);
$u = $st->fetch();

if (!$u || !password_verify($pass, $u['password_hash'])) json_error('Wrong email or password', 401);

json_out(['ok' => true, 'token' => make_token((int) $u['id'], $u['role']), 'user' => user_json($u)]);
