/*
  E-Commerce Sales Analysis - Intermediate SQL tasks

  Dialect: MySQL 8.0+

  Topics covered:
  - INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL OUTER JOIN pattern, Self Join
  - Nested and correlated subqueries
  - UNION, INTERSECT, EXCEPT
  - CASE WHEN, COALESCE, NULLIF
  - CREATE VIEW
  - CREATE INDEX
  - DATE, TIMESTAMP, DATE_ADD, DATE_SUB, TIMESTAMPDIFF
  - String functions for data cleaning
  - Sales analysis: top selling products, category-wise revenue, customer lifetime value
*/

-- ============================================================
-- 1. Clean setup
-- ============================================================

DROP VIEW IF EXISTS vw_customer_lifetime_value;
DROP VIEW IF EXISTS vw_category_revenue;
DROP VIEW IF EXISTS vw_top_selling_products;
DROP VIEW IF EXISTS vw_order_sales_details;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- ============================================================
-- 2. Schema for sales analysis
-- ============================================================

CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  referred_by_user_id INT NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(25),
  status ENUM('ACTIVE', 'BLOCKED', 'DELETED') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_referrer
    FOREIGN KEY (referred_by_user_id) REFERENCES users(user_id)
);

CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  parent_category_id INT NULL,
  category_name VARCHAR(80) NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
);

CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  category_id INT NOT NULL,
  sku VARCHAR(40) NOT NULL UNIQUE,
  product_name VARCHAR(120) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  rating DECIMAL(2, 1) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
  CONSTRAINT chk_products_price CHECK (price >= 0),
  CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
  CONSTRAINT chk_products_rating CHECK (rating BETWEEN 0.0 AND 5.0)
);

CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  order_status ENUM('PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED')
    NOT NULL DEFAULT 'PENDING',
  order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  shipped_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  shipping_city VARCHAR(80),
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_orders_product
    FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT chk_orders_quantity CHECK (quantity > 0),
  CONSTRAINT chk_orders_unit_price CHECK (unit_price >= 0),
  CONSTRAINT chk_orders_discount CHECK (discount_amount >= 0)
);

-- ============================================================
-- 3. Indexes for common sales analysis filters and joins
-- ============================================================

CREATE INDEX idx_users_referred_by ON users(referred_by_user_id);
CREATE INDEX idx_categories_parent ON categories(parent_category_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_product ON orders(product_id);
CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);

-- ============================================================
-- 4. Sample data
-- ============================================================

INSERT INTO users (referred_by_user_id, full_name, email, phone, status, created_at)
VALUES
  (NULL, ' Alice Sharma ', 'ALICE@EXAMPLE.COM ', '555-0101', 'ACTIVE', '2026-01-05 09:10:00'),
  (1, 'Bob Khan', 'bob@example.com', '555-0102', 'ACTIVE', '2026-01-12 10:20:00'),
  (1, 'Carol Smith', 'carol@example.com', NULL, 'ACTIVE', '2026-02-01 11:30:00'),
  (2, 'Daniel Lee', 'daniel@example.com', '555-0104', 'BLOCKED', '2026-02-15 12:40:00'),
  (NULL, 'Eva Patel', 'eva@example.com', '555-0105', 'ACTIVE', '2026-03-01 13:50:00');

INSERT INTO categories (parent_category_id, category_name, is_active)
VALUES
  (NULL, 'Electronics', TRUE),
  (NULL, 'Fashion', TRUE),
  (NULL, 'Books', TRUE),
  (1, 'Laptops', TRUE),
  (1, 'Audio', TRUE),
  (2, 'Winter Wear', TRUE),
  (3, 'Programming', TRUE),
  (NULL, 'Home', FALSE);

INSERT INTO products (category_id, sku, product_name, price, stock_quantity, rating, created_at)
VALUES
  (4, 'EL-001', ' UltraBook Pro 15 ', 1299.99, 8, 4.8, '2026-01-03 08:00:00'),
  (5, 'EL-002', 'NoiseCancel X', 249.99, 25, 4.5, '2026-01-08 08:00:00'),
  (6, 'CL-101', 'Winter Parka', 189.99, 12, 4.2, '2026-01-20 08:00:00'),
  (7, 'BK-501', 'The Java Journey', 29.99, 40, 4.7, '2026-02-05 08:00:00'),
  (5, 'EL-003', 'Bluetooth Speaker Mini', 59.99, 0, 4.1, '2026-03-01 08:00:00'),
  (8, 'HM-001', 'Desk Lamp', 39.99, 30, 4.0, '2026-03-10 08:00:00');

