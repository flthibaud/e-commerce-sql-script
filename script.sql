-- ========================================
-- Script SQL MySQL 8 (InnoDB)
-- Catalogue d'articles (catégories intervallaires, gestion articles, utilisateurs, commandes, mouvements)
-- Respect des conventions de nommage et ordre demandé
-- ========================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================
-- 1) CREATE DATABASE (sans contraintes) - ordre alphabétique
-- =======================

CREATE DATABASE IF NOT EXISTS iutdb_ecommerce
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- Utilisation de la base
USE iutdb_ecommerce;

-- =======================
-- 2) CREATE TABLE (sans contraintes) - ordre alphabétique
-- =======================

DROP TABLE IF EXISTS `article_categories`;
CREATE TABLE `article_categories` (
  `article_id`              BIGINT UNSIGNED NOT NULL,
  `category_id`             BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `articles`;
CREATE TABLE `articles` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sku`                     VARCHAR(100) NOT NULL COMMENT "doit être unique",
  `title`                   VARCHAR(255) NOT NULL,
  `description`             LONGTEXT,
  `photo_url`               VARCHAR(255),
  `unit_price`              DECIMAL(12,3) NOT NULL COMMENT "si renseigné, doit être supérieur ou égal à 0",
  `vat_rate`                DECIMAL(5,2) NOT NULL COMMENT "si renseigné, doit être supérieur ou égal à 0",
  `stock_quantity`          INT NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - valeur initiale du stock, mise à jour automatiquement par triggers lors des mouvements"
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name`                    VARCHAR(255) NOT NULL,
  `slug`                    VARCHAR(255) AS (LOWER(REPLACE(`name`, ' ', '-'))) STORED,
  `description`             LONGTEXT,
  `border_left`             INT NOT NULL COMMENT "doit être positif",
  `border_right`            INT NOT NULL COMMENT "doit être strictement supérieur à border_left (modéle intervallaire)"
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `order_lines`;
CREATE TABLE `order_lines` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `order_id`                BIGINT UNSIGNED NOT NULL,
  `article_id`              BIGINT UNSIGNED,
  `article_sku`             VARCHAR(100) NOT NULL COMMENT "hydraté par trigger",
  `article_title`           VARCHAR(255) NOT NULL COMMENT "hydraté par trigger",
  `article_description`     LONGTEXT COMMENT "hydraté par trigger",
  `article_photo_url`       VARCHAR(255) COMMENT "hydraté par trigger",
  `article_unit_price`      DECIMAL(12,3) NOT NULL COMMENT "doit être supérieur ou égal à 0 - hydraté par trigger",
  `article_vat_rate`        DECIMAL(5,2) NOT NULL COMMENT "doit être supérieur ou égal à 0 - hydraté par trigger",
  `quantity`                INT NOT NULL COMMENT "doit être positif",
  `line_net`                DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger",
  `line_vat`                DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger",
  `line_incl_vat`           DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger"
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id`                 BIGINT UNSIGNED,
  `user_firstname`          VARCHAR(100) NOT NULL COMMENT "hydraté par trigger",
  `user_lastname`           VARCHAR(100) NOT NULL COMMENT "hydraté par trigger",
  `user_email`              VARCHAR(255) NOT NULL COMMENT "hydraté par trigger",
  `user_phone`              VARCHAR(50) COMMENT "hydraté par trigger",
  `user_billing_address`    TEXT COMMENT "hydraté par trigger",
  `user_delivery_address`   TEXT COMMENT "hydraté par trigger",
  `status`                  ENUM('draft','confirmed','paid','cancelled') NOT NULL DEFAULT 'draft' COMMENT "forcer 'draft' à l'insertion",
  `total_net`               DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger",
  `total_vat`               DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger",
  `total_incl_vat`          DECIMAL(14,3) NOT NULL DEFAULT 0 COMMENT "doit être supérieur ou égal à 0 - calculé par trigger",
  `order_number`            VARCHAR(50) DEFAULT NULL COMMENT "doit être unique (hydraté par trigger)"
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `order_history`;
CREATE TABLE `order_history` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `order_id`                BIGINT UNSIGNED NOT NULL,
  `changed_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `previous_status`         ENUM('draft','confirmed','paid','cancelled') NOT NULL,
  `new_status`              ENUM('draft','confirmed','paid','cancelled') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `stock_movements`;
CREATE TABLE `stock_movements` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `article_id`              BIGINT UNSIGNED NOT NULL,
  `change_quantity`         INT NOT NULL,
  `reason`                  VARCHAR(100) NOT NULL,
  `before_qty`              INT NOT NULL,
  `after_qty`               INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT "Lignes insérées automatiquement par triggers lors du changement de statut d'une commande ('paid' ou 'cancelled')";

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `firstname`               VARCHAR(100) NOT NULL,
  `lastname`                VARCHAR(100) NOT NULL,
  `email`                   VARCHAR(255) NOT NULL COMMENT "doit être un email valide",
  `password`                VARCHAR(255) NOT NULL COMMENT "mot de passe crypté en SHA1, respect des régles de complexité avant cryptage",
  `phone`                   VARCHAR(50),
  `billing_address`         TEXT,
  `delivery_address`        TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================
-- 3) ADD CONSTRAINTS - ordre alphabétique
-- =======================

