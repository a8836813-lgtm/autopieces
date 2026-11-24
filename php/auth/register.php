<?php
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';
require_post();

$role  = input_str('role', 20);
$name  = input_str('name', 120);
$email = strtolower(input_str('email', 160));
$phone = input_str('phone', 30);
$pass  = (string) input('password', '');
$profile = input('profile', []);
if (!is_array($profile)) $profile = [];

if (!in_array($role, ['client', 'mechanic', 'shop'], true)) json_error('Invalid role');
if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('Name and valid email required');
if (strlen($pass) < 8) json_error('Password must be at least 8 characters');

$pdo = db();
$st = $pdo->prepare('SELECT id FROM users WHERE email = ? AND role = ?');
$st->execute([$email, $role]);
if ($st->fetch()) json_error('An account with this email already exists', 409);

$pdo->beginTransaction();
try {
    $pdo->prepare('INSERT INTO users (role, name, email, phone, password_hash, profile_json) VALUES (?,?,?,?,?,?)')
        ->execute([$role, $name, $email, $phone, password_hash($pass, PASSWORD_DEFAULT),
                   json_encode($profile ?: new stdClass(), JSON_UNESCAPED_UNICODE)]);
    $id = (int) $pdo->lastInsertId();

    // A shop or mechanic account gets its public profile row right away.
    if ($role === 'shop') {
        $pdo->prepare('INSERT INTO shops (owner_id, name, type, address, phone) VALUES (?,?,?,?,?)')
            ->execute([$id, (string) ($profile['shopName'] ?? $name), (string) ($profile['shopType'] ?? ''),
                       (string) ($profile['address'] ?? ''), $phone]);
    } elseif ($role === 'mechanic') {
        $pdo->prepare('INSERT INTO mechanics (owner_id, name, specialties, years_experience, address, phone) VALUES (?,?,?,?,?,?)')
            ->execute([$id, (string) ($profile['garage'] ?? $name), (string) ($profile['specialty'] ?? ''),
                       (int) ($profile['experience'] ?? 0), (string) ($profile['wilaya'] ?? ''), $phone]);
    }
    $pdo->commit();
} catch (Throwable $e) {
    $pdo->rollBack();
    json_error('Could not create the account', 500);
}

json_out(['ok' => true, 'id' => $id, 'token' => make_token($id, $role)], 201);
