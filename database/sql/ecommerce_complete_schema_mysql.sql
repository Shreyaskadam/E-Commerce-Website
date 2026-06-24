/*
  Complete E-Commerce Database Design

  Dialect: MySQL 8.0+

  Core entities:
  - Users
  - Addresses
  - Categories
  - Products
  - Orders
  - Order_Items
  - Payments
  - Reviews

  Design notes:
  - Surrogate integer primary keys are used for stable joins.
  - Natural business identifiers such as email, sku, order_number, and payment reference
    are protected with UNIQUE constraints.
  - Order and order item snapshot columns intentionally denormalize checkout-time data
    so historical orders do not change when users update addresses or products later.
*/

-- CREATE DATABASE IF NOT EXISTS ecommerce_db;
-- USE ecommerce_db;

-- ============================================================
-- 1. Clean setup
-- ============================================================

DROP VIEW IF EXISTS vw_order_summary;
DROP VIEW IF EXISTS vw_product_catalog;

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- ============================================================
-- 2. Users
-- ============================================================

CREATE TABLE users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(60) NOT NULL,
  last_name VARCHAR(60) NOT NULL,
  email VARCHAR(160) NOT NULL,
  phone VARCHAR(25),
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('CUSTOMER', 'ADMIN') NOT NULL DEFAULT 'CUSTOMER',
  status ENUM('ACTIVE', 'BLOCKED', 'DELETED') NOT NULL DEFAULT 'ACTIVE',
  email_verified_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT chk_users_email_format CHECK (email LIKE '%@%')
) ENGINE=InnoDB;

-- ============================================================
-- 3. Categories
-- ============================================================

