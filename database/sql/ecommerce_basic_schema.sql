/*
  E-Commerce Basic Schema - SQL starter tasks

  Dialect notes:
  - LIMIT/OFFSET, CHECK constraints, GENERATED IDENTITY, and date functions are used.
  - For MySQL, replace GENERATED ALWAYS AS IDENTITY with AUTO_INCREMENT.
*/

-- ============================================================
-- 1. Clean setup examples: DROP and TRUNCATE
-- ============================================================

-- Drop child tables before parent tables when foreign keys exist.
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- TRUNCATE removes all rows but keeps the table structure.
-- Run this after CREATE TABLE statements if you want to reset sample data.
-- TRUNCATE TABLE orders, products, categories, users RESTART IDENTITY;

-- ============================================================
-- 2. DDL: CREATE tables with data types and constraints
-- ============================================================

CREATE TABLE users (
  user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(20),
  password_hash VARCHAR(255) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'BLOCKED', 'DELETED')),
  CONSTRAINT chk_users_email_format CHECK (email LIKE '%@%')
);

CREATE TABLE categories (
  category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category_name VARCHAR(80) NOT NULL UNIQUE,
  description VARCHAR(255),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category_id INTEGER NOT NULL,
  sku VARCHAR(40) NOT NULL UNIQUE,
  product_name VARCHAR(120) NOT NULL,
  description VARCHAR(500),
  price DECIMAL(10, 2) NOT NULL,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  rating DECIMAL(2, 1) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
  CONSTRAINT chk_products_price CHECK (price >= 0),
  CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
  CONSTRAINT chk_products_rating CHECK (rating BETWEEN 0.0 AND 5.0)
);

CREATE TABLE orders (
  order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  order_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  shipping_city VARCHAR(80) NOT NULL,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_orders_product
    FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT chk_orders_quantity CHECK (quantity > 0),
  CONSTRAINT chk_orders_unit_price CHECK (unit_price >= 0),
  CONSTRAINT chk_orders_status CHECK (
    order_status IN ('PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED')
  )
);

-- ALTER example: add and later drop a column.
ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP;
ALTER TABLE users DROP COLUMN last_login_at;

-- ============================================================
-- 3. DML: INSERT sample data
-- ============================================================

INSERT INTO users (full_name, email, phone, password_hash, status)
VALUES
  ('Alice Sharma', 'alice@example.com', '555-0101', 'hashed_password_1', 'ACTIVE'),
  ('Bob Khan', 'bob@example.com', '555-0102', 'hashed_password_2', 'ACTIVE'),
  ('Carol Smith', 'carol@example.com', NULL, 'hashed_password_3', 'BLOCKED');

INSERT INTO categories (category_name, description)
VALUES
  ('Electronics', 'Phones, laptops, headphones, and accessories'),
  ('Clothing', 'Men and women clothing'),
  ('Books', 'Printed and digital books');

INSERT INTO products (
  category_id,
  sku,
  product_name,
  description,
  price,
  stock_quantity,
  rating
)
VALUES
  (1, 'EL-001', 'UltraBook Pro 15', 'Lightweight laptop for developers', 1299.99, 8, 4.8),
  (1, 'EL-002', 'NoiseCancel X', 'Wireless noise cancelling headphones', 249.99, 25, 4.5),
  (2, 'CL-101', 'Winter Parka', 'Warm winter jacket', 189.99, 12, 4.2),
  (3, 'BK-501', 'The Java Journey', 'Beginner-friendly Java book', 29.99, 40, 4.7);

INSERT INTO orders (
  user_id,
  product_id,
  quantity,
  unit_price,
  order_status,
  shipping_city
)
VALUES
  (1, 1, 1, 1299.99, 'PAID', 'New York'),
  (1, 4, 2, 29.99, 'DELIVERED', 'New York'),
  (2, 2, 1, 249.99, 'SHIPPED', 'Chicago'),
  (2, 3, 1, 189.99, 'PENDING', 'Boston');

-- ============================================================
-- 4. CRUD queries
-- ============================================================