-- article_categories
ALTER TABLE `article_categories`
  ADD CONSTRAINT `pk_article_categories_article_id_category_id` PRIMARY KEY(`article_id`, `category_id`),
  ADD CONSTRAINT `fk_article_categories_article_id` FOREIGN KEY(`article_id`) REFERENCES `articles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_article_categories_category_id` FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- articles
ALTER TABLE `articles`
  ADD CONSTRAINT `uk_articles_sku` UNIQUE(`sku`);

-- categories
ALTER TABLE `categories`
  ADD CONSTRAINT `uk_categories_slug` UNIQUE(`slug`),
  ADD CONSTRAINT `chk_categories_border_intervall` CHECK (`border_right` > `border_left`);

-- order_lines
ALTER TABLE `order_lines`
  ADD CONSTRAINT `fk_order_lines_order_id` FOREIGN KEY(`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_order_lines_article_id` FOREIGN KEY(`article_id`) REFERENCES `articles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- orders
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_user_id` FOREIGN KEY(`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `uk_orders_order_number` UNIQUE(`order_number`);

-- order_history
ALTER TABLE `order_history`
  ADD CONSTRAINT `fk_order_history_order_id` FOREIGN KEY(`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- stock_movements
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `fk_stock_movements_article_id` FOREIGN KEY(`article_id`) REFERENCES `articles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- users
ALTER TABLE `users`
  ADD CONSTRAINT `uk_users_email` UNIQUE(`email`);

-- =======================
-- 4 PROCEDURE UTILITAIRE (utilisée par les triggers users)
-- =======================

-- users
DROP PROCEDURE IF EXISTS `proc_user_validate_and_hash_password`;
DELIMITER $$
CREATE PROCEDURE `proc_user_validate_and_hash_password`(INOUT p_password VARCHAR(255))
BEGIN
    DECLARE v_password VARCHAR(255);

    SET v_password = TRIM(p_password);

    IF CHAR_LENGTH(v_password) < 12
      OR v_password NOT REGEXP '[A-Z]'
      OR v_password NOT REGEXP '[a-z]'
      OR v_password NOT REGEXP '[0-9]'
      OR v_password REGEXP ' ' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Mot de passe invalide : >= 12 caractéres, 1 majuscule, 1 minuscule, 1 chiffre, pas d'espace";
    END IF;

    SET p_password = SHA1(v_password);
END$$
DELIMITER ;

-- orders
DROP PROCEDURE IF EXISTS `proc_order_hydrate_user`;
DELIMITER $$
CREATE PROCEDURE `proc_order_hydrate_user`(
    IN p_user_id BIGINT,
    OUT p_firstname VARCHAR(100),
    OUT p_lastname VARCHAR(100),
    OUT p_email VARCHAR(255),
    OUT p_phone VARCHAR(50),
    OUT p_billing_address TEXT,
    OUT p_delivery_address TEXT
)
BEGIN
    DECLARE v_exist INT;

    IF p_user_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "L'utilisateur est obligatoire";
    END IF;

    SELECT COUNT(*) INTO v_exist FROM `users` WHERE `id` = p_user_id;

    IF v_exist = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "L'utilisateur n'existe pas";
    END IF;

    SELECT 
      `firstname`, `lastname`, `email`, `phone`, `billing_address`, `delivery_address`
    INTO 
      p_firstname, p_lastname, p_email, p_phone, p_billing_address, p_delivery_address
    FROM `users`
    WHERE `id` = p_user_id;
END$$
DELIMITER ;

-- order_lines
DROP PROCEDURE IF EXISTS `proc_order_line_hydrate_article`;
DELIMITER $$
CREATE PROCEDURE `proc_order_line_hydrate_article`(
    IN p_article_id BIGINT,
    OUT p_sku VARCHAR(100),
    OUT p_title VARCHAR(255),
    OUT p_description LONGTEXT,
    OUT p_photo_url VARCHAR(255),
    OUT p_unit_price DECIMAL(12,3),
    OUT p_vat_rate DECIMAL(5,2)
)
BEGIN
    DECLARE v_exist INT;

    IF p_article_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "L'article est obligatoire";
    END IF;

    SELECT COUNT(*) INTO v_exist FROM `articles` WHERE `id` = p_article_id;

    IF v_exist = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Article introuvable";
    END IF;

    SELECT 
      `sku`, `title`, `description`, `photo_url`, `unit_price`, `vat_rate`
    INTO 
      p_sku, p_title, p_description, p_photo_url, p_unit_price, p_vat_rate
    FROM `articles`
    WHERE `id` = p_article_id;
END$$
DELIMITER ;

-- stock check for order lines
DROP PROCEDURE IF EXISTS `proc_check_stock`;
DELIMITER $$
CREATE PROCEDURE `proc_check_stock`(
    IN p_article_id BIGINT,
    IN p_required_qty INT
)
BEGIN
    DECLARE v_stock INT;

    IF p_article_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "L'article est obligatoire";
    END IF;

    IF p_required_qty IS NULL OR p_required_qty < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Quantité invalide : doit être >= 1";
    END IF;

    SELECT `stock_quantity` INTO v_stock FROM `articles` WHERE `id` = p_article_id;

    IF v_stock IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Article introuvable pour vérification du stock";
    END IF;

    IF v_stock < p_required_qty THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Stock insuffisant pour cet article";
    END IF;
END$$
DELIMITER ;

-- order line totals
DROP PROCEDURE IF EXISTS `proc_order_line_compute_totals`;
DELIMITER $$
CREATE PROCEDURE `proc_order_line_compute_totals`(
    IN p_unit_price DECIMAL(12,3),
    IN p_vat_rate DECIMAL(5,2),
    IN p_qty INT,
    OUT p_line_net DECIMAL(14,3),
    OUT p_line_vat DECIMAL(14,3),
    OUT p_line_incl_vat DECIMAL(14,3)
)
BEGIN
    SET p_line_net = p_unit_price * p_qty;
    SET p_line_vat = p_line_net * (p_vat_rate / 100);
    SET p_line_incl_vat = p_line_net + p_line_vat;
END$$
DELIMITER ;

-- order totals recompute
DROP PROCEDURE IF EXISTS `proc_order_recompute_totals`;
DELIMITER $$
CREATE PROCEDURE `proc_order_recompute_totals`(
    IN p_order_id BIGINT
)
BEGIN
    DECLARE v_total_net DECIMAL(14,3);
    DECLARE v_total_vat DECIMAL(14,3);
    DECLARE v_total_incl_vat DECIMAL(14,3);

    IF p_order_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Commande manquante pour recalcul des totaux";
    END IF;

    SELECT 
        COALESCE(SUM(line_net), 0),
        COALESCE(SUM(line_vat), 0),
        COALESCE(SUM(line_incl_vat), 0)
    INTO
        v_total_net, v_total_vat, v_total_incl_vat
    FROM
        `order_lines`
    WHERE
        `order_id` = p_order_id;

    UPDATE `orders`
    SET
        `total_net` = v_total_net,
        `total_vat` = v_total_vat,
        `total_incl_vat` = v_total_incl_vat
    WHERE
        `id` = p_order_id;
END$$
DELIMITER ;

-- order status history
DROP PROCEDURE IF EXISTS `proc_log_order_status`;
DELIMITER $$
CREATE PROCEDURE `proc_log_order_status`(
    IN p_order_id BIGINT,
    IN p_old_status ENUM('draft','confirmed','paid','cancelled'),
    IN p_new_status ENUM('draft','confirmed','paid','cancelled')
)
BEGIN
    IF p_order_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Commande manquante pour historisation";
    END IF;

    IF p_old_status = p_new_status THEN
      RETURN;
    END IF;

    INSERT INTO `order_history` (`order_id`, `previous_status`, `new_status`, `changed_at`)
    VALUES (p_order_id, p_old_status, p_new_status, NOW());
END$$
DELIMITER ;

-- order number generation (mensuel)
DROP PROCEDURE IF EXISTS `proc_generate_order_number`;
DELIMITER $$
CREATE PROCEDURE `proc_generate_order_number`(
    IN p_order_id BIGINT,
    OUT p_order_number VARCHAR(50)
)
BEGIN
    IF p_order_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Impossible de générer le numéro de commande : id manquant";
    END IF;

    SET p_order_number = CONCAT(DATE_FORMAT(NOW(), '%Y%m'), '-', LPAD(p_order_id, 4, '0'));
END$$
DELIMITER ;

-- =======================
-- 5) FONCTIONS
-- =======================

DROP FUNCTION IF EXISTS `fn_order_status_label`;
DELIMITER $$
CREATE FUNCTION `fn_order_status_label`(
    p_status ENUM('draft','confirmed','paid','cancelled')
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CASE p_status
        WHEN 'draft' THEN 'Brouillon'
        WHEN 'confirmed' THEN 'Confirmée'
        WHEN 'paid' THEN 'Payée'
        WHEN 'cancelled' THEN 'Annulée'
        ELSE 'Inconnu'
    END;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_article_stock_level`;
DELIMITER $$
CREATE FUNCTION `fn_article_stock_level`(
    p_stock_quantity INT
)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    IF p_stock_quantity IS NULL OR p_stock_quantity <= 0 THEN
        RETURN 'Stock épuisé';
    ELSEIF p_stock_quantity <= 10 THEN
        RETURN CONCAT('Plus que ', p_stock_quantity, ' produits disponibles');
    ELSE
        RETURN 'Disponible';
    END IF;
END$$
DELIMITER ;

-- =======================
-- 6) VUES
-- =======================

DROP VIEW IF EXISTS `v_sales_daily`;
DELIMITER $$
CREATE VIEW `v_sales_daily` AS
SELECT
    DATE(t.`status_changed_at`) AS `sales_day`,
    COUNT(*) AS `orders_count`,
    SUM(o.`total_net`) AS `total_net`,
    SUM(o.`total_vat`) AS `total_vat`,
    SUM(o.`total_incl_vat`) AS `total_incl_vat`
FROM `orders` o
JOIN (
    SELECT `order_id`, MAX(`changed_at`) AS `status_changed_at`
    FROM `order_history`
    WHERE `new_status` IN ('confirmed', 'paid')
    GROUP BY `order_id`
) t ON t.`order_id` = o.`id`
WHERE o.`status` IN ('confirmed', 'paid')
GROUP BY DATE(t.`status_changed_at`)
ORDER BY `sales_day` ASC;
$$
DELIMITER ;

DROP VIEW IF EXISTS `v_sales_monthly`;
DELIMITER $$
CREATE VIEW `v_sales_monthly` AS
SELECT
    DATE_FORMAT(t.`status_changed_at`, '%Y-%m-01') AS `sales_month`,
    COUNT(*) AS `orders_count`,
    SUM(o.`total_net`) AS `total_net`,
    SUM(o.`total_vat`) AS `total_vat`,
    SUM(o.`total_incl_vat`) AS `total_incl_vat`
FROM `orders` o
JOIN (
    SELECT `order_id`, MAX(`changed_at`) AS `status_changed_at`
    FROM `order_history`
    WHERE `new_status` IN ('confirmed', 'paid')
    GROUP BY `order_id`
) t ON t.`order_id` = o.`id`
WHERE o.`status` IN ('confirmed', 'paid')
GROUP BY DATE_FORMAT(t.`status_changed_at`, '%Y-%m-01')
ORDER BY `sales_month` ASC;
$$
DELIMITER ;

DROP VIEW IF EXISTS `v_top_selling_articles`;
DELIMITER $$
CREATE VIEW `v_top_selling_articles` AS
SELECT
    ol.`article_id`,
    ol.`article_sku`,
    ol.`article_title`,
    SUM(ol.`quantity`) AS `total_qty_sold`,
    SUM(ol.`line_net`) AS `total_net`,
    SUM(ol.`line_vat`) AS `total_vat`,
    SUM(ol.`line_incl_vat`) AS `total_incl_vat`
FROM `order_lines` ol
JOIN `orders` o ON o.`id` = ol.`order_id`
WHERE o.`status` IN ('confirmed', 'paid')
GROUP BY ol.`article_id`, ol.`article_sku`, ol.`article_title`
ORDER BY `total_qty_sold` DESC, `total_incl_vat` DESC;
$$
DELIMITER ;

DROP VIEW IF EXISTS `v_active_customers`;
DELIMITER $$
CREATE VIEW `v_active_customers` AS
SELECT
    o.`user_id`,
    o.`user_email`,
    o.`user_firstname`,
    o.`user_lastname`,
    COUNT(*) AS `orders_count`,
    SUM(o.`total_net`) AS `total_net`,
    SUM(o.`total_vat`) AS `total_vat`,
    SUM(o.`total_incl_vat`) AS `total_incl_vat`
FROM `orders` o
WHERE o.`status` IN ('confirmed', 'paid')
GROUP BY o.`user_id`, o.`user_email`, o.`user_firstname`, o.`user_lastname`
ORDER BY `total_incl_vat` DESC, `orders_count` DESC;
$$
DELIMITER ;

DROP VIEW IF EXISTS `v_stock_alert`;
DELIMITER $$
CREATE VIEW `v_stock_alert` AS
SELECT
    a.`id` AS `article_id`,
    a.`sku`,
    a.`title`,
    a.`stock_quantity`,
    fn_article_stock_level(a.`stock_quantity`) AS `stock_level`
FROM `articles` a
WHERE a.`stock_quantity` <= 10
ORDER BY a.`stock_quantity` ASC, a.`id` ASC;
$$
DELIMITER ;

-- =======================
-- 7) TRIGGERS (ordre alphabétique des tables)
-- =======================

