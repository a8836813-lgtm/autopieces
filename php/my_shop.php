<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Shop owner: GET = my shop, POST = change it (hours, phone, about, open, delivery, low-stock limit...).
$u = actor(['shop']);
$shop = my_shop($u);

if (method() === 'POST') {
    $fields = [
        'name' => input_str('name', 140), 'type' => input_str('type', 140),
        'address' => input_str('address', 200), 'phone' => input_str('phone', 30),
        'hours' => input_str('hours', 80), 'about' => input_str('about', 400),
    ];
    $set = []; $args = [];
    foreach ($fields as $col => $val) {
        if (input($col) !== null) {
            if ($col === 'name' && $val === '') json_error('Shop name cannot be empty');
            $set[] = "$col = ?"; $args[] = $val;
        }
    }
    foreach (['open_now', 'delivers'] as $col) {
        if (input($col) !== null) { $set[] = "$col = ?"; $args[] = input($col) ? 1 : 0; }
    }
    if (input('low_stock_limit') !== null) { $set[] = 'low_stock_limit = ?'; $args[] = max(0, input_int('low_stock_limit')); }
    foreach (['lat', 'lng'] as $col) {
        if (input($col) !== null) { $set[] = "$col = ?"; $args[] = (float) input($col); }
    }
    if ($set) {
        $args[] = $shop['id'];
        db()->prepare('UPDATE shops SET ' . implode(', ', $set) . ' WHERE id = ?')->execute($args);
    }
    $st = db()->prepare('SELECT * FROM shops WHERE id = ?');
    $st->execute([$shop['id']]);
    $shop = $st->fetch();
}
json_out(['ok' => true, 'shop' => $shop]);
