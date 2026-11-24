<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET shops.php                      all shops
// GET shops.php?lat=..&lng=..        sorted by distance (haversine, km)
// GET shops.php?id=3                 one shop
$lat = isset($_GET['lat']) ? (float) $_GET['lat'] : null;
$lng = isset($_GET['lng']) ? (float) $_GET['lng'] : null;

$rating = "(SELECT ROUND(AVG(stars),1) FROM reviews r WHERE r.target_kind='shop' AND r.target_id=s.id)";
$count  = "(SELECT COUNT(*) FROM reviews r WHERE r.target_kind='shop' AND r.target_id=s.id)";
$parts  = "(SELECT COUNT(*) FROM stock st WHERE st.shop_id=s.id AND st.quantity>0)";
$sel = "s.id, s.name, s.type, s.address, s.phone, s.hours, s.about, s.open_now, s.delivers, s.lat, s.lng,
        COALESCE($rating, s.rating) AS rating, $count AS reviews_count, $parts AS parts_count";

if (isset($_GET['id'])) {
    $st = db()->prepare("SELECT $sel FROM shops s WHERE s.id = ?");
    $st->execute([(int) $_GET['id']]);
    $row = $st->fetch();
    if (!$row) json_error('Shop not found', 404);
    json_out(['ok' => true, 'shop' => $row]);
}

if ($lat !== null && $lng !== null) {
    $st = db()->prepare(
        "SELECT $sel, (6371 * ACOS(LEAST(1, COS(RADIANS(?)) * COS(RADIANS(s.lat)) *
            COS(RADIANS(s.lng) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(s.lat))))) AS distance_km
         FROM shops s WHERE s.lat IS NOT NULL ORDER BY distance_km");
    $st->execute([$lat, $lng, $lat]);
} else {
    $st = db()->query("SELECT $sel FROM shops s ORDER BY s.name");
}
json_out(['ok' => true, 'shops' => $st->fetchAll()]);
