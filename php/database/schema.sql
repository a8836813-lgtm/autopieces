-- AutoPièces schema (MySQL / MariaDB, XAMPP). Import in phpMyAdmin.
CREATE DATABASE IF NOT EXISTS autopieces CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE autopieces;

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

CREATE TABLE shops (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NULL,
  name VARCHAR(140) NOT NULL,
  type VARCHAR(140) DEFAULT '',
  phone VARCHAR(30) DEFAULT '',
  hours VARCHAR(60) DEFAULT '',
  rating DECIMAL(2,1) DEFAULT 0,
  lat DOUBLE NULL,
  lng DOUBLE NULL,
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE parts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  oem VARCHAR(60) DEFAULT '',
  fits VARCHAR(200) DEFAULT '',
  INDEX idx_oem (oem)
);

CREATE TABLE stock (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id INT NOT NULL,
  part_id INT NOT NULL,
  price INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  part_condition VARCHAR(30) DEFAULT 'New',
  FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
  FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
);

CREATE TABLE reservations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  stock_id INT NOT NULL,
  status ENUM('Pending','Confirmed','Cancelled') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (stock_id) REFERENCES stock(id) ON DELETE CASCADE
);

CREATE TABLE mechanic_reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  mechanic_id INT NOT NULL,
  car VARCHAR(120) NOT NULL,
  title VARCHAR(160) NOT NULL,
  body TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (mechanic_id) REFERENCES users(id) ON DELETE CASCADE
);