-- CREATE TRIGGER trigger_name
-- {BEFORE | AFTER} {INSERT | UPDATE| DELETE }
-- ON table_name FOR EACH ROW
-- trigger_body;

-- users
DROP TRIGGER IF EXISTS `trg_users_bi`;
DELIMITER $$
CREATE TRIGGER `trg_users_bi`
BEFORE INSERT ON `users`
FOR EACH ROW
BEGIN
    DECLARE v_password VARCHAR(255);

    SET v_password = NEW.`password`;
    CALL `proc_user_validate_and_hash_password`(v_password);
    SET NEW.`password` = v_password;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_users_bu`;
DELIMITER $$
CREATE TRIGGER `trg_users_bu`
BEFORE UPDATE ON `users` FOR EACH ROW
  BEGIN
    DECLARE v_password VARCHAR(255);

    SET v_password = NEW.`password`;
    CALL `proc_user_validate_and_hash_password`(v_password);

    IF v_password != OLD.`password` THEN
      SET NEW.`password` = v_password;
    ELSE
      SET NEW.`password` = OLD.`password`;
    END IF;
  END$$
DELIMITER ;

-- orders
DROP TRIGGER IF EXISTS `trg_orders_bi`;
DELIMITER $$
CREATE TRIGGER `trg_orders_bi`
BEFORE INSERT ON `orders` FOR EACH ROW
  BEGIN
    DECLARE v_next_id BIGINT;
    DECLARE v_order_number VARCHAR(50);

    SET NEW.`status` = 'draft';

    CALL `proc_order_hydrate_user`(
      NEW.`user_id`,
      NEW.`user_firstname`,
      NEW.`user_lastname`,
      NEW.`user_email`,
      NEW.`user_phone`,
      NEW.`user_billing_address`,
      NEW.`user_delivery_address`
    );

    SELECT `AUTO_INCREMENT`
    INTO v_next_id
    FROM `information_schema`.`TABLES`
    WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'orders';

    IF v_next_id IS NULL OR v_next_id < 1 THEN
      SELECT IFNULL(MAX(`id`), 0) + 1 INTO v_next_id FROM `orders`;
    END IF;

    CALL `proc_generate_order_number`(IFNULL(NEW.`id`, v_next_id), v_order_number);
    SET NEW.`order_number` = v_order_number;
  END$$
DELIMITER ;

-- orders_lines
DROP TRIGGER IF EXISTS `trg_order_lines_bi`;
DELIMITER $$
CREATE TRIGGER `trg_order_lines_bi`
BEFORE INSERT ON `order_lines` FOR EACH ROW
  BEGIN
    DECLARE v_exist INT;

    -- Check si la commande existe ?
    SELECT COUNT(*) INTO v_exist FROM `orders` WHERE `id` = NEW.`order_id`;

    IF v_exist = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "La commande associée n'existe pas";
    END IF;

    CALL `proc_order_line_hydrate_article`(
      NEW.`article_id`,
      NEW.`article_sku`,
      NEW.`article_title`,
      NEW.`article_description`,
      NEW.`article_photo_url`,
      NEW.`article_unit_price`,
      NEW.`article_vat_rate`
    );

    -- Calcul des montants (Prix * Quantité)
    -- On s'assure que la quantité est au moins de 1
    IF NEW.`quantity` IS NULL OR NEW.`quantity` < 1 THEN
      SET NEW.`quantity` = 1;
    END IF;

    CALL `proc_check_stock`(NEW.`article_id`, NEW.`quantity`);

    CALL `proc_order_line_compute_totals`(
      NEW.`article_unit_price`,
      NEW.`article_vat_rate`,
      NEW.`quantity`,
      NEW.`line_net`,
      NEW.`line_vat`,
      NEW.`line_incl_vat`
    );
  END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_order_lines_bu`;
