<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET ?q=brake            (matches part name, serial number or an alternative serial)
// optional: &category=Brakes  &sort=cheapest|nearest  &lat=..&lng=..
$q = trim($_GET['q'] ?? '');
$category = trim($_GET['category'] ?? '');
if ($q === '' && $category === '') json_error('Missing q or category');

$where = ['st.quantity > 0'];
$args = [];
if ($q !== '') {
    $like = '%' . $q . '%';
    $where[] = '(p.name LIKE ? OR p.oem LIKE ? OR p.alt_serials LIKE ?)';
    array_push($args, $like, $like, $like);
}
if ($category !== '') { $where[] = 'p.category = ?'; $args[] = $category; }

$lat = isset($_GET['lat']) ? (float) $_GET['lat'] : null;
$lng = isset($_GET['lng']) ? (float) $_GET['lng'] : null;
$dist = ($lat !== null && $lng !== null && ($_GET['sort'] ?? '') === 'nearest')
    ? ', (6371 * ACOS(LEAST(1, COS(RADIANS(' . $lat . ')) * COS(RADIANS(s.lat)) * COS(RADIANS(s.lng) - RADIANS(' . $lng . ')) + SIN(RADIANS(' . $lat . ')) * SIN(RADIANS(s.lat))))) AS distance_km'
    : '';
$order = $dist !== '' ? 'distance_km ASC' : 'st.price ASC';

$st = db()->prepare(
    "SELECT p.id AS part_id, p.name, p.oem, p.category, p.fits,
            s.id AS shop_id, s.name AS shop_name, s.phone, s.hours, s.open_now, s.lat, s.lng,
            st.id AS stock_id, st.price, st.quantity, st.part_condition $dist
     FROM parts p
     JOIN stock st ON st.part_id = p.id
     JOIN shops s  ON s.id = st.shop_id
     WHERE " . implode(' AND ', $where) . " ORDER BY $order LIMIT 50");
$st->execute($args);
json_out(['ok' => true, 'results' => $st->fetchAll()]);
