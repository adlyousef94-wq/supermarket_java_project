-- 1. تهيئة القاعدة وإيقاف القيود مؤقتاً لضمان المسح وإعادة البناء
SET FOREIGN_KEY_CHECKS = 0;
CREATE DATABASE IF NOT EXISTS `supermarket_db`;
USE `supermarket_db`;

-- 2. حذف الجداول القديمة لضمان نظافة الهيكل الجديد
DROP TABLE IF EXISTS `inventory_logs`;
DROP TABLE IF EXISTS `sales_items`;
DROP TABLE IF EXISTS `sales`;
DROP TABLE IF EXISTS `cashier`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `suppliers`;
DROP TABLE IF EXISTS `users`;
DROP VIEW IF EXISTS `cashier_performance_view`;

-- 3. جدول المستخدمين (تم استخدام id ليتوافق مع LoginController)
CREATE TABLE `users` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(100) NOT NULL,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL DEFAULT '123',
  `role` VARCHAR(20) DEFAULT 'Cashier',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

-- 4. جدول الموردين
CREATE TABLE `suppliers` (
  `supplier_id` INT(11) NOT NULL AUTO_INCREMENT,
  `supplier_name` VARCHAR(100) NOT NULL,
  `contact_info` VARCHAR(255),
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB;

-- 5. جدول الكاشير (يحتوي على cashier_id و user_id للربط)
CREATE TABLE `cashier` (
  `cashier_id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_id` INT(11),
  `full_name` VARCHAR(100) NOT NULL,
  `phone_number` VARCHAR(20),
  `email` VARCHAR(100),
  `salary` DECIMAL(10,2) DEFAULT 0.00,
  `shift` VARCHAR(50) DEFAULT 'Morning',
  `status` TINYINT(1) DEFAULT 1,
  `last_login` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cashier_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. جدول المنتجات
CREATE TABLE `products` (
  `product_id` INT(11) NOT NULL AUTO_INCREMENT,
  `product_name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50),
  `quantity` INT(11) DEFAULT 0,
  `buying_price` DOUBLE DEFAULT 0,
  `selling_price` DOUBLE DEFAULT 0,
  `supplier_id` INT(11),
  PRIMARY KEY (`product_id`),
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`supplier_id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 7. جدول المبيعات (تم استخدام date ليتوافق مع POSController)
CREATE TABLE `sales` (
  `sale_id` INT(11) NOT NULL AUTO_INCREMENT,
  `cashier_id` INT(11),
  `total_amount` DOUBLE NOT NULL,
  `tax` DOUBLE DEFAULT 0,
  `date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`sale_id`),
  FOREIGN KEY (`cashier_id`) REFERENCES `cashier`(`cashier_id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. جدول تفاصيل المبيعات (تم استخدام price ليتوافق مع الكود)
CREATE TABLE `sales_items` (
  `item_id` INT(11) NOT NULL AUTO_INCREMENT,
  `sale_id` INT(11),
  `product_id` INT(11),
  `quantity` INT(11) NOT NULL,
  `price` DOUBLE NOT NULL,
  `subtotal` DOUBLE NOT NULL,
  PRIMARY KEY (`item_id`),
  FOREIGN KEY (`sale_id`) REFERENCES `sales`(`sale_id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 9. جدول سجلات المخزن (بالأعمدة المطلوبة: change_type, quantity_change, change_date)
CREATE TABLE `inventory_logs` (
  `log_id` INT(11) NOT NULL AUTO_INCREMENT,
  `product_id` INT(11) NOT NULL,
  `change_type` VARCHAR(50) NOT NULL,
  `quantity_change` INT(11) NOT NULL,
  `user_id` INT(11),
  `notes` TEXT,
  `change_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. الـ View الخاص بأداء الكاشير (بالأعمدة المطلوبة: total_sales, total_revenue)
CREATE OR REPLACE VIEW cashier_performance_view AS
SELECT 
    c.cashier_id, 
    c.full_name,
    u.username,
    u.role,
    c.last_login,
    c.salary,
    c.shift,
    (SELECT COUNT(*) FROM sales s WHERE s.cashier_id = c.cashier_id) AS total_sales,
    (SELECT IFNULL(SUM(total_amount), 0) FROM sales s WHERE s.cashier_id = c.cashier_id) AS total_revenue
FROM cashier c
JOIN users u ON c.user_id = u.id;

-- 11. إدخال بيانات تجريبية جاهزة للعمل فوراً
INSERT INTO `users` (`id`, `full_name`, `username`, `password`, `role`) VALUES 
(1, 'Admin Ismail', 'admin', '123', 'Admin'),
(2, 'Mustafa Cashier', 'mustafa', '123', 'Cashier');

INSERT INTO `cashier` (`user_id`, `full_name`, `salary`, `shift`) VALUES 
(1, 'Ismail Ibrahim', 15000.00, 'Night'),
(2, 'Mustafa Ibrahim', 8000.00, 'Morning');

-- إعادة تفعيل القيود
SET FOREIGN_KEY_CHECKS = 1;
