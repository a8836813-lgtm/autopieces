<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET parts.php                  catalogue (with cheapest price and number of shops in stock)
// GET parts.php?id=5             one part
// GET parts.php?category=Brakes
// POST parts.php                 (shop owner) add a part to the catalogue, optionally with price + quantity
//                                for the owner's own shop: {name, oem, category, fits, alt_serials, price, quantity, condition}
$cheapest = '(SELECT MIN(st.price) FROM stock st WHERE st.part_id = p.id AND st.quantity > 0)';
$shops    = '(SELECT COUNT(*) FROM stock st WHERE st.part_id = p.id AND st.quantity > 0)';
$sel = "p.id, p.name, p.oem, p.category, p.fits, p.alt_serials, p.fitments_json,
        $cheapest AS cheapest_price, $shops AS shops_count";

if (method() === 'POST') {
    $u = actor(['shop']);
    $shop = my_shop($u);
    $name = input_str('name', 160);
    $oem = input_str('oem', 60);
    if ($name === '') json_error('Part name required');

    $pdo = db();
    $part = null;
    if ($oem !== '') {   // the serial number identifies the part: reuse it when it exists
        $st = $pdo->prepare('SELECT id FROM parts WHERE oem = ?');
        $st->execute([$oem]);
        $part = $st->fetch() ?: null;
    }
    if (!$part) {
        $fit = input('fitments');
        $pdo->prepare('INSERT INTO parts (name, oem, category, fits, alt_serials, fitments_json) VALUES (?,?,?,?,?,?)')
            ->execute([$name, $oem, input_str('category', 60), input_str('fits', 200), input_str('alt_serials', 300),
                       is_array($fit) ? json_encode($fit, JSON_UNESCAPED_UNICODE) : null]);
        $partId = (int) $pdo->lastInsertId();
    } else {
        $partId = (int) $part['id'];
    }
    if (input('price') !== null) {
        $price = input_int('price');
        if ($price <= 0) json_error('Price must be above 0');
        $qty = max(0, input_int('quantity', 1));
        $cond = input_str('condition', 30) ?: 'New';
        $st = $pdo->prepare('SELECT id FROM stock WHERE shop_id = ? AND part_id = ?');
        $st->execute([$shop['id'], $partId]);
        if ($row = $st->fetch()) {
            $pdo->prepare('UPDATE stock SET price=?, quantity=?, part_condition=? WHERE id=?')
                ->execute([$price, $qty, $cond, $row['id']]);
        } else {
            $pdo->prepare('INSERT INTO stock (shop_id, part_id, price, quantity, part_condition) VALUES (?,?,?,?,?)')
                ->execute([$shop['id'], $partId, $price, $qty, $cond]);
        }
    }
    $st = $pdo->prepare("SELECT $sel FROM parts p WHERE p.id = ?");
    $st->execute([$partId]);
    json_out(['ok' => true, 'part' => $st->fetch()], 201);
}

if (isset($_GET['id'])) {
    $st = db()->prepare("SELECT $sel FROM parts p WHERE p.id = ?");
    $st->execute([(int) $_GET['id']]);
    $row = $st->fetch();
    if (!$row) json_error('Part not found', 404);
    json_out(['ok' => true, 'part' => $row]);
}
$cat = trim($_GET['category'] ?? '');
if ($cat !== '') {
    $st = db()->prepare("SELECT $sel FROM parts p WHERE p.category = ? ORDER BY p.name");
    $st->execute([$cat]);
} else {
    $st = db()->query("SELECT $sel FROM parts p ORDER BY p.name LIMIT 500");
}
json_out(['ok' => true, 'parts' => $st->fetchAll()]);
