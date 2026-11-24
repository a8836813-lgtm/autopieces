<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Client:      GET reservations.php                     my reservations (order history)
//              POST {action:"create", stock_id}          reserve a part
//              POST {action:"cancel", id}                cancel while Pending or Confirmed
// Shop owner:  GET reservations.php?as=shop[&status=Pending]
//              POST {action:"confirm", id}               Pending   -> Confirmed
//              POST {action:"decline", id}               Pending   -> Cancelled
//              POST {action:"complete", id}              Confirmed -> Completed (picked up, stock -1)
$pdo = db();

$SELECT = 'SELECT r.id, r.status, r.price, r.reviewed, r.created_at, r.completed_at,
                  u.name AS client_name, u.phone AS client_phone,
                  st.id AS stock_id, st.quantity, st.part_condition,
                  p.id AS part_id, p.name AS part_name, p.oem, p.category,
                  s.id AS shop_id, s.name AS shop_name, s.phone AS shop_phone
           FROM reservations r
           JOIN users u ON u.id = r.client_id
           JOIN stock st ON st.id = r.stock_id
           JOIN parts p ON p.id = st.part_id
           JOIN shops s ON s.id = st.shop_id';

function reservation_by_id(PDO $pdo, string $select, int $id): ?array {
    $st = $pdo->prepare("$select WHERE r.id = ?");
    $st->execute([$id]);
    return $st->fetch() ?: null;
}

if (method() === 'GET') {
    if (input_str('as', 10) === 'shop') {
        $u = actor(['shop']);
        $shop = my_shop($u);
        $sql = "$SELECT WHERE s.id = ?";
        $args = [$shop['id']];
        if (input_str('status', 20) !== '') { $sql .= ' AND r.status = ?'; $args[] = input_str('status', 20); }
    } else {
        $u = actor(['client']);
        $sql = "$SELECT WHERE r.client_id = ?";
        $args = [$u['id']];
    }
    $st = $pdo->prepare("$sql ORDER BY r.id DESC LIMIT 200");
    $st->execute($args);
    json_out(['ok' => true, 'reservations' => $st->fetchAll()]);
}

$action = input_str('action', 20);

if ($action === 'create') {
    $u = actor(['client']);
    $stockId = input_int('stock_id');
    $st = $pdo->prepare('SELECT * FROM stock WHERE id = ?');
    $st->execute([$stockId]);
    $stock = $st->fetch() ?: json_error('Part not found in this shop', 404);
    if ((int) $stock['quantity'] <= 0) json_error('This part is out of stock', 409);

    $dup = $pdo->prepare("SELECT id FROM reservations WHERE client_id = ? AND stock_id = ? AND status IN ('Pending','Confirmed')");
    $dup->execute([$u['id'], $stockId]);
    if ($dup->fetch()) json_error('You already reserved this part', 409);

    $pdo->prepare('INSERT INTO reservations (client_id, stock_id, price, created_at) VALUES (?,?,?,?)')
        ->execute([$u['id'], $stockId, $stock['price'], now_sql()]);
    json_out(['ok' => true, 'reservation' => reservation_by_id($pdo, $SELECT, (int) $pdo->lastInsertId())], 201);
}

$id = input_int('id');
$r = reservation_by_id($pdo, $SELECT, $id) ?: json_error('Reservation not found', 404);

if ($action === 'cancel') {
    $u = actor(['client']);
    $own = $pdo->prepare('SELECT client_id FROM reservations WHERE id = ?');
    $own->execute([$id]);
    if ((int) $own->fetchColumn() !== (int) $u['id']) json_error('Not your reservation', 403);
    if (!in_array($r['status'], ['Pending', 'Confirmed'], true)) json_error('This reservation can no longer be cancelled', 409);
    $pdo->prepare("UPDATE reservations SET status = 'Cancelled' WHERE id = ?")->execute([$id]);
    json_out(['ok' => true, 'reservation' => reservation_by_id($pdo, $SELECT, $id)]);
}

if (in_array($action, ['confirm', 'decline', 'complete'], true)) {
    $u = actor(['shop']);
    $shop = my_shop($u);
    if ((int) $r['shop_id'] !== (int) $shop['id']) json_error('Not an order of your shop', 403);

    if ($action === 'confirm' || $action === 'decline') {
        if ($r['status'] !== 'Pending') json_error('Only a pending order can be ' . ($action === 'confirm' ? 'confirmed' : 'declined'), 409);
        $new = $action === 'confirm' ? 'Confirmed' : 'Cancelled';
        $pdo->prepare('UPDATE reservations SET status = ? WHERE id = ?')->execute([$new, $id]);
    } else {
        if ($r['status'] !== 'Confirmed') json_error('Only a confirmed order can be completed', 409);
        $pdo->beginTransaction();
        $pdo->prepare("UPDATE reservations SET status = 'Completed', completed_at = ? WHERE id = ?")
            ->execute([now_sql(), $id]);
        $pdo->prepare('UPDATE stock SET quantity = quantity - 1 WHERE id = ? AND quantity > 0')
            ->execute([$r['stock_id']]);
        $pdo->commit();
    }
    json_out(['ok' => true, 'reservation' => reservation_by_id($pdo, $SELECT, $id)]);
}

json_error('Unknown action');
