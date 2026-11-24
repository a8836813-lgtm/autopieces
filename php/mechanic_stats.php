<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Mechanic dashboard numbers. Earnings = invoice total (labour + parts, labour defaults to the quoted price)
// of Done jobs, by day of completion.
// GET mechanic_stats.php -> jobs by status, done count, earnings today / week / last week / 7 daily totals,
//                           reports count, average rating.
$pdo = db();
$u = actor(['mechanic']);
$mech = my_mechanic($u);
$mid = (int) $mech['id'];

$one = function (string $sql, array $args = []) use ($pdo) {
    $st = $pdo->prepare($sql); $st->execute($args); return $st->fetchColumn();
};
function earned(PDO $pdo, int $mid, string $from, string $to): int {
    $st = $pdo->prepare("SELECT COALESCE(SUM(COALESCE(labour_cost, price) + parts_cost),0) FROM job_requests
                         WHERE mechanic_id = ? AND status = 'Done' AND completed_at >= ? AND completed_at < ?");
    $st->execute([$mid, $from, $to]);
    return (int) $st->fetchColumn();
}

$today = strtotime('today');
$daily = [];
for ($i = 6; $i >= 0; $i--) {
    $start = strtotime("-$i day", $today);
    $daily[] = earned($pdo, $mid, date('Y-m-d H:i:s', $start), date('Y-m-d H:i:s', strtotime('+1 day', $start)));
}
$byStatus = ['New' => 0, 'Accepted' => 0, 'In progress' => 0, 'Done' => 0, 'Declined' => 0];
$st = $pdo->prepare('SELECT status, COUNT(*) AS n FROM job_requests WHERE mechanic_id = ? GROUP BY status');
$st->execute([$mid]);
foreach ($st->fetchAll() as $r) $byStatus[$r['status']] = (int) $r['n'];

json_out(['ok' => true,
    'jobs' => $byStatus, 'jobs_done' => $byStatus['Done'],
    'today' => $daily[6], 'week' => array_sum($daily), 'daily' => $daily,
    'last_week' => earned($pdo, $mid, date('Y-m-d H:i:s', strtotime('-13 day', $today)), date('Y-m-d H:i:s', strtotime('-6 day', $today))),
    'unpaid' => (int) $one("SELECT COALESCE(SUM(COALESCE(labour_cost, price) + parts_cost),0) FROM job_requests WHERE mechanic_id = ? AND status = 'Done' AND paid = 0", [$mid]),
    'reports' => (int) $one('SELECT COUNT(*) FROM mechanic_reports WHERE mechanic_id = ?', [$mid]),
    'rating' => $one("SELECT ROUND(AVG(stars),1) FROM reviews WHERE target_kind = 'mechanic' AND target_id = ?", [$mid]),
]);
