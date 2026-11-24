<?php
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/database/db.php';

// Mechanic's Jobs tab.
// GET  jobs.php[?status=New,Accepted]     my jobs (soonest first) with photos and invoice
// POST (JSON or form), field "action":
//   accept | decline          New -> Accepted | Declined
//   start                     Accepted -> In progress
//   finish                    In progress -> Done
//   invoice  {labour, parts}  Done jobs (labour defaults to the quoted price)
//   paid     {paid:true|false}
//   photo    multipart: job_id + photo (JPG/PNG/WebP, 5 MB). Accepted, In progress or Done jobs.
//   remove_photo {photo_id}
$pdo = db();
$u = actor(['mechanic']);
$mech = my_mechanic($u);

function job_json(PDO $pdo, array $j): array {
    $st = $pdo->prepare('SELECT id, path FROM job_photos WHERE job_id = ? ORDER BY id');
    $st->execute([$j['id']]);
    $photos = [];
    foreach ($st->fetchAll() as $p) $photos[] = ['id' => (int) $p['id'], 'url' => photo_url('jobs', $p['path'])];
    $labour = $j['labour_cost'] === null ? null : (int) $j['labour_cost'];
    return [
        'id' => (int) $j['id'], 'client_name' => $j['client_name'], 'car' => $j['car'], 'problem' => $j['problem'],
        'price' => (int) $j['price'], 'slot' => $j['slot'], 'urgent' => (bool) $j['urgent'], 'status' => $j['status'],
        'created_at' => $j['created_at'], 'completed_at' => $j['completed_at'],
        'labour_cost' => $labour, 'parts_cost' => (int) $j['parts_cost'],
        'invoice_no' => 'INV-' . $j['id'],
        'invoice_total' => ($labour ?? (int) $j['price']) + (int) $j['parts_cost'],
        'paid' => (bool) $j['paid'], 'paid_at' => $j['paid_at'], 'photos' => $photos,
    ];
}

function load_job(PDO $pdo, int $id, int $mechId): array {
    $st = $pdo->prepare('SELECT * FROM job_requests WHERE id = ? AND mechanic_id = ?');
    $st->execute([$id, $mechId]);
    return $st->fetch() ?: json_error('Job not found', 404);
}

if (method() === 'GET') {
    $sql = 'SELECT * FROM job_requests WHERE mechanic_id = ?';
    $args = [$mech['id']];
    $want = array_filter(array_map('trim', explode(',', input_str('status', 80))));
    if ($want) {
        $sql .= ' AND status IN (' . implode(',', array_fill(0, count($want), '?')) . ')';
        $args = array_merge($args, $want);
    }
    $st = $pdo->prepare("$sql ORDER BY slot ASC LIMIT 200");
    $st->execute($args);
    json_out(['ok' => true, 'jobs' => array_map(fn($j) => job_json($pdo, $j), $st->fetchAll())]);
}

$action = input_str('action', 20);
$job = load_job($pdo, input_int('job_id') ?: input_int('id'), (int) $mech['id']);
$id = (int) $job['id'];

function move(PDO $pdo, array $job, array $from, string $to, string $extra = ''): void {
    if (!in_array($job['status'], $from, true)) {
        json_error("A job that is '{$job['status']}' cannot move to '$to'", 409);
    }
    $pdo->prepare("UPDATE job_requests SET status = ?$extra WHERE id = ?")->execute([$to, $job['id']]);
}

switch ($action) {
    case 'accept':  move($pdo, $job, ['New'], 'Accepted'); break;
    case 'decline': move($pdo, $job, ['New'], 'Declined'); break;
    case 'start':   move($pdo, $job, ['Accepted'], 'In progress'); break;
    case 'finish':
        if ($job['status'] !== 'In progress') json_error("A job that is '{$job['status']}' cannot be finished", 409);
        $pdo->prepare("UPDATE job_requests SET status = 'Done', completed_at = ? WHERE id = ?")->execute([now_sql(), $id]);
        break;

    case 'invoice':
        if ($job['status'] !== 'Done') json_error('Write the invoice once the job is done', 409);
        $labour = input_int('labour', (int) $job['price']);
        $parts = input_int('parts');
        if ($labour < 0 || $parts < 0) json_error('Amounts cannot be negative');
        $pdo->prepare('UPDATE job_requests SET labour_cost = ?, parts_cost = ? WHERE id = ?')->execute([$labour, $parts, $id]);
        break;

    case 'paid':
        if ($job['status'] !== 'Done') json_error('Only a finished job can be marked as paid', 409);
        $paid = filter_var(input('paid', true), FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
        $pdo->prepare('UPDATE job_requests SET paid = ?, paid_at = ? WHERE id = ?')
            ->execute([$paid, $paid ? now_sql() : null, $id]);
        break;

    case 'photo':
        if (!in_array($job['status'], ['Accepted', 'In progress', 'Done'], true)) {
            json_error('Accept the job before adding photos', 409);
        }
        $files = uploaded_files('photo');
        if (!$files) json_error('No photo received');
        $n = $pdo->prepare('SELECT COUNT(*) FROM job_photos WHERE job_id = ?');
        $n->execute([$id]);
        if ((int) $n->fetchColumn() + count($files) > 30) json_error('A job can hold 30 photos at most');
        foreach ($files as $f) {
            $name = save_image($f, 'jobs');
            $pdo->prepare('INSERT INTO job_photos (job_id, path, created_at) VALUES (?,?,?)')->execute([$id, $name, now_sql()]);
        }
        break;

    case 'remove_photo':
        $ph = $pdo->prepare('SELECT * FROM job_photos WHERE id = ? AND job_id = ?');
        $ph->execute([input_int('photo_id'), $id]);
        $row = $ph->fetch() ?: json_error('Photo not found', 404);
        $pdo->prepare('DELETE FROM job_photos WHERE id = ?')->execute([$row['id']]);
        @unlink(__DIR__ . '/uploads/jobs/' . basename($row['path']));
        break;

    default: json_error('Unknown action');
}
json_out(['ok' => true, 'job' => job_json($pdo, load_job($pdo, $id, (int) $mech['id']))]);