DELIMITER $$
CREATE TRIGGER `trg_order_lines_bu`
BEFORE UPDATE ON `order_lines` FOR EACH ROW
  BEGIN
    CALL `proc_order_line_hydrate_article`(
      NEW.`article_id`,
      NEW.`article_sku`,
      NEW.`article_title`,
      NEW.`article_description`,
      NEW.`article_photo_url`,
      NEW.`article_unit_price`,
      NEW.`article_vat_rate`
    );

    IF NEW.`quantity` IS NULL OR NEW.`quantity` < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Quantité invalide : doit être >= 1";
    END IF;

    CALL `proc_check_stock`(NEW.`article_id`, NEW.`quantity`);

    CALL `proc_order_line_compute_totals`(
      NEW.`article_unit_price`,
      NEW.`article_vat_rate`,
      NEW.`quantity`,
      NEW.`line_net`,
      NEW.`line_vat`,
      NEW.`line_incl_vat`
    );
  END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_order_lines_ai`;
DELIMITER $$
CREATE TRIGGER `trg_order_lines_ai`
AFTER INSERT ON `order_lines` FOR EACH ROW
BEGIN
    CALL `proc_order_recompute_totals`(NEW.`order_id`);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_order_lines_au`;
DELIMITER $$
CREATE TRIGGER `trg_order_lines_au`
AFTER UPDATE ON `order_lines` FOR EACH ROW
BEGIN
    CALL `proc_order_recompute_totals`(NEW.`order_id`);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_order_lines_ad`;
DELIMITER $$
CREATE TRIGGER `trg_order_lines_ad`
AFTER DELETE ON `order_lines` FOR EACH ROW
BEGIN
    CALL `proc_order_recompute_totals`(OLD.`order_id`);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_orders_au`;