INSERT INTO orders (
  user_id,
  product_id,
  quantity,
  unit_price,
  discount_amount,
  order_status,
  order_date,
  shipped_at,
  delivered_at,
  shipping_city
)
VALUES
  (1, 1, 1, 1299.99, 100.00, 'DELIVERED', '2026-03-01 09:00:00', '2026-03-02 10:00:00', '2026-03-05 15:00:00', 'New York'),
  (1, 4, 2, 29.99, 0.00, 'DELIVERED', '2026-03-04 11:00:00', '2026-03-05 09:00:00', '2026-03-07 18:00:00', 'New York'),
  (2, 2, 1, 249.99, 20.00, 'SHIPPED', '2026-03-10 14:00:00', '2026-03-11 08:00:00', NULL, 'Chicago'),
  (2, 3, 2, 189.99, 15.00, 'PAID', '2026-03-12 16:00:00', NULL, NULL, 'Boston'),
  (3, 4, 5, 29.99, 10.00, 'DELIVERED', '2026-04-01 10:00:00', '2026-04-02 10:00:00', '2026-04-04 12:30:00', 'Seattle'),
  (3, 2, 2, 249.99, 0.00, 'DELIVERED', '2026-04-03 13:00:00', '2026-04-04 09:00:00', '2026-04-06 17:00:00', 'Seattle'),
  (4, 1, 1, 1299.99, 0.00, 'CANCELLED', '2026-04-06 09:00:00', NULL, NULL, 'Dallas'),
  (5, 5, 3, 59.99, 5.00, 'REFUNDED', '2026-04-08 15:00:00', '2026-04-09 09:00:00', '2026-04-12 12:00:00', 'Miami'),
  (5, 3, 1, 189.99, 0.00, 'DELIVERED', '2026-04-12 12:00:00', '2026-04-13 10:00:00', '2026-04-16 16:00:00', 'Miami'),
  (2, 4, 1, 29.99, 0.00, 'PENDING', '2026-04-15 10:30:00', NULL, NULL, 'Chicago');

-- ============================================================
-- 5. Views for reusable sales analysis
-- ============================================================

CREATE VIEW vw_order_sales_details AS
SELECT
  o.order_id,
  o.user_id,
  u.full_name,
  u.email,
  o.product_id,
  p.sku,
  p.product_name,
  p.category_id,
  c.category_name,
  pc.category_name AS parent_category_name,
  o.quantity,
  o.unit_price,
  o.discount_amount,
  (o.quantity * o.unit_price) AS gross_amount,
  ((o.quantity * o.unit_price) - o.discount_amount) AS net_amount,
  o.order_status,
  o.order_date,
  o.shipped_at,
  o.delivered_at,
  o.shipping_city
FROM orders o
INNER JOIN users u ON u.user_id = o.user_id
INNER JOIN products p ON p.product_id = o.product_id
INNER JOIN categories c ON c.category_id = p.category_id
LEFT JOIN categories pc ON pc.category_id = c.parent_category_id;

CREATE VIEW vw_top_selling_products AS
SELECT
  product_id,
  sku,
  TRIM(product_name) AS product_name,
  COUNT(order_id) AS paid_order_count,
  SUM(quantity) AS units_sold,
  ROUND(SUM(net_amount), 2) AS total_revenue
FROM vw_order_sales_details
WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY product_id, sku, TRIM(product_name);

CREATE VIEW vw_category_revenue AS
SELECT
  COALESCE(parent_category_name, category_name) AS reporting_category,
  COUNT(order_id) AS paid_order_count,
  SUM(quantity) AS units_sold,
  ROUND(SUM(gross_amount), 2) AS gross_revenue,
  ROUND(SUM(discount_amount), 2) AS total_discounts,
  ROUND(SUM(net_amount), 2) AS net_revenue
FROM vw_order_sales_details
WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY COALESCE(parent_category_name, category_name);

CREATE VIEW vw_customer_lifetime_value AS
SELECT
  user_id,
  TRIM(full_name) AS customer_name,
  LOWER(TRIM(email)) AS cleaned_email,
  COUNT(order_id) AS paid_order_count,
  SUM(quantity) AS total_units_bought,
  ROUND(SUM(net_amount), 2) AS customer_lifetime_value,
  MIN(order_date) AS first_order_at,
  MAX(order_date) AS latest_order_at
FROM vw_order_sales_details
WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY user_id, TRIM(full_name), LOWER(TRIM(email));

