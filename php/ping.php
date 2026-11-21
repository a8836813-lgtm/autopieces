<?php
// Open http://localhost/autopieces/api/ping.php to test XAMPP + MySQL.
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

try {
    db()->query('SELECT 1');
    json_out(['ok' => true, 'db' => 'connected', 'time' => date('c')]);
} catch (Throwable $e) {
    json_error('Database not reachable. Is MySQL started in XAMPP and schema.sql imported?', 500);
}
