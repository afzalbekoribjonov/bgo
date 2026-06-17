#!/usr/bin/env bash
# Beshariq Super-App — OSRM marshrut serverini tayyorlash (bir martalik + oylik yangilash)
# plan/09-maps-navigation.md
#
# Talab: Docker (osrm/osrm-backend image) yoki OSRM binarlari.
# Bu skript O'zbekiston OSM ma'lumotini yuklab, marshrut grafini tayyorlaydi.

set -euo pipefail

DATA_DIR="$(dirname "$0")/data"
PBF_URL="https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf"
PBF_FILE="$DATA_DIR/uzbekistan-latest.osm.pbf"
PROFILE="car" # taksi/kuryer mashina uchun

mkdir -p "$DATA_DIR"

echo "==> 1/5 OSM ma'lumotini yuklab olish (O'zbekiston)"
if [ ! -f "$PBF_FILE" ]; then
  wget -O "$PBF_FILE" "$PBF_URL"
else
  echo "    (mavjud, qayta yuklanmadi)"
fi

# Docker orqali OSRM (binar o'rnatmaslik uchun qulay)
OSRM="docker run --rm -t -v ${DATA_DIR}:/data osrm/osrm-backend"

echo "==> 2/5 osrm-extract (profil: $PROFILE)"
$OSRM osrm-extract -p "/opt/${PROFILE}.lua" "/data/uzbekistan-latest.osm.pbf"

echo "==> 3/5 osrm-partition"
$OSRM osrm-partition "/data/uzbekistan-latest.osrm"

echo "==> 4/5 osrm-customize"
$OSRM osrm-customize "/data/uzbekistan-latest.osrm"

echo "==> 5/5 Tayyor. Serverni ishga tushirish uchun:"
echo "    docker run --rm -t -p 5000:5000 -v ${DATA_DIR}:/data \\"
echo "      osrm/osrm-backend osrm-routed --algorithm mld /data/uzbekistan-latest.osrm"
echo ""
echo "Test: curl 'http://localhost:5000/route/v1/driving/71.0,40.4;71.05,40.42?overview=false'"
