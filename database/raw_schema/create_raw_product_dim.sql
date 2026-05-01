CREATE TABLE IF NOT EXISTS raw.product_dim (
    product_id BIGINT PRIMARY KEY,
    category_id NUMERIC(20, 0),
    category_code VARCHAR(255),
    brand VARCHAR(255),
    source_system VARCHAR(50) DEFAULT 'mysql_product_master',
    loaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
ON raw.product_dim
TO analytics_user;