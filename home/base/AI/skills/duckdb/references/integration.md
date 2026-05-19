# DuckDB + Polars Integration Guide

This document provides detailed examples of integrating DuckDB and Polars for optimal data analytics workflows.

## Overview

DuckDB and Polars integrate seamlessly through Apache Arrow, allowing zero-copy data exchange between the two libraries. This combination leverages:

- **Polars**: Fast data loading, transformations, and I/O operations
- **DuckDB**: Complex SQL analytics, joins, and aggregations
- **Arrow**: Efficient memory format for zero-copy data transfer

## Installation

```bash
pip install duckdb 'polars[pyarrow]'
```

The `pyarrow` package is required for the integration to work.

## Basic Integration Patterns

### Pattern 1: Polars DataFrame to DuckDB Query

Query a Polars DataFrame using SQL:

```python
import polars as pl
import duckdb

# Load data with Polars
df = pl.read_csv('sales.csv')

# Query with DuckDB SQL
result = duckdb.sql("""
    SELECT
        product_category,
        SUM(amount) as total_sales,
        AVG(amount) as avg_sale
    FROM df
    WHERE sale_date >= '2024-01-01'
    GROUP BY product_category
    ORDER BY total_sales DESC
""")

# Convert result back to Polars
result_df = result.pl()
print(result_df)
```

### Pattern 2: Multiple DataFrames with SQL Joins

Join multiple Polars DataFrames using SQL:

```python
import polars as pl
import duckdb

# Load multiple datasets
customers = pl.read_csv('customers.csv')
orders = pl.read_csv('orders.csv')
products = pl.read_parquet('products.parquet')

# Complex multi-table join with SQL
result = duckdb.sql("""
    SELECT
        c.customer_name,
        c.segment,
        p.product_name,
        p.category,
        o.order_date,
        o.quantity,
        o.unit_price,
        o.quantity * o.unit_price as total
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.id
    INNER JOIN products p ON o.product_id = p.id
    WHERE o.order_date >= '2024-01-01'
        AND c.segment = 'Enterprise'
    ORDER BY o.order_date DESC
""").pl()

print(result)
```

### Pattern 3: Lazy Polars + DuckDB

Combine lazy evaluation with SQL:

```python
import polars as pl
import duckdb

# Lazy load and filter with Polars
df = (
    pl.scan_parquet('data/*.parquet')
    .filter(pl.col('status') == 'active')
    .select(['user_id', 'event_type', 'timestamp', 'value'])
    .collect()  # Materialize for DuckDB
)

# Aggregate with DuckDB
result = duckdb.sql("""
    SELECT
        DATE_TRUNC('day', timestamp) as date,
        event_type,
        COUNT(*) as event_count,
        SUM(value) as total_value,
        AVG(value) as avg_value
    FROM df
    GROUP BY date, event_type
    ORDER BY date DESC, event_count DESC
""").pl(lazy=True)  # Return as lazy Polars frame

# Continue with lazy Polars operations
final = (
    result
    .filter(pl.col('event_count') > 100)
    .with_columns([
        (pl.col('total_value') / pl.col('event_count')).alias('value_per_event')
    ])
    .collect()
)
```

### Pattern 4: DuckDB Result to Polars for Further Processing

Use DuckDB for complex SQL, then Polars for final transformations:

```python
import polars as pl
import duckdb

# Initial data loading
raw_data = pl.read_csv('transactions.csv')

# Complex SQL analytics with window functions
sql_result = duckdb.sql("""
    SELECT
        customer_id,
        transaction_date,
        amount,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_amount,
        AVG(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as rolling_7day_avg,
        RANK() OVER (
            PARTITION BY customer_id
            ORDER BY amount DESC
        ) as amount_rank
    FROM raw_data
    WHERE amount > 0
""").pl()

# Continue with Polars transformations
final_result = (
    sql_result
    .with_columns([
        pl.col('transaction_date').str.strptime(pl.Date, '%Y-%m-%d'),
        pl.when(pl.col('amount') > pl.col('rolling_7day_avg') * 1.5)
            .then(pl.lit('high'))
            .when(pl.col('amount') < pl.col('rolling_7day_avg') * 0.5)
            .then(pl.lit('low'))
            .otherwise(pl.lit('normal'))
            .alias('amount_category')
    ])
    .filter(pl.col('amount_rank') <= 10)  # Top 10 transactions per customer
)

final_result.write_parquet('customer_top_transactions.parquet')
```

## Advanced Integration Scenarios

### Scenario 1: ETL Pipeline with Both Tools

