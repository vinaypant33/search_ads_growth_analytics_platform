-- dedicated user for this project 
CREATE USER analytics_user WITH PASSWORD 'Admin1234';

-- database for this project 
CREATE DATABASE search_ads_analytics
    OWNER analytics_user;

-- permissions to connect with this databse
GRANT CONNECT ON DATABASE search_ads_analytics TO analytics_user;