DELIMITER $$
CREATE TRIGGER `trg_orders_au`
AFTER UPDATE ON `orders` FOR EACH ROW
BEGIN
  -- 1. DÉCLARATION DES VARIABLES
  DECLARE v_article_id BIGINT UNSIGNED;
  DECLARE v_quantity INT;
  DECLARE v_change INT DEFAULT NULL;
  DECLARE v_reason VARCHAR(100);
  DECLARE v_done INT DEFAULT FALSE;

  -- 2. DÉCLARATION DES CURSEURS
  DECLARE cur_order_lines CURSOR FOR
    SELECT `article_id`, `quantity`
    FROM `order_lines`
    WHERE `order_id` = NEW.`id`;

  -- 3. DÉCLARATION DES HANDLERS
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

  -- 4. LOGIQUE MÉTIER (Instructions exécutables)

  -- Vérifications de sécurité
  IF OLD.`status` = 'draft' AND NEW.`status` = 'paid' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Draft vers paid non autorisé.';
  END IF;

  IF OLD.`status` = 'paid' AND NEW.`status` = 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paid vers draft non autorisé.';
  END IF;

  -- Historisation simple (toutes transitions de statut)
  CALL `proc_log_order_status`(NEW.`id`, OLD.`status`, NEW.`status`);

  -- Calcul du sens du mouvement de stock
  IF NEW.`status` = 'paid' AND OLD.`status` <> 'paid' THEN
    SET v_change = -1;
    SET v_reason = CONCAT('order ', NEW.`id`, ' paid');
  ELSEIF NEW.`status` = 'cancelled' AND OLD.`status` <> 'cancelled' THEN
    SET v_change = 1;
    SET v_reason = CONCAT('order ', NEW.`id`, ' cancelled');
  END IF;

  -- On n'exécute la boucle que si un mouvement de stock est nécessaire (v_change n'est pas NULL)
  IF v_change IS NOT NULL THEN
    OPEN cur_order_lines;
    read_loop: LOOP
      FETCH cur_order_lines INTO v_article_id, v_quantity;
      
      IF v_done THEN
        LEAVE read_loop;
      END IF;

      -- Vérification stock négatif avant insertion du mouvement
      IF (SELECT IFNULL(`stock_quantity`, 0) FROM `articles` WHERE `id` = v_article_id) + (v_change * v_quantity) < 0 THEN
         CLOSE cur_order_lines; 
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuffisant pour cet article.';
      END IF;

      -- Historique mouvement (les triggers stock_movements_* appliqueront le stock)
      INSERT INTO `stock_movements` (`article_id`, `change_quantity`, `reason`)
      VALUES (v_article_id, v_change * v_quantity, v_reason);
      
    END LOOP;
    
    CLOSE cur_order_lines;
    
  END IF;