```python
import polars as pl
import duckdb
from datetime import datetime, timedelta

# Extract: Load from multiple sources with Polars
events = pl.read_parquet('events/*.parquet')
users = pl.read_csv('users.csv')
sessions = pl.read_json('sessions.jsonl')

# Transform: Use DuckDB for complex SQL transformations
transformed = duckdb.sql("""
    WITH user_sessions AS (
        SELECT
            s.session_id,
            s.user_id,
            s.start_time,
            s.end_time,
            u.signup_date,
            u.plan_type,
            EXTRACT(EPOCH FROM (s.end_time - s.start_time)) as session_duration_seconds
        FROM sessions s
        JOIN users u ON s.user_id = u.user_id
        WHERE s.start_time >= CURRENT_DATE - INTERVAL '30 days'
    ),
    session_events AS (
        SELECT
            e.session_id,
            e.event_type,
            e.event_value,
            us.user_id,
            us.plan_type,
            us.session_duration_seconds
        FROM events e
        JOIN user_sessions us ON e.session_id = us.session_id
    )
    SELECT
        user_id,
        plan_type,
        COUNT(DISTINCT session_id) as num_sessions,
        SUM(session_duration_seconds) as total_duration_seconds,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as num_purchases,
        SUM(CASE WHEN event_type = 'purchase' THEN event_value ELSE 0 END) as total_revenue
    FROM session_events
    GROUP BY user_id, plan_type
    HAVING num_sessions > 5
""").pl()

# Load: Further processing and export with Polars
final = (
    transformed
    .with_columns([
        (pl.col('total_duration_seconds') / 3600).alias('total_hours'),
        (pl.col('total_revenue') / pl.col('num_purchases')).alias('avg_purchase_value'),
        pl.when(pl.col('plan_type') == 'premium')
            .then(pl.col('total_revenue') * 0.7)
            .otherwise(pl.col('total_revenue'))
            .alias('net_revenue')
    ])
    .sort('total_revenue', descending=True)
)

final.write_parquet('user_metrics_summary.parquet')
```

### Scenario 2: Time Series Analysis

```python
import polars as pl
import duckdb

# Load time series data with Polars
df = pl.read_parquet('metrics/*.parquet')

# Use DuckDB for time-based analytics
time_series_analysis = duckdb.sql("""
    SELECT
        DATE_TRUNC('hour', timestamp) as hour,
        metric_name,
        COUNT(*) as data_points,
        AVG(value) as avg_value,
        MIN(value) as min_value,
        MAX(value) as max_value,
        STDDEV(value) as std_value,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value) as median_value,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) as p95_value,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY value) as p99_value,
        LAG(AVG(value)) OVER (
            PARTITION BY metric_name
            ORDER BY DATE_TRUNC('hour', timestamp)
        ) as prev_hour_avg
    FROM df
    WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    GROUP BY hour, metric_name
    ORDER BY hour DESC, metric_name
""").pl()

# Detect anomalies with Polars
anomalies = (
    time_series_analysis
    .with_columns([
        ((pl.col('avg_value') - pl.col('prev_hour_avg')) / pl.col('prev_hour_avg'))
            .alias('pct_change'),
        (pl.col('p99_value') - pl.col('p95_value')).alias('tail_spread')
    ])
    .filter(
        (pl.col('pct_change').abs() > 0.5) |  # >50% change from previous hour
        (pl.col('avg_value') > pl.col('prev_hour_avg') + 3 * pl.col('std_value'))  # >3 std devs
    )
)

print("Detected anomalies:")
print(anomalies)
```

### Scenario 3: Data Quality Checks

```python
import polars as pl
import duckdb

# Load data
data = pl.read_csv('raw_data.csv')

# Use DuckDB for comprehensive data quality analysis
quality_report = duckdb.sql("""
    SELECT
        'total_rows' as metric,
        COUNT(*)::VARCHAR as value
    FROM data

    UNION ALL

    SELECT 'unique_ids' as metric, COUNT(DISTINCT id)::VARCHAR FROM data
    UNION ALL
    SELECT 'null_email' as metric, SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END)::VARCHAR FROM data
    UNION ALL
    SELECT 'null_phone' as metric, SUM(CASE WHEN phone IS NULL THEN 1 ELSE 0 END)::VARCHAR FROM data
    UNION ALL
    SELECT 'invalid_email' as metric,
           SUM(CASE WHEN email NOT LIKE '%@%.%' THEN 1 ELSE 0 END)::VARCHAR FROM data
    UNION ALL
    SELECT 'duplicate_ids' as metric,
           (COUNT(*) - COUNT(DISTINCT id))::VARCHAR FROM data
    UNION ALL
    SELECT 'future_dates' as metric,
           SUM(CASE WHEN created_at > CURRENT_DATE THEN 1 ELSE 0 END)::VARCHAR FROM data
    UNION ALL
    SELECT 'negative_amounts' as metric,
           SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END)::VARCHAR FROM data

    ORDER BY metric
""").pl()

print("Data Quality Report:")
print(quality_report)

# Flag records with issues using Polars
flagged_records = (
    data
    .with_columns([
        pl.when(pl.col('email').is_null())
            .then(pl.lit(True))
            .otherwise(pl.lit(False))
            .alias('missing_email'),
        pl.when(~pl.col('email').str.contains('@'))
            .then(pl.lit(True))
            .otherwise(pl.lit(False))
            .alias('invalid_email'),
        pl.when(pl.col('amount') < 0)
            .then(pl.lit(True))
            .otherwise(pl.lit(False))
            .alias('negative_amount')
    ])
    .filter(
        pl.col('missing_email') |
        pl.col('invalid_email') |
        pl.col('negative_amount')
    )
)
```

