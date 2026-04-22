-- Commands outisde the script  : 

ALTER SCHEMA raw OWNER TO analytics_user;

ALTER TABLE raw.raw_events OWNER TO analytics_user;

GRANT USAGE ON SCHEMA raw TO analytics_user;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
ON raw.raw_events
TO analytics_user;

GRANT USAGE, SELECT
ON SEQUENCE raw.raw_events_event_id_seq
TO analytics_user;

