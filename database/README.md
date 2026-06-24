# Database Starter

This folder contains SQL practice tasks for the e-commerce project.

## Files

- `sql/ecommerce_basic_schema.sql` - creates a basic e-commerce schema with users, categories, products, and orders, then demonstrates CRUD, filtering, grouping, aggregate functions, and common string/date/numeric functions.
- `sql/ecommerce_sales_analysis_mysql.sql` - MySQL 8.0+ intermediate SQL practice for sales analysis, including joins, subqueries, set operations, views, indexes, date/time handling, string cleaning, top selling products, category revenue, and customer lifetime value.
- `sql/ecommerce_complete_schema_mysql.sql` - complete MySQL 8.0+ e-commerce database implementation with products, categories, users, addresses, orders, order items, payments, and reviews.
- `sql/ecommerce_backend_query_optimization_mysql.sql` - production SQL tuning script with composite/covering indexes, `EXPLAIN ANALYZE`, slow-query rewrites, partitioning, database roles, and backup/restore examples.
- `E_COMMERCE_DATABASE_DESIGN.md` - database design notes covering normalization, denormalization, ER modeling, keys, cascading, and scalable schema practices.
- `PERFORMANCE_TUNING_PRODUCTION_SQL.md` - performance tuning guide covering indexing strategy, execution plans, query anti-patterns, partitioning, connection pooling, security, and backups.

## Suggested Practice Flow

1. Run the `DROP TABLE` and `CREATE TABLE` statements.
2. Run the sample `INSERT` statements.
3. Practice the CRUD queries one section at a time.
4. Modify the `SELECT`, `WHERE`, `GROUP BY`, and `HAVING` examples with your own conditions.

The basic schema script is written in PostgreSQL-style SQL. For MySQL, replace `GENERATED ALWAYS AS IDENTITY` with `AUTO_INCREMENT`.

The sales analysis script is written strictly for MySQL 8.0+. `INTERSECT` and `EXCEPT` require MySQL 8.0.31 or newer.

The complete schema script is written for MySQL 8.0+ and uses InnoDB foreign keys, `BIGINT UNSIGNED` surrogate keys, `DECIMAL` money columns, indexes, views, and historical order snapshots.

The query optimization script is written for MySQL 8.0.18+ because it uses `EXPLAIN ANALYZE`. Run it after the complete schema script.