CREATE TABLE categories (
  category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_category_id BIGINT UNSIGNED NULL,
  category_name VARCHAR(100) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  description VARCHAR(500),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_categories_slug UNIQUE (slug),
  CONSTRAINT uq_categories_parent_name UNIQUE (parent_category_id, category_name),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 4. Products
-- ============================================================

CREATE TABLE products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(60) NOT NULL,
  product_name VARCHAR(160) NOT NULL,
  slug VARCHAR(180) NOT NULL,
  description TEXT,
  price DECIMAL(12, 2) NOT NULL,
  compare_at_price DECIMAL(12, 2),
  cost_price DECIMAL(12, 2),
  stock_quantity INT NOT NULL DEFAULT 0,
  low_stock_threshold INT NOT NULL DEFAULT 5,
  product_status ENUM('DRAFT', 'ACTIVE', 'ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_products_sku UNIQUE (sku),
  CONSTRAINT uq_products_slug UNIQUE (slug),
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_products_price CHECK (price >= 0),
  CONSTRAINT chk_products_compare_price CHECK (compare_at_price IS NULL OR compare_at_price >= 0),
  CONSTRAINT chk_products_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
  CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
  CONSTRAINT chk_products_low_stock CHECK (low_stock_threshold >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- 5. Addresses
-- ============================================================

CREATE TABLE addresses (
  address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  address_type ENUM('SHIPPING', 'BILLING', 'BOTH') NOT NULL DEFAULT 'BOTH',
  recipient_name VARCHAR(120) NOT NULL,
  phone VARCHAR(25),
  line1 VARCHAR(160) NOT NULL,
  line2 VARCHAR(160),
  city VARCHAR(80) NOT NULL,
  state VARCHAR(80) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  country_code CHAR(2) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_addresses_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 6. Orders
-- ============================================================

CREATE TABLE orders (
  order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  order_number VARCHAR(40) NOT NULL,
  shipping_address_id BIGINT UNSIGNED NULL,
  billing_address_id BIGINT UNSIGNED NULL,
  order_status ENUM(
    'PENDING',
    'CONFIRMED',
    'PAID',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
    'REFUNDED'
  ) NOT NULL DEFAULT 'PENDING',
  subtotal_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  shipping_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  shipping_recipient_name VARCHAR(120) NOT NULL,
  shipping_line1 VARCHAR(160) NOT NULL,
  shipping_line2 VARCHAR(160),
  shipping_city VARCHAR(80) NOT NULL,
  shipping_state VARCHAR(80) NOT NULL,
  shipping_postal_code VARCHAR(20) NOT NULL,
  shipping_country_code CHAR(2) NOT NULL,
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid_at TIMESTAMP NULL,
  shipped_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  cancelled_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_orders_order_number UNIQUE (order_number),
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_orders_shipping_address
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_orders_billing_address
    FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_orders_amounts CHECK (
    subtotal_amount >= 0
    AND discount_amount >= 0
    AND tax_amount >= 0
    AND shipping_amount >= 0
    AND total_amount >= 0
  )
) ENGINE=InnoDB;

-- ============================================================
-- 7. Order items
-- ============================================================

CREATE TABLE order_items (
  order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  sku_snapshot VARCHAR(60) NOT NULL,
  product_name_snapshot VARCHAR(160) NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(12, 2) NOT NULL,
  discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(12, 2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_order_items_order_product UNIQUE (order_id, product_id),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
  CONSTRAINT chk_order_items_amounts CHECK (
    unit_price >= 0
    AND discount_amount >= 0
    AND tax_amount >= 0
    AND line_total >= 0
  )
) ENGINE=InnoDB;

-- ============================================================
-- 8. Payments
-- ============================================================

CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  payment_reference VARCHAR(100) NOT NULL,
  payment_method ENUM('CARD', 'UPI', 'NET_BANKING', 'WALLET', 'CASH_ON_DELIVERY') NOT NULL,
  payment_status ENUM('INITIATED', 'AUTHORIZED', 'CAPTURED', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'INITIATED',
  amount DECIMAL(12, 2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  provider_name VARCHAR(80),
  provider_transaction_id VARCHAR(120),
  paid_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_payments_reference UNIQUE (payment_reference),
  CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT chk_payments_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- 9. Reviews
-- ============================================================

CREATE TABLE reviews (
  review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NULL,
  rating TINYINT UNSIGNED NOT NULL,
  title VARCHAR(120),
  comment TEXT,
  review_status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_reviews_user_product_order_item UNIQUE (user_id, product_id, order_item_id),
  CONSTRAINT fk_reviews_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_reviews_order_item
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ============================================================
-- 10. Indexes for scalable reads
-- ============================================================

CREATE INDEX idx_users_status_created ON users(status, created_at);
CREATE INDEX idx_categories_parent_active ON categories(parent_category_id, is_active);
CREATE INDEX idx_products_category_status ON products(category_id, product_status);
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_addresses_user_default ON addresses(user_id, is_default);
CREATE INDEX idx_orders_user_placed ON orders(user_id, placed_at);
CREATE INDEX idx_orders_status_placed ON orders(order_status, placed_at);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order_status ON payments(order_id, payment_status);
CREATE INDEX idx_reviews_product_status ON reviews(product_id, review_status);
CREATE INDEX idx_reviews_user_created ON reviews(user_id, created_at);

-- ============================================================
-- 11. Views for common application/reporting reads
-- ============================================================

CREATE OR REPLACE VIEW vw_product_catalog AS
SELECT
  p.product_id,
  p.sku,
  p.product_name,
  p.slug,
  p.price,
  p.stock_quantity,
  p.product_status,
  c.category_id,
  c.category_name,
  parent_c.category_name AS parent_category_name,
  ROUND(AVG(CASE WHEN r.review_status = 'APPROVED' THEN r.rating END), 2) AS average_rating,
  COUNT(CASE WHEN r.review_status = 'APPROVED' THEN r.review_id END) AS approved_review_count
FROM products p
INNER JOIN categories c ON c.category_id = p.category_id
LEFT JOIN categories parent_c ON parent_c.category_id = c.parent_category_id
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY
  p.product_id,
  p.sku,
  p.product_name,
  p.slug,
  p.price,
  p.stock_quantity,
  p.product_status,
  c.category_id,
  c.category_name,
  parent_c.category_name;

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
  o.order_id,
  o.order_number,
  o.user_id,
  CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
  u.email,
  o.order_status,
  o.subtotal_amount,
  o.discount_amount,
  o.tax_amount,
  o.shipping_amount,
  o.total_amount,
  o.currency_code,
  COUNT(oi.order_item_id) AS item_count,
  SUM(oi.quantity) AS total_quantity,
  o.placed_at,
  o.paid_at,
  o.shipped_at,
  o.delivered_at
FROM orders o
INNER JOIN users u ON u.user_id = o.user_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  o.order_id,
  o.order_number,
  o.user_id,
  u.first_name,
  u.last_name,
  u.email,
  o.order_status,
  o.subtotal_amount,
  o.discount_amount,
  o.tax_amount,
  o.shipping_amount,
  o.total_amount,
  o.currency_code,
  o.placed_at,
  o.paid_at,
  o.shipped_at,
  o.delivered_at;

-- ============================================================
-- 12. Seed data for quick verification and practice
-- ============================================================

INSERT INTO users (first_name, last_name, email, phone, password_hash, role, status, email_verified_at)
VALUES
  ('Alice', 'Sharma', 'alice@example.com', '555-0101', 'hashed_password_1', 'CUSTOMER', 'ACTIVE', CURRENT_TIMESTAMP),
  ('Bob', 'Khan', 'bob@example.com', '555-0102', 'hashed_password_2', 'CUSTOMER', 'ACTIVE', CURRENT_TIMESTAMP),
  ('Admin', 'User', 'admin@example.com', '555-0199', 'hashed_password_admin', 'ADMIN', 'ACTIVE', CURRENT_TIMESTAMP);

INSERT INTO categories (parent_category_id, category_name, slug, description, is_active, display_order)
VALUES
  (NULL, 'Electronics', 'electronics', 'Electronic devices and accessories', TRUE, 1),
  (NULL, 'Fashion', 'fashion', 'Clothing and wearable products', TRUE, 2),
  (NULL, 'Books', 'books', 'Books and learning resources', TRUE, 3),
  (1, 'Laptops', 'laptops', 'Portable computers', TRUE, 1),
  (1, 'Audio', 'audio', 'Headphones and speakers', TRUE, 2),
  (2, 'Winter Wear', 'winter-wear', 'Jackets and winter clothing', TRUE, 1),
  (3, 'Programming', 'programming', 'Programming books', TRUE, 1);

INSERT INTO products (
  category_id,
  sku,
  product_name,
  slug,
  description,
  price,
  compare_at_price,
  cost_price,
  stock_quantity,
  low_stock_threshold,
  product_status
)
VALUES
  (4, 'EL-001', 'UltraBook Pro 15', 'ultrabook-pro-15', 'Lightweight developer laptop', 1299.99, 1499.99, 950.00, 8, 3, 'ACTIVE'),
  (5, 'EL-002', 'NoiseCancel X', 'noisecancel-x', 'Wireless noise cancelling headphones', 249.99, 299.99, 140.00, 25, 5, 'ACTIVE'),
  (6, 'CL-101', 'Winter Parka', 'winter-parka', 'Warm winter jacket', 189.99, 229.99, 90.00, 12, 4, 'ACTIVE'),
  (7, 'BK-501', 'The Java Journey', 'the-java-journey', 'Beginner-friendly Java book', 29.99, NULL, 12.00, 40, 10, 'ACTIVE');

INSERT INTO addresses (
  user_id,
  address_type,
  recipient_name,
  phone,
  line1,
  city,
  state,
  postal_code,
  country_code,
  is_default
)
VALUES
  (1, 'BOTH', 'Alice Sharma', '555-0101', '100 Market Street', 'New York', 'NY', '10001', 'US', TRUE),
  (2, 'BOTH', 'Bob Khan', '555-0102', '200 Lake Avenue', 'Chicago', 'IL', '60601', 'US', TRUE);

INSERT INTO orders (
  user_id,
  order_number,
  shipping_address_id,
  billing_address_id,
  order_status,
  subtotal_amount,
  discount_amount,
  tax_amount,
  shipping_amount,
  total_amount,
  currency_code,
  shipping_recipient_name,
  shipping_line1,
  shipping_city,
  shipping_state,
  shipping_postal_code,
  shipping_country_code,
  paid_at,
  shipped_at,
  delivered_at
)
VALUES
  (1, 'ORD-2026-0001', 1, 1, 'DELIVERED', 1329.98, 100.00, 98.40, 0.00, 1328.38, 'USD',
   'Alice Sharma', '100 Market Street', 'New York', 'NY', '10001', 'US',
   '2026-04-01 10:15:00', '2026-04-02 09:30:00', '2026-04-05 15:45:00'),
  (2, 'ORD-2026-0002', 2, 2, 'PAID', 439.98, 15.00, 34.00, 9.99, 468.97, 'USD',
   'Bob Khan', '200 Lake Avenue', 'Chicago', 'IL', '60601', 'US',
   '2026-04-10 12:30:00', NULL, NULL);

INSERT INTO order_items (
  order_id,
  product_id,
  sku_snapshot,
  product_name_snapshot,
  quantity,
  unit_price,
  discount_amount,
  tax_amount,
  line_total
)
VALUES
  (1, 1, 'EL-001', 'UltraBook Pro 15', 1, 1299.99, 100.00, 96.00, 1295.99),
  (1, 4, 'BK-501', 'The Java Journey', 1, 29.99, 0.00, 2.40, 32.39),
  (2, 2, 'EL-002', 'NoiseCancel X', 1, 249.99, 15.00, 18.80, 253.79),
  (2, 3, 'CL-101', 'Winter Parka', 1, 189.99, 0.00, 15.20, 205.19);

INSERT INTO payments (
  order_id,
  payment_reference,
  payment_method,
  payment_status,
  amount,
  currency_code,
  provider_name,
  provider_transaction_id,
  paid_at
)
VALUES
  (1, 'PAY-2026-0001', 'CARD', 'CAPTURED', 1328.38, 'USD', 'Stripe', 'txn_10001', '2026-04-01 10:15:00'),
  (2, 'PAY-2026-0002', 'CARD', 'CAPTURED', 468.97, 'USD', 'Stripe', 'txn_10002', '2026-04-10 12:30:00');

INSERT INTO reviews (user_id, product_id, order_item_id, rating, title, comment, review_status)
VALUES
  (1, 1, 1, 5, 'Excellent laptop', 'Fast, lightweight, and perfect for development.', 'APPROVED'),
  (1, 4, 2, 5, 'Helpful Java book', 'Clear explanations and useful examples.', 'APPROVED'),
  (2, 2, 3, 4, 'Good headphones', 'Strong noise cancellation and comfortable fit.', 'APPROVED');

-- ============================================================
-- 13. Smoke-test queries
-- ============================================================

SELECT * FROM vw_product_catalog ORDER BY category_name, product_name;

SELECT * FROM vw_order_summary ORDER BY placed_at DESC;

SELECT
  c.category_name,
  COUNT(DISTINCT p.product_id) AS product_count,
  COALESCE(SUM(oi.quantity), 0) AS units_sold,
  COALESCE(ROUND(SUM(oi.line_total), 2), 0.00) AS revenue
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC;