-- ============================================================
-- 6. E-Commerce sales analysis tasks
-- ============================================================

-- a. Complex query using multiple joins and aggregations
SELECT
  u.user_id,
  TRIM(u.full_name) AS customer_name,
  COALESCE(parent_c.category_name, c.category_name) AS reporting_category,
  COUNT(o.order_id) AS order_count,
  SUM(o.quantity) AS units_bought,
  ROUND(SUM((o.quantity * o.unit_price) - o.discount_amount), 2) AS net_revenue,
  ROUND(AVG((o.quantity * o.unit_price) - o.discount_amount), 2) AS avg_order_line_value
FROM orders o
INNER JOIN users u ON u.user_id = o.user_id
INNER JOIN products p ON p.product_id = o.product_id
INNER JOIN categories c ON c.category_id = p.category_id
LEFT JOIN categories parent_c ON parent_c.category_id = c.parent_category_id
WHERE o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY u.user_id, TRIM(u.full_name), COALESCE(parent_c.category_name, c.category_name)
HAVING net_revenue > 100
ORDER BY net_revenue DESC;

-- b1. Top selling products by units sold and revenue
SELECT
  product_id,
  sku,
  product_name,
  paid_order_count,
  units_sold,
  total_revenue
FROM vw_top_selling_products
ORDER BY units_sold DESC, total_revenue DESC
LIMIT 5;

-- b2. Category-wise revenue
SELECT
  reporting_category,
  paid_order_count,
  units_sold,
  gross_revenue,
  total_discounts,
  net_revenue
FROM vw_category_revenue
ORDER BY net_revenue DESC;

-- b3. Customer lifetime value
SELECT
  user_id,
  customer_name,
  cleaned_email,
  paid_order_count,
  total_units_bought,
  customer_lifetime_value,
  first_order_at,
  latest_order_at,
  TIMESTAMPDIFF(DAY, first_order_at, latest_order_at) AS customer_order_span_days
FROM vw_customer_lifetime_value
ORDER BY customer_lifetime_value DESC;

-- ============================================================
-- 7. Join examples
-- ============================================================

-- INNER JOIN: only products that have matching paid/shipped/delivered orders.
SELECT
  p.product_name,
  SUM(o.quantity) AS units_sold
FROM products p
INNER JOIN orders o ON o.product_id = p.product_id
WHERE o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY p.product_id, p.product_name;

-- LEFT JOIN: all products, including products with no successful sales.
SELECT
  p.product_name,
  COALESCE(SUM(CASE
    WHEN o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED') THEN o.quantity
    ELSE 0
  END), 0) AS successful_units_sold
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- RIGHT JOIN: all users, including users without orders.
SELECT
  u.user_id,
  u.full_name,
  COUNT(o.order_id) AS total_orders
FROM orders o
RIGHT JOIN users u ON u.user_id = o.user_id
GROUP BY u.user_id, u.full_name;

-- MySQL does not have a direct FULL OUTER JOIN keyword.
-- This UNION pattern returns rows from both sides.
SELECT
  p.product_id,
  p.product_name,
  o.order_id,
  o.order_status
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id
UNION
SELECT
  p.product_id,
  p.product_name,
  o.order_id,
  o.order_status
FROM products p
RIGHT JOIN orders o ON o.product_id = p.product_id;

-- Self Join: users and the customers who referred them.
SELECT
  child.user_id,
  child.full_name AS customer_name,
  parent.full_name AS referred_by
FROM users child
LEFT JOIN users parent ON parent.user_id = child.referred_by_user_id
ORDER BY child.user_id;

-- Self Join: subcategories with their parent category.
SELECT
  child.category_name AS category_name,
  parent.category_name AS parent_category_name
FROM categories child
LEFT JOIN categories parent ON parent.category_id = child.parent_category_id
ORDER BY parent.category_name, child.category_name;

-- ============================================================
-- 8. Subqueries
-- ============================================================

-- Nested subquery: products priced above the overall average product price.
SELECT
  product_id,
  product_name,
  price
FROM products
WHERE price > (
  SELECT AVG(price)
  FROM products
);

-- Nested subquery: users who placed at least one successful order.
SELECT
  user_id,
  full_name,
  email
FROM users
WHERE user_id IN (
  SELECT DISTINCT user_id
  FROM orders
  WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
);

