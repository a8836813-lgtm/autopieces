<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET ?q=brake   (matches part name or OEM/serial number)
$q = trim($_GET['q'] ?? '');
if ($q === '') json_error('Missing q');

$like = '%' . $q . '%';
$st = db()->prepare(
    'SELECT p.id AS part_id, p.name, p.oem, p.fits,
            s.id AS shop_id, s.name AS shop_name, s.phone, s.lat, s.lng,
            st.price, st.quantity, st.part_condition
     FROM parts p
     JOIN stock st ON st.part_id = p.id
     JOIN shops s  ON s.id = st.shop_id
     WHERE (p.name LIKE ? OR p.oem LIKE ?) AND st.quantity > 0
     ORDER BY st.price ASC LIMIT 50');
$st->execute([$like, $like]);
json_out(['ok' => true, 'results' => $st->fetchAll()]);
