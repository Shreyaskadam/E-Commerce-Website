/*
  E-Commerce Backend Query Optimization

  Dialect: MySQL 8.0.18+ for EXPLAIN ANALYZE

  Run this after:
    database/sql/ecommerce_complete_schema_mysql.sql

  Goal:
  - Add production-oriented indexes.
  - Rewrite slow backend queries into index-friendly forms.
  - Show EXPLAIN / EXPLAIN ANALYZE commands for measuring improvement.
  - Include production SQL examples for partitioning, security, and backup/restore.

  Important:
  - CREATE INDEX statements should be run once. If an index already exists, MySQL
    returns a duplicate-key-name error.
  - On large production tables, create indexes during low traffic windows or use
    online schema migration tooling.
*/

-- ============================================================
-- 1. Inspect current execution plans before changing indexes
-- ============================================================

-- Use EXPLAIN first, then EXPLAIN ANALYZE on a safe staging database.
EXPLAIN
SELECT
  p.product_id,
  p.product_name,
  p.slug,
  p.price,
  p.stock_quantity
FROM products p
WHERE p.product_status = 'ACTIVE'
  AND p.category_id = 4
  AND p.price BETWEEN 100.00 AND 1500.00
ORDER BY p.price ASC, p.product_id ASC
LIMIT 20;

EXPLAIN
SELECT
  o.order_id,
  o.order_number,
  o.order_status,
  o.total_amount,
  o.placed_at
FROM orders o
WHERE o.user_id = 1
ORDER BY o.placed_at DESC
LIMIT 10;

EXPLAIN
SELECT
  oi.product_id,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.line_total) AS revenue
FROM order_items oi
INNER JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status IN ('PAID', 'PROCESSING', 'SHIPPED', 'DELIVERED')
  AND o.placed_at >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY oi.product_id
ORDER BY units_sold DESC
LIMIT 10;

-- ============================================================
-- 2. Production indexing strategy
-- ============================================================

/*
  B-Tree index strategy:
  - Equality columns first.
  - Range column next.
  - ORDER BY / GROUP BY columns after that when possible.
  - Include selected columns at the end to make covering indexes for hot reads.
*/

-- Catalog browse: WHERE product_status + category_id + price range, ORDER BY price.
CREATE INDEX idx_products_catalog_browse
ON products (
  product_status,
  category_id,
  price,
  product_id,
  product_name,
  slug,
  stock_quantity
);

-- Catalog newest products: active products ordered by creation time.
CREATE INDEX idx_products_status_created
ON products (product_status, created_at, product_id);

-- Product search by SKU is already covered by uq_products_sku.
-- Add full-text search for product search boxes.
CREATE FULLTEXT INDEX ft_products_name_description
ON products (product_name, description);

-- Customer order history: WHERE user_id, ORDER BY placed_at, return summary fields.
CREATE INDEX idx_orders_user_history_covering
ON orders (
  user_id,
  placed_at,
  order_id,
  order_number,
  order_status,
  total_amount
);

-- Admin dashboard: filter by status and date range, then sort by newest orders.
CREATE INDEX idx_orders_status_date_dashboard
ON orders (
  order_status,
  placed_at,
  order_id,
  user_id,
  total_amount
);

-- Reporting joins from order_items to products and orders.
CREATE INDEX idx_order_items_product_sales
ON order_items (product_id, order_id, quantity, line_total);

CREATE INDEX idx_order_items_order_covering
ON order_items (order_id, product_id, quantity, line_total);

-- Payment reconciliation: captured or failed payments by paid date.
CREATE INDEX idx_payments_status_paid
ON payments (payment_status, paid_at, order_id, amount);

-- Product reviews: approved reviews by product, newest first, rating summary.
CREATE INDEX idx_reviews_product_approved_recent
ON reviews (product_id, review_status, created_at, rating, user_id);

-- Address lookup: user's default address for checkout.
CREATE INDEX idx_addresses_user_type_default
ON addresses (user_id, address_type, is_default, address_id);

-- Category menu: active children sorted by display order.
CREATE INDEX idx_categories_menu
ON categories (is_active, parent_category_id, display_order, category_id, category_name);