-- Correlated subquery: products whose successful units sold are above their category average.
SELECT
  p.product_id,
  p.product_name,
  p.category_id,
  (
    SELECT COALESCE(SUM(o.quantity), 0)
    FROM orders o
    WHERE o.product_id = p.product_id
      AND o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
  ) AS product_units_sold
FROM products p
WHERE (
  SELECT COALESCE(SUM(o.quantity), 0)
  FROM orders o
  WHERE o.product_id = p.product_id
    AND o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
) > (
  SELECT AVG(category_product_units.units_sold)
  FROM (
    SELECT
      p2.category_id,
      p2.product_id,
      COALESCE(SUM(o2.quantity), 0) AS units_sold
    FROM products p2
    LEFT JOIN orders o2
      ON o2.product_id = p2.product_id
      AND o2.order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
    GROUP BY p2.category_id, p2.product_id
  ) AS category_product_units
  WHERE category_product_units.category_id = p.category_id
);

-- Correlated subquery with EXISTS: active customers with at least one delivered order.
SELECT
  u.user_id,
  u.full_name
FROM users u
WHERE u.status = 'ACTIVE'
  AND EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.user_id = u.user_id
      AND o.order_status = 'DELIVERED'
  );

-- ============================================================
-- 9. Set operations
-- ============================================================

-- UNION: customers who are active or have successful orders.
SELECT user_id, email
FROM users
WHERE status = 'ACTIVE'
UNION
SELECT u.user_id, u.email
FROM users u
INNER JOIN orders o ON o.user_id = u.user_id
WHERE o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED');

-- INTERSECT: active users who also have successful orders.
SELECT user_id, email
FROM users
WHERE status = 'ACTIVE'
INTERSECT
SELECT u.user_id, u.email
FROM users u
INNER JOIN orders o ON o.user_id = u.user_id
WHERE o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED');

-- EXCEPT: active users who have not placed a successful order.
SELECT user_id, email
FROM users
WHERE status = 'ACTIVE'
EXCEPT
SELECT u.user_id, u.email
FROM users u
INNER JOIN orders o ON o.user_id = u.user_id
WHERE o.order_status IN ('PAID', 'SHIPPED', 'DELIVERED');

-- ============================================================
-- 10. Conditional expressions
-- ============================================================

SELECT
  order_id,
  order_status,
  quantity,
  unit_price,
  discount_amount,
  ROUND((quantity * unit_price) - discount_amount, 2) AS net_amount,
  CASE
    WHEN order_status IN ('CANCELLED', 'REFUNDED') THEN 'No revenue'
    WHEN ((quantity * unit_price) - discount_amount) >= 1000 THEN 'High value'
    WHEN ((quantity * unit_price) - discount_amount) >= 200 THEN 'Medium value'
    ELSE 'Low value'
  END AS order_value_band,
  COALESCE(shipping_city, 'Unknown') AS clean_shipping_city,
  ROUND(discount_amount / NULLIF(quantity * unit_price, 0) * 100, 2) AS discount_percent
FROM orders
ORDER BY net_amount DESC;

-- ============================================================
-- 11. Date and time handling
-- ============================================================

SELECT
  order_id,
  order_date,
  DATE(order_date) AS order_day,
  DATE_ADD(order_date, INTERVAL 7 DAY) AS follow_up_date,
  DATE_SUB(order_date, INTERVAL 30 DAY) AS thirty_days_before_order,
  TIMESTAMPDIFF(HOUR, order_date, shipped_at) AS hours_to_ship,
  TIMESTAMPDIFF(DAY, shipped_at, delivered_at) AS days_from_ship_to_delivery
FROM orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 120 DAY)
ORDER BY order_date DESC;

SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
  COUNT(order_id) AS order_count,
  ROUND(SUM((quantity * unit_price) - discount_amount), 2) AS net_revenue
FROM orders
WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- ============================================================
-- 12. String functions for data cleaning
-- ============================================================

SELECT
  user_id,
  full_name AS raw_name,
  TRIM(full_name) AS cleaned_name,
  email AS raw_email,
  LOWER(TRIM(email)) AS cleaned_email,
  REPLACE(phone, '-', '') AS digits_only_phone,
  CONCAT(TRIM(full_name), ' <', LOWER(TRIM(email)), '>') AS customer_label
FROM users;

SELECT
  product_id,
  product_name AS raw_product_name,
  TRIM(product_name) AS cleaned_product_name,
  UPPER(TRIM(sku)) AS cleaned_sku,
  LENGTH(product_name) AS raw_name_length,
  LENGTH(TRIM(product_name)) AS cleaned_name_length
FROM products;
