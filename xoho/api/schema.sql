-- ─── XOHO Database Schema ─────────────────────────────────────────────────
-- Run this once in phpMyAdmin (Systalink cPanel) or via MySQL CLI
-- Database: xoho_db (create it first in cPanel → MySQL Databases)

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- ─── Products ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `products` (
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255)     NOT NULL,
  `pole`        ENUM('administratif','academique','citoyen','business','vie-pratique') NOT NULL,
  `price`       SMALLINT UNSIGNED NOT NULL DEFAULT 500,
  `short_desc`  VARCHAR(320)     NOT NULL DEFAULT '',
  `full_desc`   TEXT             NOT NULL DEFAULT '',
  `bullets`     TEXT             NOT NULL DEFAULT '',  -- newline-separated
  `format`      VARCHAR(100)     NOT NULL DEFAULT '',  -- e.g. "PDF + Excel"
  `file_size`   VARCHAR(50)      NOT NULL DEFAULT '',  -- e.g. "1.2 Mo"
  `file_path`   VARCHAR(500)     NOT NULL DEFAULT '',  -- relative path under uploads/
  `preview_url` VARCHAR(500)     NOT NULL DEFAULT '',  -- URL or relative path
  `published`   TINYINT(1)       NOT NULL DEFAULT 0,
  `top_sell`    TINYINT(1)       NOT NULL DEFAULT 0,
  `featured`    TINYINT(1)       NOT NULL DEFAULT 0,
  `created_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pole_published` (`pole`, `published`),
  KEY `idx_top_sell`       (`top_sell`, `published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Orders ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `orders` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id`    INT UNSIGNED NOT NULL,
  `product_name`  VARCHAR(255) NOT NULL,
  `amount`        SMALLINT UNSIGNED NOT NULL,
  `buyer_name`    VARCHAR(150) NOT NULL,
  `buyer_email`   VARCHAR(200) NOT NULL DEFAULT '',
  `buyer_phone`   VARCHAR(30)  NOT NULL,
  `status`        ENUM('pending','completed','accessed','failed') NOT NULL DEFAULT 'pending',
  `kkiapay_txid`  VARCHAR(120) NOT NULL DEFAULT '',
  `download_token` CHAR(64)    NOT NULL DEFAULT '',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_download_token` (`download_token`),
  KEY `idx_status`      (`status`),
  KEY `idx_product_id`  (`product_id`),
  KEY `idx_buyer_phone` (`buyer_phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Admin Users ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `admin_users` (
  `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `email`        VARCHAR(200)  NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `name`         VARCHAR(150)  NOT NULL DEFAULT 'Administrateur',
  `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks = 1;

-- ─── Default admin account ─────────────────────────────────────────────────
-- Password: admin123 (CHANGE THIS immediately via the admin panel or phpMyAdmin)
-- Hash generated with: password_hash('admin123', PASSWORD_DEFAULT)
INSERT IGNORE INTO `admin_users` (`email`, `password_hash`, `name`) VALUES
('admin@xoho.bj', '$2y$12$eImiTXuWVxfM37uY4JANjQ==XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'Admin XOHO');
-- ⚠️  Replace the hash above by running: php -r "echo password_hash('YOUR_PASSWORD', PASSWORD_DEFAULT);"
-- Or use the seed script: php api/seed_admin.php
