<?php
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';

$in = json_body();
$role  = $in['role']  ?? '';
$name  = trim($in['name']  ?? '');
$email = strtolower(trim($in['email'] ?? ''));
$phone = trim($in['phone'] ?? '');
$pass  = $in['password'] ?? '';

if (!in_array($role, ['client', 'mechanic', 'shop'], true)) json_error('Invalid role');
if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('Name and valid email required');
if (strlen($pass) < 8) json_error('Password must be at least 8 characters');

$st = db()->prepare('SELECT id FROM users WHERE email = ? AND role = ?');
$st->execute([$email, $role]);
if ($st->fetch()) json_error('An account with this email already exists', 409);

$st = db()->prepare(
    'INSERT INTO users (role, name, email, phone, password_hash, profile_json) VALUES (?,?,?,?,?,?)'
);
$st->execute([$role, $name, $email, $phone, password_hash($pass, PASSWORD_DEFAULT),
              json_encode($in['profile'] ?? new stdClass(), JSON_UNESCAPED_UNICODE)]);

json_out(['ok' => true, 'id' => (int) db()->lastInsertId()], 201);
