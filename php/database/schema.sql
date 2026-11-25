-- AutoPièces schema v2 (MySQL / MariaDB, XAMPP). Import in phpMyAdmin.
--
-- IMPORTANT: this replaces the first version. If you imported the old schema,
-- drop the `autopieces` database in phpMyAdmin first (it only held test data),
-- then import this file, then import seed.sql for the demo data.
--
-- Everything that the app keeps in memory today has a table here:
--   shops, parts, stock, reservations      (client + shop owner)
--   mechanics, mechanic_services           (mechanic profile)
--   mechanic_reports, report_helpful       (repair reports)
--   appointments, job_requests, job_photos (client asks, mechanic works, client follows)
--   reviews, review_photos                 (shops and mechanics, with replies)
--   favorites, price_alerts                (client)
--   chat_messages                          (client <-> mechanic / shop)

CREATE DATABASE IF NOT EXISTS autopieces CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE autopieces;

-- ───────────────────────────── accounts ─────────────────────────────
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  role ENUM('client','mechanic','shop') NOT NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(160) NOT NULL,
  phone VARCHAR(30) DEFAULT '',
  password_hash VARCHAR(255) NOT NULL,
  profile_json TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_email_role (email, role)
);

-- ───────────────────────────── shops and parts ─────────────────────────────
CREATE TABLE shops (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NULL,
  name VARCHAR(140) NOT NULL,
  type VARCHAR(140) DEFAULT '',
  address VARCHAR(200) DEFAULT '',
  phone VARCHAR(30) DEFAULT '',
  hours VARCHAR(80) DEFAULT '',
  about VARCHAR(400) DEFAULT '',
  open_now TINYINT DEFAULT 1,
  delivers TINYINT DEFAULT 0,
  low_stock_limit INT DEFAULT 1,
  payments VARCHAR(120) NOT NULL DEFAULT 'Cash',
  rating DECIMAL(2,1) DEFAULT 0,
  lat DOUBLE NULL,
  lng DOUBLE NULL,
  UNIQUE KEY uq_shop_owner (owner_id),
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE parts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  oem VARCHAR(60) DEFAULT '',
  category VARCHAR(60) DEFAULT '',
  fits VARCHAR(200) DEFAULT '',
  alt_serials VARCHAR(300) DEFAULT '',   -- other serial numbers, comma separated
  fitments_json TEXT,                    -- [{"brand":"renault","model":"Clio"}] (empty = universal)
  INDEX idx_oem (oem)
);

CREATE TABLE stock (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id INT NOT NULL,
  part_id INT NOT NULL,
  price INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  part_condition VARCHAR(30) DEFAULT 'New',
  UNIQUE KEY uq_shop_part (shop_id, part_id),
  FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
  FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
);

CREATE TABLE reservations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  stock_id INT NOT NULL,
  price INT NOT NULL,                    -- price when the client reserved
  status ENUM('Pending','Confirmed','Completed','Cancelled') DEFAULT 'Pending',
  reviewed TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_res_client (client_id),
  INDEX idx_res_stock (stock_id),
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (stock_id) REFERENCES stock(id) ON DELETE CASCADE
);

-- ───────────────────────────── mechanics ─────────────────────────────
CREATE TABLE mechanics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NULL,
  name VARCHAR(140) NOT NULL,
  specialties VARCHAR(300) DEFAULT '',   -- comma separated
  years_experience INT DEFAULT 0,
  address VARCHAR(200) DEFAULT '',
  phone VARCHAR(30) DEFAULT '',
  hours VARCHAR(80) DEFAULT '',
  about VARCHAR(600) DEFAULT '',
  response_time VARCHAR(60) DEFAULT 'Replies within a day',
  languages VARCHAR(120) DEFAULT 'Arabic, French',
  mobile_service TINYINT DEFAULT 0,
  premium TINYINT DEFAULT 0,
  verified TINYINT DEFAULT 0,
  available TINYINT DEFAULT 1,
  rating DECIMAL(2,1) DEFAULT 0,
  lat DOUBLE NULL,
  lng DOUBLE NULL,
  UNIQUE KEY uq_mech_owner (owner_id),
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE mechanic_services (
  id INT AUTO_INCREMENT PRIMARY KEY,
  mechanic_id INT NOT NULL,
  name VARCHAR(120) NOT NULL,
  price_from INT NOT NULL DEFAULT 0,
  FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE
);

