# Performance Tuning & Production SQL

This guide supports `sql/ecommerce_backend_query_optimization_mysql.sql`.

## Optimization Targets

The e-commerce backend has several hot query paths:

- Product catalog browsing and search.
- Customer order history.
- Admin order dashboard.
- Top selling products report.
- Product review summary.
- Checkout default address lookup.
- Payment reconciliation.

## Indexing Strategy

### B-Tree Indexes

Most MySQL indexes are B-Tree indexes. They work well for:

- Equality filters: `WHERE user_id = ?`
- Range filters: `WHERE placed_at >= ? AND placed_at < ?`
- Sorting: `ORDER BY placed_at`
- Joins: `ON order_items.order_id = orders.order_id`

### Composite Indexes

Composite indexes should follow the query shape:

```sql
WHERE product_status = 'ACTIVE'
  AND category_id = ?
  AND price BETWEEN ? AND ?
ORDER BY price, product_id
```

Useful index:

```sql
(product_status, category_id, price, product_id)
```

Put equality columns first, then range/sort columns.

### Covering Indexes

A covering index includes all columns needed by a query, allowing MySQL to answer from the index without reading the table row.

Example:

```sql
(user_id, placed_at, order_id, order_number, order_status, total_amount)
```

This supports an order-history API that only returns summary fields.

## Query Optimization Rules

- Avoid `SELECT *` in backend APIs.
- Avoid `DATE(column)` in `WHERE`; use date ranges instead.
- Avoid leading wildcard searches like `LIKE '%phone%'`; use `FULLTEXT` search.
- Avoid deep `OFFSET`; use keyset pagination.
- Filter rows before joining large tables.
- Replace repeated correlated subqueries with grouped derived tables.
- Keep money columns as `DECIMAL`.
- Run `ANALYZE TABLE` after major index or data changes.

## EXPLAIN Checklist

Use:

```sql
EXPLAIN SELECT ...;
EXPLAIN ANALYZE SELECT ...;
EXPLAIN FORMAT=TREE SELECT ...;
```

Look for:

- `type`: prefer `const`, `eq_ref`, `ref`, or `range`; avoid `ALL` on large tables.
- `key`: the expected index should appear.
- `rows`: should drop significantly after indexing/rewrite.
- `Extra`: watch for `Using temporary` and `Using filesort`.
- Actual time in `EXPLAIN ANALYZE`: compare before vs after.

## Expected Improvements

Actual numbers depend on data volume, but the intended improvements are:

- Product catalog browse: table scan to indexed range or full-text lookup.
- Customer order history: full scan/sort to covering index lookup.
- Admin order dashboard: non-sargable `DATE(placed_at)` scan to indexed date range.
- Top products report: all-history aggregation to date-filtered join.
- Review summary: repeated correlated subqueries to one grouped review aggregate.

## Partitioning

Partitioning is not a magic replacement for indexes. Use it when:

- Tables are very large.
- Most queries include the partition key.
- You need fast archive/delete by date.

For this project, the safer pattern is to keep normalized OLTP tables with foreign keys and create a partitioned archive/reporting table for older immutable sales data.

## Connection Pooling

For a Java backend, use a connection pool such as HikariCP.

Suggested starting point:

```properties
maximumPoolSize=10
minimumIdle=2
connectionTimeout=30000
idleTimeout=600000
maxLifetime=1800000
leakDetectionThreshold=20000
```

Production tuning depends on:

- Database CPU and connection limit.
- Web server thread count.
- Average query latency.
- Peak traffic.

Avoid opening a new database connection per request without pooling.

## Security

Use separate database users:

- `ecommerce_app`: normal application reads/writes.
- `ecommerce_report`: read-only reporting.
- `ecommerce_migrator`: schema migrations.

Do not run the application as `root` or as the schema owner.

## Backup & Restore

Minimum strategy:

- Daily backups.
- Binary logs for point-in-time recovery.
- Restore drills into staging.
- Backup monitoring and alerts.

Backups are only trustworthy after a successful restore test.
