USE product_master;

DROP TABLE IF EXISTS product_dim;

CREATE TABLE product_dim (
    product_id BIGINT NOT NULL,
    category_id DECIMAL(20, 0),
    category_code VARCHAR(255),
    brand VARCHAR(255),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (product_id)
);

CREATE INDEX idx_product_dim_category_id
ON product_dim (category_id);

CREATE INDEX idx_product_dim_category_code
ON product_dim (category_code);

CREATE INDEX idx_product_dim_brand
ON product_dim (brand);