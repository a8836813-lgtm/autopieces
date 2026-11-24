<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Client side of a mechanic appointment. Creating one also creates the job in the mechanic's Jobs tab,
// so the client can follow its status, the progress photos and the invoice.
//
// GET  appointments.php                                   my appointments (with job status, photos, invoice)
// POST {action:"create", mechanic_id, service, when, note?, car?}
// POST {action:"cancel", id}                              only while the mechanic has not answered (job New)
$pdo = db();
$u = actor(['client']);

$SEL = 'SELECT a.id, a.service, a.when_at, a.note, a.status AS appointment_status, a.created_at,
               m.id AS mechanic_id, m.name AS mechanic_name, m.phone AS mechanic_phone,
               j.id AS job_id, j.status AS job_status, j.labour_cost, j.parts_cost, j.paid, j.paid_at
        FROM appointments a
        JOIN mechanics m ON m.id = a.mechanic_id
        LEFT JOIN job_requests j ON j.id = a.job_id';

function shape(PDO $pdo, array $rows): array {
    foreach ($rows as &$r) {
        $r['job_status'] = $r['job_status'] ?? 'New';
        $r['invoice_total'] = $r['labour_cost'] === null ? null : (int) $r['labour_cost'] + (int) $r['parts_cost'];
        $r['invoice_no'] = $r['job_id'] ? 'INV-' . $r['job_id'] : null;
        $r['paid'] = (bool) $r['paid'];
        $r['photos'] = [];
        if ($r['job_id']) {
            $st = $pdo->prepare('SELECT id, path FROM job_photos WHERE job_id = ? ORDER BY id');
            $st->execute([$r['job_id']]);
            foreach ($st->fetchAll() as $p) {
                $r['photos'][] = ['id' => (int) $p['id'], 'url' => photo_url('jobs', $p['path'])];
            }
        }
    }
    return $rows;
}

if (method() === 'GET') {
    $st = $pdo->prepare("$SEL WHERE a.client_id = ? ORDER BY a.id DESC LIMIT 100");
    $st->execute([$u['id']]);
    json_out(['ok' => true, 'appointments' => shape($pdo, $st->fetchAll())]);
}

$action = input_str('action', 10);

if ($action === 'create') {
    $mid = input_int('mechanic_id');
    $service = input_str('service', 120);
    $when = parse_datetime(input('when'));
    if ($service === '' || $when === null) json_error('service and a valid date (when) are required');
    if (strtotime($when) < time() - 60) json_error('Choose a date in the future');
    $st = $pdo->prepare('SELECT * FROM mechanics WHERE id = ?');
    $st->execute([$mid]);
    $mech = $st->fetch() ?: json_error('Mechanic not found', 404);

    $price = 0;
    $sv = $pdo->prepare('SELECT price_from FROM mechanic_services WHERE mechanic_id = ? AND name = ?');
    $sv->execute([$mid, $service]);
    if (($p = $sv->fetchColumn()) !== false) $price = (int) $p;

    $note = input_str('note', 400);
    $pdo->beginTransaction();
    $pdo->prepare('INSERT INTO job_requests (mechanic_id, client_id, client_name, car, problem, price, slot, created_at)
                   VALUES (?,?,?,?,?,?,?,?)')
        ->execute([$mid, $u['id'], $u['name'], input_str('car', 120) ?: 'Car not specified',
                   $note === '' ? $service : "$service. $note", $price, $when, now_sql()]);
    $jobId = (int) $pdo->lastInsertId();
    $pdo->prepare('INSERT INTO appointments (client_id, mechanic_id, job_id, service, when_at, note, created_at)
                   VALUES (?,?,?,?,?,?,?)')
        ->execute([$u['id'], $mid, $jobId, $service, $when, $note, now_sql()]);
    $id = (int) $pdo->lastInsertId();
    $pdo->commit();

    $st = $pdo->prepare("$SEL WHERE a.id = ?");
    $st->execute([$id]);
    json_out(['ok' => true, 'appointment' => shape($pdo, $st->fetchAll())[0]], 201);
}

if ($action === 'cancel') {
    $id = input_int('id');
    $st = $pdo->prepare('SELECT a.*, j.status AS job_status FROM appointments a
                         LEFT JOIN job_requests j ON j.id = a.job_id WHERE a.id = ? AND a.client_id = ?');
    $st->execute([$id, $u['id']]);
    $a = $st->fetch() ?: json_error('Appointment not found', 404);
    if ($a['status'] === 'Cancelled') json_error('Already cancelled', 409);
    if (($a['job_status'] ?? 'New') !== 'New') json_error('The mechanic already answered, call or chat to cancel', 409);
    $pdo->beginTransaction();
    $pdo->prepare("UPDATE appointments SET status = 'Cancelled', job_id = NULL WHERE id = ?")->execute([$id]);
    if ($a['job_id']) $pdo->prepare('DELETE FROM job_requests WHERE id = ?')->execute([$a['job_id']]);
    $pdo->commit();
    json_out(['ok' => true]);
}
json_error('Unknown action');