/*
  Optional cleanup after validating plans:
  Some earlier single-column indexes may become redundant once composite indexes are proven
  in staging. Drop only after checking SHOW INDEX and real query plans.

  Examples:
  -- DROP INDEX idx_products_price ON products;
  -- DROP INDEX idx_products_name ON products;
  -- DROP INDEX idx_order_items_product ON order_items;
*/

-- Refresh statistics after adding indexes.
ANALYZE TABLE
  users,
  categories,
  products,
  addresses,
  orders,
  order_items,
  payments,
  reviews;

-- ============================================================
-- 3. Slow query rewrites
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Product catalog browse
-- ------------------------------------------------------------

-- Anti-pattern:
-- - SELECT * reads unnecessary columns.
-- - Function on product_name prevents normal B-Tree use.
-- - Leading wildcard LIKE usually causes a scan.
-- - OFFSET gets slower on deep pages.
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE LOWER(product_name) LIKE '%book%'
  AND product_status = 'ACTIVE'
ORDER BY price ASC
LIMIT 20 OFFSET 1000;

-- Optimized search:
-- - Select only fields needed by the API response.
-- - Use FULLTEXT for search.
-- - Use keyset pagination instead of deep OFFSET.
-- - Uses ft_products_name_description first, then applies category/price filters.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  p.slug,
  p.price,
  p.stock_quantity
FROM products p
WHERE p.product_status = 'ACTIVE'
  AND p.category_id = 4
  AND p.price BETWEEN 100.00 AND 1500.00
  AND MATCH(p.product_name, p.description) AGAINST ('+book*' IN BOOLEAN MODE)
  AND (
    p.price > 100.00
    OR (p.price = 100.00 AND p.product_id > 0)
  )
ORDER BY p.price ASC, p.product_id ASC
LIMIT 20;

-- Optimized browse without a search term:
-- - Uses idx_products_catalog_browse as a composite B-Tree range index.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  p.slug,
  p.price,
  p.stock_quantity
FROM products p
WHERE p.product_status = 'ACTIVE'
  AND p.category_id = 4
  AND p.price BETWEEN 100.00 AND 1500.00
  AND (
    p.price > 100.00
    OR (p.price = 100.00 AND p.product_id > 0)
  )
ORDER BY p.price ASC, p.product_id ASC
LIMIT 20;

-- ------------------------------------------------------------
-- Query 2: Customer order history
-- ------------------------------------------------------------

-- Anti-pattern:
-- - Pulls full order rows.
-- - Sort can be expensive without a matching user/date index.
-- - OFFSET gets slower as page number increases.
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE user_id = 1
ORDER BY placed_at DESC
LIMIT 20 OFFSET 500;

-- Optimized:
-- - Covering index for the order-history API.
-- - Keyset pagination with the last seen placed_at/order_id from the previous page.
EXPLAIN ANALYZE
SELECT
  o.order_id,
  o.order_number,
  o.order_status,
  o.total_amount,
  o.currency_code,
  o.placed_at
FROM orders o
WHERE o.user_id = 1
  AND (
    o.placed_at < '2026-04-10 12:30:00'
    OR (o.placed_at = '2026-04-10 12:30:00' AND o.order_id < 2)
  )
ORDER BY o.placed_at DESC, o.order_id DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Query 3: Admin order dashboard
-- ------------------------------------------------------------

-- Anti-pattern:
-- - DATE(placed_at) makes the date condition non-sargable.
-- - SELECT * pulls large address snapshot fields unnecessarily.
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE DATE(placed_at) = '2026-04-10'
  AND order_status = 'PAID'
ORDER BY placed_at DESC;

-- Optimized:
-- - Uses a half-open range instead of DATE(column).
-- - Uses idx_orders_status_date_dashboard.
EXPLAIN ANALYZE
SELECT
  o.order_id,
  o.order_number,
  o.user_id,
  o.order_status,
  o.total_amount,
  o.placed_at
FROM orders o
WHERE o.order_status = 'PAID'
  AND o.placed_at >= '2026-04-10 00:00:00'
  AND o.placed_at < '2026-04-11 00:00:00'
