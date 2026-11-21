<?php
/**
 * AutoPièces PHP API: configuration (XAMPP / MySQL).
 *
 * Install: copy this whole /php folder to C:\xampp\htdocs\autopieces\api
 * then import database/schema.sql in phpMyAdmin (http://localhost/phpmyadmin).
 *
 * PLACEHOLDERS: change the values marked CHANGE_ME.
 */

// ───────── MySQL (XAMPP defaults: user "root", empty password) ─────────
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 3306);
define('DB_NAME', 'autopieces');
define('DB_USER', 'root');
define('DB_PASS', '');            // CHANGE_ME if you set a MySQL password

// ───────── Supabase (PLACEHOLDER, optional, used later for sync/storage) ─────────
define('SUPABASE_URL',      'YOUR_SUPABASE_URL');
define('SUPABASE_ANON_KEY', 'YOUR_SUPABASE_ANON_KEY');

// ───────── Security ─────────
define('JWT_SECRET', 'CHANGE_ME_TO_A_LONG_RANDOM_STRING');
define('ALLOWED_ORIGIN', '*');    // CHANGE_ME to your web origin before going public
