SELECT COUNT(*) AS total_rows
FROM dbt_dev_marts.mart_revenue_attribution;

SELECT
    category_code,
    brand,
    SUM(total_revenue) AS revenue,
    SUM(purchase_events) AS purchases
FROM dbt_dev_marts.mart_revenue_attribution
GROUP BY category_code, brand
ORDER BY revenue DESC
LIMIT 20;

SELECT *
FROM dbt_dev_marts.mart_revenue_attribution
ORDER BY total_revenue DESC
LIMIT 10;