CREATE TABLE mechanic_reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  mechanic_id INT NOT NULL,
  car VARCHAR(120) NOT NULL,
  category VARCHAR(60) DEFAULT '',
  title VARCHAR(160) NOT NULL,
  problem TEXT,
  diagnosis TEXT,
  work_done TEXT,
  parts_text VARCHAR(300) DEFAULT '',
  cost INT DEFAULT 0,
  labour_cost INT DEFAULT 0,
  parts_cost INT DEFAULT 0,
  duration_hours DOUBLE DEFAULT 0,
  warranty_months INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_report_mech (mechanic_id),
  FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE
);

CREATE TABLE report_helpful (
  report_id INT NOT NULL,
  user_id INT NOT NULL,
  PRIMARY KEY (report_id, user_id),
  FOREIGN KEY (report_id) REFERENCES mechanic_reports(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ───────────────────── jobs: client asks, mechanic works ─────────────────────
CREATE TABLE job_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  mechanic_id INT NOT NULL,
  client_id INT NULL,
  client_name VARCHAR(120) DEFAULT '',
  car VARCHAR(120) DEFAULT '',
  problem VARCHAR(400) DEFAULT '',
  price INT DEFAULT 0,                   -- quoted price in DZD
  slot DATETIME NOT NULL,                -- when the client wants it done
  urgent TINYINT DEFAULT 0,
  distance_km DOUBLE NULL,
  status ENUM('New','Accepted','In progress','Done','Declined') DEFAULT 'New',
  completed_at TIMESTAMP NULL DEFAULT NULL,
  labour_cost INT NULL,                  -- invoice
  parts_cost INT DEFAULT 0,
  paid TINYINT DEFAULT 0,
  paid_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_job_mech (mechanic_id, status),
  FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE job_photos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_id INT NOT NULL,
  path VARCHAR(200) NOT NULL,            -- file name inside uploads/jobs/
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES job_requests(id) ON DELETE CASCADE
);

CREATE TABLE appointments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  mechanic_id INT NOT NULL,
  job_id INT NULL,                       -- the job it created on the mechanic side
  service VARCHAR(120) NOT NULL,
  when_at DATETIME NOT NULL,
  note VARCHAR(400) DEFAULT '',
  status ENUM('Sent','Cancelled') DEFAULT 'Sent',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_appt_client (client_id),
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE,
  FOREIGN KEY (job_id) REFERENCES job_requests(id) ON DELETE SET NULL
);

-- ───────────────────────────── reviews ─────────────────────────────
CREATE TABLE reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  target_kind ENUM('shop','mechanic') NOT NULL,
  target_id INT NOT NULL,
  author_id INT NOT NULL,
  author_name VARCHAR(120) DEFAULT '',
  stars TINYINT NOT NULL,
  comment VARCHAR(1000) DEFAULT '',
  reply VARCHAR(1000) DEFAULT NULL,      -- answer of the shop or mechanic
  reservation_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_review_target (target_kind, target_id),
  FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE review_photos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_id INT NOT NULL,
  path VARCHAR(200) NOT NULL,            -- file name inside uploads/reviews/
  FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE
);

-- ───────────────────────────── client extras ─────────────────────────────
CREATE TABLE favorites (
  user_id INT NOT NULL,
  kind ENUM('shop','part','mechanic') NOT NULL,
  target_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, kind, target_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE price_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  part_id INT NOT NULL,
  target_price INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_alert (user_id, part_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
);

-- ───────────────────────────── chat ─────────────────────────────
-- Identity is stored as plain text references so the chat also works before the
-- app login is wired to this database:
--   client_ref = the client's e-mail, peer_kind = 'mechanic' | 'shop',
--   peer_id    = mechanics.id or shops.id (as text, e.g. "1").
CREATE TABLE chat_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_ref VARCHAR(160) NOT NULL,
  client_name VARCHAR(120) NOT NULL DEFAULT '',
  peer_kind ENUM('mechanic','shop') NOT NULL,
  peer_id VARCHAR(40) NOT NULL,
  peer_name VARCHAR(140) NOT NULL DEFAULT '',
  sender ENUM('client','peer') NOT NULL,
  body TEXT,
  photo_path VARCHAR(200) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_conv (client_ref, peer_kind, peer_id, id),
  INDEX idx_peer (peer_kind, peer_id, id)
);
