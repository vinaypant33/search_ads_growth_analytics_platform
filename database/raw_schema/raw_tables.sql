
SELECT current_database();

CREATE SCHEMA IF NOT EXISTS raw AUTHORIZATION analytics_user;

DROP TABLE IF EXISTS raw.raw_events CASCADE;

CREATE TABLE raw.raw_events (
    event_id        BIGSERIAL PRIMARY KEY,
    event_time      TIMESTAMPTZ NOT NULL,
    event_type      VARCHAR(50) NOT NULL,
    product_id      BIGINT NOT NULL,
    category_id     NUMERIC(20, 0),
    price           NUMERIC(12, 2),
    user_id         BIGINT NOT NULL,
    user_session    VARCHAR(100),
    source_file     VARCHAR(255),
    loaded_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE raw.raw_events
ADD CONSTRAINT chk_raw_events_event_type
CHECK (event_type IN ('view', 'cart', 'purchase'));

ALTER TABLE raw.raw_events
ADD CONSTRAINT chk_raw_events_price_non_negative
CHECK (price IS NULL OR price >= 0);

CREATE INDEX IF NOT EXISTS idx_raw_events_event_time
ON raw.raw_events (event_time);

CREATE INDEX IF NOT EXISTS idx_raw_events_user_id
ON raw.raw_events (user_id);

CREATE INDEX IF NOT EXISTS idx_raw_events_user_session
ON raw.raw_events (user_session);

CREATE INDEX IF NOT EXISTS idx_raw_events_product_id
ON raw.raw_events (product_id);

CREATE INDEX IF NOT EXISTS idx_raw_events_event_type
ON raw.raw_events (event_type);

GRANT USAGE ON SCHEMA raw TO analytics_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA raw TO analytics_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA raw TO analytics_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA raw
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analytics_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA raw
GRANT USAGE, SELECT ON SEQUENCES TO analytics_user;

