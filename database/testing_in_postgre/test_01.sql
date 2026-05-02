SELECT COUNT(*) AS total_products
FROM dbt_dev_analytics.dim_product;

SELECT
    COUNT(*) FILTER (WHERE category_code = 'unknown') AS unknown_categories,
    COUNT(*) FILTER (WHERE brand = 'unknown') AS unknown_brands
FROM dbt_dev_analytics.dim_product;

SELECT *
FROM dbt_dev_analytics.dim_product
LIMIT 10;