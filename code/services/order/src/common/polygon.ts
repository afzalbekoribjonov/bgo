/** GeoJSON Polygon koordinatalari: halqalar ro'yxati, har biri [lng, lat] nuqtalar. */
export type PolygonCoords = number[][][];

/** Nuqta bitta halqa ichidami — ray casting algoritmi. */
function pointInRing(lng: number, lat: number, ring: number[][]): boolean {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const xi = ring[i][0];
    const yi = ring[i][1];
    const xj = ring[j][0];
    const yj = ring[j][1];
    const intersect =
      yi > lat !== yj > lat &&
      lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

/**
 * Nuqta (lat, lng) poligon ichidami. Birinchi halqa — tashqi chegara,
 * qolganlari — "teshik"lar (ichida bo'lsa — tashqarida hisoblanadi).
 */
export function pointInPolygon(
  lat: number,
  lng: number,
  polygon: PolygonCoords,
): boolean {
  if (!Array.isArray(polygon) || polygon.length === 0) return false;
  if (!pointInRing(lng, lat, polygon[0])) return false;
  for (let k = 1; k < polygon.length; k++) {
    if (pointInRing(lng, lat, polygon[k])) return false;
  }
  return true;
}