END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_movements_bi`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movements_bi`
BEFORE INSERT ON `stock_movements` FOR EACH ROW
BEGIN
    DECLARE v_current_qty INT;
    SELECT `stock_quantity` INTO v_current_qty FROM `articles` WHERE `id` = NEW.`article_id`;
    SET NEW.`before_qty` = v_current_qty;
    SET NEW.`after_qty` = v_current_qty + NEW.`change_quantity`;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_movements_ai`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movements_ai`
AFTER INSERT ON `stock_movements` FOR EACH ROW
BEGIN
    UPDATE `articles`
    SET `stock_quantity` = NEW.`after_qty`
    WHERE `id` = NEW.`article_id`;
END$$
DELIMITER ;

-- =======================
-- 8) INSERTS (ordre alphabétique des tables)
-- =======================

-- articles
INSERT INTO `articles` (`id`, `sku`, `title`, `description`, `photo_url`, `unit_price`, `vat_rate`) VALUES
  (1,'SKU-0001','Smartphone Alpha X','Smartphone 6.5"','http://ex.com/alpha.jpg',399.00,20.00),
  (2,'SKU-0002','Laptop ZenBook','14-inch ultralight','http://ex.com/zen.jpg',1099.00,20.00),
  (3,'SKU-0003','USB-C Charger 65W','Fast charger','http://ex.com/charger.jpg',29.90,20.00),
  (4,'SKU-0004','Cooking Pot 24cm','Stainless steel','http://ex.com/pot.jpg',49.50,5.50),
  (5,'SKU-0005','Novel: The Traveler','Fiction book','http://ex.com/novel.jpg',14.90,5.50);

-- categories
INSERT INTO `categories` (`id`, `name`, `description`, `border_left`, `border_right`) VALUES
  (1,'Root','Root category',1,20),
  (2,'Electronics','Electronic devices',2,9),
  (3,'Phones','Smartphones',3,4),
  (4,'Laptops','Notebooks',5,6),
  (5,'Accessories','Cables and chargers',7,8),
  (6,'Home','Home equipment',10,15),
  (7,'Kitchen','Cooking utensils',11,12),
  (8,'Appliances','Electrical appliances',13,14),
  (9,'Books','Bookstore',16,19),
  (10,'Fiction','Novels',17,18);

-- article_categories
INSERT INTO `article_categories` VALUES
  (1,2),(1,3),
  (2,2),(2,4),
  (3,2),(3,5),
  (4,6),(4,7),
  (5,9),(5,10);

-- users
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `password`, `phone`, `billing_address`, `delivery_address`) VALUES
  (1,'Alice','Smith','alice@example.com','P@$$w0rd#IUT','0600000000','Paris','Paris'),
  (2,'Bob','Johnson','bob@example.com','P@$$w0rd#IUT','0611111111','Lyon','Lyon');

SET FOREIGN_KEY_CHECKS = 1;