ORDER BY o.placed_at DESC, o.order_id DESC
LIMIT 100;

-- ------------------------------------------------------------
-- Query 4: Top selling products
-- ------------------------------------------------------------

-- Anti-pattern:
-- - Scans all historical orders when the dashboard only needs recent data.
-- - Aggregates before reducing by date/status.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.line_total) AS revenue
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.product_id
INNER JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status IN ('PAID', 'PROCESSING', 'SHIPPED', 'DELIVERED')
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC
LIMIT 10;

-- Optimized:
-- - Filters orders by status/date first.
-- - Joins to order_items after the reduced order set.
-- - Uses idx_orders_status_date_dashboard and idx_order_items_order_covering.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.line_total), 2) AS revenue
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
INNER JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('PAID', 'PROCESSING', 'SHIPPED', 'DELIVERED')
  AND o.placed_at >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, revenue DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Query 5: Product review summary
-- ------------------------------------------------------------

-- Anti-pattern:
-- - Correlated subqueries run once per product row.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  (
    SELECT AVG(r.rating)
    FROM reviews r
    WHERE r.product_id = p.product_id
      AND r.review_status = 'APPROVED'
  ) AS average_rating,
  (
    SELECT COUNT(*)
    FROM reviews r
    WHERE r.product_id = p.product_id
      AND r.review_status = 'APPROVED'
  ) AS review_count
FROM products p
WHERE p.product_status = 'ACTIVE';

-- Optimized:
-- - Aggregates reviews once and joins the result.
-- - Uses idx_reviews_product_approved_recent.
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  COALESCE(rr.average_rating, 0) AS average_rating,
  COALESCE(rr.review_count, 0) AS review_count
FROM products p
LEFT JOIN (
  SELECT
    product_id,
    ROUND(AVG(rating), 2) AS average_rating,
    COUNT(*) AS review_count
  FROM reviews
  WHERE review_status = 'APPROVED'
  GROUP BY product_id
) rr ON rr.product_id = p.product_id
WHERE p.product_status = 'ACTIVE'
ORDER BY p.product_id;

-- ------------------------------------------------------------
-- Query 6: Checkout default address
-- ------------------------------------------------------------

-- Optimized direct lookup for checkout.
EXPLAIN ANALYZE
SELECT
  address_id,
  recipient_name,
  phone,
  line1,
  line2,
  city,
  state,
  postal_code,
  country_code
FROM addresses
WHERE user_id = 1
  AND address_type IN ('SHIPPING', 'BOTH')
  AND is_default = TRUE
ORDER BY address_id DESC
LIMIT 1;

-- ============================================================
-- 4. Measuring significant performance improvement
-- ============================================================

/*
  Recommended benchmark loop:

  1. Run the anti-pattern query with EXPLAIN ANALYZE.
  2. Record:
     - actual time
     - rows examined
     - whether it used index lookup, range scan, full table scan, filesort, or temp table
  3. Add the index.
  4. Run ANALYZE TABLE for touched tables.
  5. Run the optimized query with EXPLAIN ANALYZE.
  6. Compare:
     - fewer rows scanned
     - lower actual time
     - better access type in EXPLAIN, such as const/ref/range instead of ALL
     - fewer "Using temporary" / "Using filesort" cases

  Performance target examples:
  - Catalog browse should use idx_products_catalog_browse or FULLTEXT search.
  - Order history should use idx_orders_user_history_covering.
  - Admin dashboard should use idx_orders_status_date_dashboard.
  - Top-products report should filter orders first, then join order_items.
*/

-- Example session-level profiling helpers.
EXPLAIN FORMAT=TREE
SELECT
  o.order_id,
  o.order_number,
  o.order_status,
  o.total_amount,
  o.placed_at
FROM orders o
WHERE o.user_id = 1
ORDER BY o.placed_at DESC, o.order_id DESC
LIMIT 20;

SHOW INDEX FROM products;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_items;
SHOW INDEX FROM reviews;

-- ============================================================
-- 5. Partitioning strategy
-- ============================================================