## Performance Considerations

### When to Use DuckDB vs Polars

**Use DuckDB when:**
- Complex SQL queries with multiple joins, CTEs, or subqueries
- Window functions and advanced aggregations
- SQL is more natural for the task
- Working with SQL-familiar team members

**Use Polars when:**
- Simple filtering and transformations
- Reading/writing data files
- Need lazy evaluation for query optimization
- Chaining operations in a pipeline

**Use Both when:**
- Complex analytics on large datasets
- Need both SQL expressiveness and DataFrame performance
- Building ETL pipelines
- Combining data from multiple sources

### Memory Efficiency

```python
import polars as pl
import duckdb

# Efficient: Use Polars lazy + DuckDB for minimal memory footprint
result = duckdb.sql("""
    SELECT category, SUM(amount) as total
    FROM df
    GROUP BY category
""").pl(lazy=True)  # Lazy Polars DataFrame

# Process only when needed
top_categories = result.top_k(10, by='total').collect()

# Less efficient: Materializing large intermediate results
df = pl.read_parquet('huge_file.parquet')  # Loads everything
result = df.group_by('category').agg(pl.sum('amount'))  # In-memory aggregation
```

## Troubleshooting

### Issue: "pyarrow not found"

```bash
pip install 'polars[pyarrow]'
```

### Issue: Column name conflicts

```python
# Use explicit column selection
result = duckdb.sql("""
    SELECT
        df.id as polars_id,
        df.name,
        df.value
    FROM df
""").pl()
```

### Issue: Data type mismatches

```python
# Convert types before querying
df = df.with_columns([
    pl.col('date').str.strptime(pl.Date, '%Y-%m-%d'),
    pl.col('amount').cast(pl.Float64)
])

result = duckdb.sql("SELECT * FROM df WHERE date >= '2024-01-01'").pl()
```

## Best Practices

1. **Use lazy evaluation when possible** - Delays computation until necessary
2. **Filter data early** - Reduce data volume before complex operations
3. **Choose the right tool for each step** - Polars for I/O, DuckDB for SQL
4. **Use Parquet for large datasets** - Columnar format benefits both tools
5. **Monitor memory usage** - Profile code to optimize performance

## Example: Complete Analytics Workflow

```python
import polars as pl
import duckdb
from datetime import datetime

# 1. Extract: Load data efficiently with Polars
orders = pl.scan_parquet('orders/*.parquet').collect()
customers = pl.read_csv('customers.csv')
products = pl.read_parquet('products.parquet')

# 2. Transform: Complex analytics with DuckDB
analysis = duckdb.sql("""
    WITH customer_metrics AS (
        SELECT
            c.customer_id,
            c.segment,
            c.region,
            COUNT(DISTINCT o.order_id) as num_orders,
            SUM(o.order_total) as total_spent,
            AVG(o.order_total) as avg_order_value,
            MIN(o.order_date) as first_order,
            MAX(o.order_date) as last_order,
            EXTRACT(DAYS FROM (MAX(o.order_date) - MIN(o.order_date))) as customer_age_days
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id, c.segment, c.region
    ),
    product_popularity AS (
        SELECT
            p.product_id,
            p.category,
            COUNT(*) as times_ordered,
            SUM(o.quantity) as total_quantity
        FROM orders o
        JOIN products p ON o.product_id = p.product_id
        GROUP BY p.product_id, p.category
    )
    SELECT
        cm.*,
        pp.category as top_category
    FROM customer_metrics cm
    LEFT JOIN orders o ON cm.customer_id = o.customer_id
    LEFT JOIN product_popularity pp ON o.product_id = pp.product_id
    WHERE cm.num_orders > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cm.customer_id ORDER BY pp.times_ordered DESC) = 1
""").pl()

# 3. Load: Final processing and export with Polars
final_report = (
    analysis
    .with_columns([
        (pl.col('total_spent') / pl.col('num_orders')).alias('spend_per_order'),
        (pl.col('customer_age_days') / 30).alias('customer_age_months'),
        pl.when(pl.col('total_spent') > 10000)
            .then(pl.lit('VIP'))
            .when(pl.col('total_spent') > 5000)
            .then(pl.lit('High Value'))
            .otherwise(pl.lit('Standard'))
            .alias('customer_tier')
    ])
    .sort('total_spent', descending=True)
)

# Export results
final_report.write_parquet('customer_analysis.parquet')
final_report.write_csv('customer_analysis.csv')

print(f"Analysis complete: {len(final_report)} customers analyzed")
print(final_report.head(10))
```

## Additional Resources

- DuckDB Python API: https://duckdb.org/docs/api/python/overview
- Polars User Guide: https://docs.pola.rs/user-guide/
- DuckDB + Polars Integration: https://duckdb.org/docs/guides/python/polars
