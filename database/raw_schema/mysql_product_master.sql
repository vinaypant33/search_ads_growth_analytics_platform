CREATE DATABASE IF NOT EXISTS product_master;

CREATE USER IF NOT EXISTS 'analytics_user'@'localhost'
IDENTIFIED BY 'Admin1234';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP
ON product_master.*
TO 'analytics_user'@'localhost';

FLUSH PRIVILEGES;

