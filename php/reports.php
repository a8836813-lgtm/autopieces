<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// GET  reports.php                        newest reports of all mechanics. Optional: q, category, mechanic_id,
//                                         sort=helpful|cheapest|fastest
// GET  reports.php?id=4                   one report
// POST (mechanic) {action:"create", car, title, problem, diagnosis, work_done, parts_text, category,
//                  labour_cost, parts_cost, duration_hours, warranty_months, cost?}
// POST (mechanic) {action:"update", id, ...same fields}   own reports only
// POST (mechanic) {action:"delete", id}
// POST (any signed-in user) {action:"helpful", id}        toggles "this report helped me"
$pdo = db();

$SEL = 'SELECT r.id, r.mechanic_id, m.name AS mechanic_name, r.car, r.category, r.title, r.problem, r.diagnosis,
               r.work_done, r.parts_text, r.cost, r.labour_cost, r.parts_cost, r.duration_hours, r.warranty_months,
               r.created_at, r.updated_at,
               (SELECT COUNT(*) FROM report_helpful h WHERE h.report_id = r.id) AS helpful
        FROM mechanic_reports r JOIN mechanics m ON m.id = r.mechanic_id';

function report_fields(): array {
    $labour = max(0, input_int('labour_cost'));
    $parts = max(0, input_int('parts_cost'));
    $cost = input('cost') !== null ? max(0, input_int('cost')) : $labour + $parts;
    return [
        'car' => input_str('car', 120), 'category' => input_str('category', 60), 'title' => input_str('title', 160),
        'problem' => input_str('problem', 2000), 'diagnosis' => input_str('diagnosis', 2000),
        'work_done' => input_str('work_done', 2000), 'parts_text' => input_str('parts_text', 300),
        'cost' => $cost, 'labour_cost' => $labour, 'parts_cost' => $parts,
        'duration_hours' => max(0, (float) input('duration_hours', 0)),
        'warranty_months' => max(0, input_int('warranty_months')),
    ];
}

if (method() === 'GET') {
    if (isset($_GET['id'])) {
        $st = $pdo->prepare("$SEL WHERE r.id = ?");
        $st->execute([(int) $_GET['id']]);
        $row = $st->fetch() ?: json_error('Report not found', 404);
        json_out(['ok' => true, 'report' => $row]);
    }
    $where = ['1=1']; $args = [];
    if (input_int('mechanic_id') > 0) { $where[] = 'r.mechanic_id = ?'; $args[] = input_int('mechanic_id'); }
    if (input_str('category', 60) !== '') { $where[] = 'r.category = ?'; $args[] = input_str('category', 60); }
    $q = input_str('q', 100);
    if ($q !== '') {
        $where[] = '(r.title LIKE ? OR r.car LIKE ? OR r.problem LIKE ? OR r.diagnosis LIKE ?)';
        array_push($args, "%$q%", "%$q%", "%$q%", "%$q%");
    }
    $order = match (input_str('sort', 10)) {
        'helpful'  => 'helpful DESC, r.id DESC',
        'cheapest' => 'r.cost ASC, r.id DESC',
        'fastest'  => 'r.duration_hours ASC, r.id DESC',
        default    => 'r.id DESC',
    };
    $st = $pdo->prepare("$SEL WHERE " . implode(' AND ', $where) . " ORDER BY $order LIMIT 100");
    $st->execute($args);
    json_out(['ok' => true, 'reports' => $st->fetchAll()]);
}

$action = input_str('action', 10);

if ($action === 'helpful') {
    $u = actor();
    $id = input_int('id');
    $chk = $pdo->prepare('SELECT id FROM mechanic_reports WHERE id = ?');
    $chk->execute([$id]);
    if (!$chk->fetch()) json_error('Report not found', 404);
    $has = $pdo->prepare('SELECT 1 FROM report_helpful WHERE report_id = ? AND user_id = ?');
    $has->execute([$id, $u['id']]);
    if ($has->fetch()) {
        $pdo->prepare('DELETE FROM report_helpful WHERE report_id = ? AND user_id = ?')->execute([$id, $u['id']]);
        $voted = false;
    } else {
        $pdo->prepare('INSERT INTO report_helpful (report_id, user_id) VALUES (?,?)')->execute([$id, $u['id']]);
        $voted = true;
    }
    $n = $pdo->prepare('SELECT COUNT(*) FROM report_helpful WHERE report_id = ?');
    $n->execute([$id]);
    json_out(['ok' => true, 'voted' => $voted, 'helpful' => (int) $n->fetchColumn()]);
}

$u = actor(['mechanic']);
$mech = my_mechanic($u);

if ($action === 'create') {
    $f = report_fields();
    if ($f['car'] === '' || $f['title'] === '') json_error('Car and title are required');
    $cols = array_keys($f);
    $pdo->prepare('INSERT INTO mechanic_reports (mechanic_id, created_at, ' . implode(', ', $cols) . ') VALUES (?,?,' .
                  implode(',', array_fill(0, count($cols), '?')) . ')')
        ->execute(array_merge([$mech['id'], now_sql()], array_values($f)));
    $st = $pdo->prepare("$SEL WHERE r.id = ?");
    $st->execute([(int) $pdo->lastInsertId()]);
    json_out(['ok' => true, 'report' => $st->fetch()], 201);
}

$id = input_int('id');
$own = $pdo->prepare('SELECT mechanic_id FROM mechanic_reports WHERE id = ?');
$own->execute([$id]);
$owner = $own->fetchColumn();
if ($owner === false) json_error('Report not found', 404);
if ((int) $owner !== (int) $mech['id']) json_error('Not your report', 403);

if ($action === 'update') {
    $f = report_fields();
    if ($f['car'] === '' || $f['title'] === '') json_error('Car and title are required');
    $set = implode(', ', array_map(fn($c) => "$c = ?", array_keys($f)));
    $pdo->prepare("UPDATE mechanic_reports SET $set, updated_at = ? WHERE id = ?")
        ->execute(array_merge(array_values($f), [now_sql(), $id]));
    $st = $pdo->prepare("$SEL WHERE r.id = ?");
    $st->execute([$id]);
    json_out(['ok' => true, 'report' => $st->fetch()]);
}
if ($action === 'delete') {
    $pdo->prepare('DELETE FROM mechanic_reports WHERE id = ?')->execute([$id]);
    json_out(['ok' => true]);
}
json_error('Unknown action');