/*
  MySQL note:
  InnoDB user-defined partitioned tables have foreign-key limitations depending on
  version and configuration. Do not blindly partition the core orders table if it
  participates in foreign keys.

  Safer production pattern:
  - Keep OLTP tables normalized with foreign keys.
  - Move older immutable data into archive/reporting tables partitioned by date.
  - Query current OLTP tables for app screens and archive tables for long reports.
*/

CREATE TABLE IF NOT EXISTS order_sales_archive (
  archive_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  order_status VARCHAR(30) NOT NULL,
  placed_at DATETIME NOT NULL,
  quantity INT NOT NULL,
  line_total DECIMAL(12, 2) NOT NULL,
  PRIMARY KEY (archive_id, placed_at),
  KEY idx_archive_product_date (product_id, placed_at),
  KEY idx_archive_user_date (user_id, placed_at),
  KEY idx_archive_status_date (order_status, placed_at)
)
PARTITION BY RANGE COLUMNS (placed_at) (
  PARTITION p2026_q1 VALUES LESS THAN ('2026-04-01'),
  PARTITION p2026_q2 VALUES LESS THAN ('2026-07-01'),
  PARTITION p2026_q3 VALUES LESS THAN ('2026-10-01'),
  PARTITION p2026_q4 VALUES LESS THAN ('2027-01-01'),
  PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- Example archive load. In production, run in batches.
INSERT INTO order_sales_archive (
  order_id,
  order_item_id,
  product_id,
  user_id,
  order_status,
  placed_at,
  quantity,
  line_total
)
SELECT
  o.order_id,
  oi.order_item_id,
  oi.product_id,
  o.user_id,
  o.order_status,
  o.placed_at,
  oi.quantity,
  oi.line_total
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.placed_at < CURRENT_DATE - INTERVAL 18 MONTH;

-- ============================================================
-- 6. Database security: users, roles, privileges
-- ============================================================

/*
  Run as a database admin and replace passwords before use.
  Principle: the application user should not own schema migrations.
*/

CREATE ROLE IF NOT EXISTS ecommerce_app_readwrite;
CREATE ROLE IF NOT EXISTS ecommerce_reporting_readonly;
CREATE ROLE IF NOT EXISTS ecommerce_migration_admin;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ecommerce_db.*
TO ecommerce_app_readwrite;

GRANT SELECT
ON ecommerce_db.*
TO ecommerce_reporting_readonly;

GRANT ALTER, CREATE, CREATE VIEW, DELETE, DROP, INDEX, INSERT, REFERENCES, SELECT, UPDATE
ON ecommerce_db.*
TO ecommerce_migration_admin;

CREATE USER IF NOT EXISTS 'ecommerce_app'@'%' IDENTIFIED BY 'replace_with_strong_password';
CREATE USER IF NOT EXISTS 'ecommerce_report'@'%' IDENTIFIED BY 'replace_with_strong_password';
CREATE USER IF NOT EXISTS 'ecommerce_migrator'@'%' IDENTIFIED BY 'replace_with_strong_password';

GRANT ecommerce_app_readwrite TO 'ecommerce_app'@'%';
GRANT ecommerce_reporting_readonly TO 'ecommerce_report'@'%';
GRANT ecommerce_migration_admin TO 'ecommerce_migrator'@'%';

SET DEFAULT ROLE ecommerce_app_readwrite TO 'ecommerce_app'@'%';
SET DEFAULT ROLE ecommerce_reporting_readonly TO 'ecommerce_report'@'%';
SET DEFAULT ROLE ecommerce_migration_admin TO 'ecommerce_migrator'@'%';

-- ============================================================
-- 7. Backup and restore commands
-- ============================================================

/*
  Logical backup:

  mysqldump \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --set-gtid-purged=OFF \
    ecommerce_db > ecommerce_db_backup.sql

  Restore:

  mysql ecommerce_db < ecommerce_db_backup.sql

  Production strategy:
  - Daily full logical backup for small/medium databases.
  - Binary logs enabled for point-in-time recovery.
  - Regular restore drills into a staging database.
  - For large databases, use physical backups such as MySQL Enterprise Backup,
    Percona XtraBackup, or managed database snapshots.
*/
