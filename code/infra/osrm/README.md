# OSRM — Marshrut serveri

Bepul marshrut/ETA tizimi (OpenStreetMap asosida). Batafsil: [`../../../plan/09-maps-navigation.md`](../../../plan/09-maps-navigation.md).

## Tayyorlash
```bash
bash infra/osrm/build-osrm.sh
```
Bu O'zbekiston OSM ma'lumotini yuklab, marshrut grafini tayyorlaydi (`data/` papkada).

## Ishga tushirish
```bash
docker run --rm -t -p 5000:5000 -v "$PWD/infra/osrm/data:/data" \
  osrm/osrm-backend osrm-routed --algorithm mld /data/uzbekistan-latest.osrm
```

## API namuna
```
GET http://localhost:5000/route/v1/driving/{lon1},{lat1};{lon2},{lat2}
GET http://localhost:5000/table/v1/driving/...   # masofa matritsasi (dispatch)
```

> `data/` papka `.gitignore`'da (fayllar katta, generatsiya qilinadi).
> Faza 3 (haydovchi/dostavka) da Routing servisi shu serverdan foydalanadi.
