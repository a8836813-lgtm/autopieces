<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET  stock.php?shop_id=1        public: what a shop holds
// POST stock.php  (shop owner, own shop only), field "action":
//   upsert     {part_id, price, quantity, condition}
//   adjust     {part_id, delta}            quick +/- buttons
//   delete     {part_id}
//   bulk_price {percent, category?}        e.g. 5 = +5 %, -10 = -10 %
$pdo = db();

if (method() === 'GET') {
    $shopId = input_int('shop_id');
    if ($shopId <= 0) json_error('shop_id required');
    $st = $pdo->prepare(
        'SELECT st.id AS stock_id, st.price, st.quantity, st.part_condition,
                p.id AS part_id, p.name, p.oem, p.category, p.fits
         FROM stock st JOIN parts p ON p.id = st.part_id
         WHERE st.shop_id = ? ORDER BY p.name');
    $st->execute([$shopId]);
    json_out(['ok' => true, 'stock' => $st->fetchAll()]);
}

$u = actor(['shop']);
$shop = my_shop($u);
$action = input_str('action', 20);
$partId = input_int('part_id');

function stock_row(PDO $pdo, int $shopId, int $partId): ?array {
    $st = $pdo->prepare('SELECT * FROM stock WHERE shop_id = ? AND part_id = ?');
    $st->execute([$shopId, $partId]);
    return $st->fetch() ?: null;
}

switch ($action) {
    case 'upsert':
        $price = input_int('price');
        $qty = input_int('quantity');
        if ($partId <= 0) json_error('part_id required');
        if ($price <= 0) json_error('Price must be above 0');
        if ($qty < 0) json_error('Quantity cannot be negative');
        $chk = $pdo->prepare('SELECT id FROM parts WHERE id = ?');
        $chk->execute([$partId]);
        if (!$chk->fetch()) json_error('Part not found', 404);
        $cond = in_array(input_str('condition', 30), ['New', 'Used'], true) ? input_str('condition', 30) : 'New';
        if ($row = stock_row($pdo, (int) $shop['id'], $partId)) {
            $pdo->prepare('UPDATE stock SET price=?, quantity=?, part_condition=? WHERE id=?')
                ->execute([$price, $qty, $cond, $row['id']]);
        } else {
            $pdo->prepare('INSERT INTO stock (shop_id, part_id, price, quantity, part_condition) VALUES (?,?,?,?,?)')
                ->execute([$shop['id'], $partId, $price, $qty, $cond]);
        }
        break;

    case 'adjust':
        $row = stock_row($pdo, (int) $shop['id'], $partId) ?: json_error('This part is not in your stock', 404);
        $qty = max(0, (int) $row['quantity'] + input_int('delta'));
        $pdo->prepare('UPDATE stock SET quantity = ? WHERE id = ?')->execute([$qty, $row['id']]);
        break;

    case 'delete':
        $row = stock_row($pdo, (int) $shop['id'], $partId) ?: json_error('This part is not in your stock', 404);
        $pdo->prepare('DELETE FROM stock WHERE id = ?')->execute([$row['id']]);
        break;

    case 'bulk_price':
        $percent = (float) input('percent', 0);
        if ($percent == 0.0 || $percent < -90 || $percent > 500) json_error('percent must be between -90 and 500 (not 0)');
        $cat = input_str('category', 60);
        $sql = 'SELECT st.id, st.price FROM stock st JOIN parts p ON p.id = st.part_id WHERE st.shop_id = ?';
        $args = [$shop['id']];
        if ($cat !== '') { $sql .= ' AND p.category = ?'; $args[] = $cat; }
        $st = $pdo->prepare($sql);
        $st->execute($args);
        $up = $pdo->prepare('UPDATE stock SET price = ? WHERE id = ?');
        $changed = 0;
        foreach ($st->fetchAll() as $r) {
            $new = max(1, (int) round($r['price'] * (1 + $percent / 100)));
            if ($new !== (int) $r['price']) { $up->execute([$new, $r['id']]); $changed++; }
        }
        json_out(['ok' => true, 'changed' => $changed]);

    default:
        json_error('Unknown action');
}
json_out(['ok' => true]);
