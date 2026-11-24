<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Shop owner dashboard numbers (sales come from Completed reservations).
// GET shop_stats.php  ->  today, this week, last week, 7 daily totals (oldest first), pending orders,
//                         stock value, out-of-stock and low-stock counts, top 5 parts, average rating.
$pdo = db();
$u = actor(['shop']);
$shop = my_shop($u);
$sid = (int) $shop['id'];

function sales_between(PDO $pdo, int $shopId, string $from, string $to): int {
    $st = $pdo->prepare("SELECT COALESCE(SUM(r.price),0) FROM reservations r JOIN stock s ON s.id = r.stock_id
                         WHERE s.shop_id = ? AND r.status = 'Completed' AND r.completed_at >= ? AND r.completed_at < ?");
    $st->execute([$shopId, $from, $to]);
    return (int) $st->fetchColumn();
}

$today = strtotime('today');
$daily = [];
for ($i = 6; $i >= 0; $i--) {
    $start = strtotime("-$i day", $today);
    $daily[] = sales_between($pdo, $sid, date('Y-m-d H:i:s', $start), date('Y-m-d H:i:s', strtotime('+1 day', $start)));
}
$lastWeek = sales_between($pdo, $sid, date('Y-m-d H:i:s', strtotime('-13 day', $today)),
                          date('Y-m-d H:i:s', strtotime('-6 day', $today)));

$one = function (string $sql, array $args = []) use ($pdo) {
    $st = $pdo->prepare($sql); $st->execute($args); return $st->fetchColumn();
};
$top = $pdo->prepare("SELECT p.name, COUNT(*) AS sold FROM reservations r
                      JOIN stock s ON s.id = r.stock_id JOIN parts p ON p.id = s.part_id
                      WHERE s.shop_id = ? AND r.status = 'Completed' GROUP BY p.id, p.name ORDER BY sold DESC LIMIT 5");
$top->execute([$sid]);

json_out(['ok' => true,
    'today' => $daily[6], 'week' => array_sum($daily), 'last_week' => $lastWeek, 'daily' => $daily,
    'pending_orders' => (int) $one("SELECT COUNT(*) FROM reservations r JOIN stock s ON s.id = r.stock_id WHERE s.shop_id = ? AND r.status = 'Pending'", [$sid]),
    'stock_value' => (int) $one('SELECT COALESCE(SUM(price * quantity),0) FROM stock WHERE shop_id = ?', [$sid]),
    'out_of_stock' => (int) $one('SELECT COUNT(*) FROM stock WHERE shop_id = ? AND quantity = 0', [$sid]),
    'low_stock' => (int) $one('SELECT COUNT(*) FROM stock WHERE shop_id = ? AND quantity > 0 AND quantity <= ?', [$sid, (int) $shop['low_stock_limit']]),
    'top_parts' => $top->fetchAll(),
    'rating' => $one("SELECT ROUND(AVG(stars),1) FROM reviews WHERE target_kind = 'shop' AND target_id = ?", [$sid]),
]);
