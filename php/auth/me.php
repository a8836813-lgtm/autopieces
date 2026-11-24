<?php
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../database/db.php';

// Who am I? Send the token (Authorization: Bearer ...). Used by the app at start-up.
json_out(['ok' => true, 'user' => user_json(actor())]);
