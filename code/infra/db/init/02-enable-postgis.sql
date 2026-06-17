-- geo_db'da PostGIS kengaytmasini yoqish (xarita/marshrut/zona uchun)
-- plan/09-maps-navigation.md
\connect geo_db
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- taxi_db va delivery_db ham geo so'rovlardan foydalanishi mumkin
\connect taxi_db
CREATE EXTENSION IF NOT EXISTS postgis;

\connect delivery_db
CREATE EXTENSION IF NOT EXISTS postgis;

\connect restaurant_db
CREATE EXTENSION IF NOT EXISTS postgis;
