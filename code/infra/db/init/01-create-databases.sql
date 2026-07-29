-- Beshariq Super-App — boshlang'ich DB yaratish (database-per-service)
-- Bu skript Postgres konteyneri BIRINCHI marta ishga tushganda avtomatik bajariladi.
-- Model: plan/03-databases.md

-- Har servisning o'z databasesi
CREATE DATABASE auth_db;
CREATE DATABASE user_db;
CREATE DATABASE order_db;
CREATE DATABASE taxi_db;
CREATE DATABASE delivery_db;
CREATE DATABASE restaurant_db;
CREATE DATABASE pricing_db;
CREATE DATABASE promo_db;
CREATE DATABASE payment_db;
CREATE DATABASE notif_db;
CREATE DATABASE market_db;
CREATE DATABASE marketplace_db;
CREATE DATABASE support_db;

-- Navigator/geo uchun alohida DB (PostGIS bilan)
CREATE DATABASE geo_db;