-- CREATE
INSERT INTO categories (category_name, description)
VALUES ('Home', 'Home and kitchen products');

INSERT INTO products (category_id, sku, product_name, price, stock_quantity, rating)
VALUES (4, 'HM-001', 'Desk Lamp', 39.99, 30, 4.3);

-- READ
SELECT user_id, full_name, email, status
FROM users
WHERE status = 'ACTIVE'
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

SELECT product_id, sku, product_name, price, stock_quantity
FROM products
WHERE price BETWEEN 50 AND 300
ORDER BY price ASC;

-- UPDATE
UPDATE products
SET price = 229.99,
    stock_quantity = stock_quantity - 1
WHERE sku = 'EL-002';

UPDATE orders
SET order_status = 'DELIVERED'
WHERE order_id = 3
  AND order_status = 'SHIPPED';

-- DELETE
DELETE FROM orders
WHERE order_status = 'CANCELLED';

DELETE FROM products
WHERE sku = 'HM-001'
  AND stock_quantity = 0;

-- ============================================================
-- 5. SELECT practice: WHERE, operators, LIKE, IN, BETWEEN
-- ============================================================

SELECT product_name, price, rating
FROM products
WHERE price > 100
  AND rating >= 4.5
ORDER BY rating DESC, price ASC;

SELECT full_name, email, status
FROM users
WHERE status IN ('ACTIVE', 'BLOCKED')
  AND email LIKE '%example.com';

SELECT product_name, price
FROM products
WHERE NOT category_id = 2
  OR price < 100;

SELECT order_id, user_id, product_id, quantity, order_status
FROM orders
WHERE order_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_TIMESTAMP;

-- ============================================================
-- 6. Aggregate functions, GROUP BY, and HAVING
-- ============================================================

SELECT COUNT(*) AS total_users
FROM users;

SELECT
  COUNT(*) AS total_orders,
  SUM(quantity * unit_price) AS total_revenue,
  AVG(quantity * unit_price) AS average_order_value,
  MIN(quantity * unit_price) AS smallest_order,
  MAX(quantity * unit_price) AS largest_order
FROM orders
WHERE order_status IN ('PAID', 'SHIPPED', 'DELIVERED');

SELECT
  c.category_name,
  COUNT(p.product_id) AS product_count,
  AVG(p.price) AS average_price,
  SUM(p.stock_quantity) AS total_stock
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
HAVING COUNT(p.product_id) >= 1
ORDER BY average_price DESC;

SELECT
  u.full_name,
  COUNT(o.order_id) AS order_count,
  SUM(o.quantity * o.unit_price) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING SUM(o.quantity * o.unit_price) > 100
ORDER BY total_spent DESC;

-- ============================================================
-- 7. String, date, and numeric functions
-- ============================================================

-- String functions
SELECT
  product_name,
  UPPER(product_name) AS uppercase_name,
  LOWER(sku) AS lowercase_sku,
  LENGTH(product_name) AS name_length,
  CONCAT(sku, ' - ', product_name) AS product_label
FROM products;

-- Date functions
SELECT
  order_id,
  order_date,
  DATE(order_date) AS order_day,
  EXTRACT(YEAR FROM order_date) AS order_year,
  CURRENT_DATE AS report_date
FROM orders;

-- Numeric functions
SELECT
  product_name,
  price,
  ROUND(price * 0.10, 2) AS ten_percent_discount,
  ROUND(price - (price * 0.10), 2) AS discounted_price
FROM products
ORDER BY discounted_price ASC;

-- ============================================================
-- 8. Basic joined report for the e-commerce schema
-- ============================================================

SELECT
  o.order_id,
  u.full_name AS customer_name,
  p.product_name,
  c.category_name,
  o.quantity,
  o.unit_price,
  ROUND(o.quantity * o.unit_price, 2) AS line_total,
  o.order_status,
  o.shipping_city,
  o.order_date
FROM orders o
JOIN users u ON u.user_id = o.user_id
JOIN products p ON p.product_id = o.product_id
JOIN categories c ON c.category_id = p.category_id
ORDER BY o.order_date DESC;
