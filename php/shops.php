<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Optional: ?lat=..&lng=.. sorts by distance (haversine, km)
$lat = isset($_GET['lat']) ? (float) $_GET['lat'] : null;
$lng = isset($_GET['lng']) ? (float) $_GET['lng'] : null;

if ($lat !== null && $lng !== null) {
    $st = db()->prepare(
        'SELECT s.*, (6371 * ACOS(LEAST(1, COS(RADIANS(?)) * COS(RADIANS(lat)) *
            COS(RADIANS(lng) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(lat))))) AS distance_km
         FROM shops s ORDER BY distance_km');
    $st->execute([$lat, $lng, $lat]);
} else {
    $st = db()->query('SELECT * FROM shops ORDER BY name');
}
json_out(['ok' => true, 'shops' => $st->fetchAll()]);
