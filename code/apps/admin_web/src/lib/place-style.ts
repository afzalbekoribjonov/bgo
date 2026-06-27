/** Joy turlari — xaritada belgilab qo'yish uchun (oshxona, parkovka, ...). */
export interface PlaceCategory {
  key: string;
  label: string;
  color: string;
  emoji: string;
}

export const PLACE_CATEGORIES: PlaceCategory[] = [
  { key: 'restaurant', label: 'Oshxona', color: '#e8590c', emoji: '🍽️' },
  { key: 'parking', label: 'Parkovka', color: '#1971c2', emoji: '🅿️' },
  { key: 'hospital', label: 'Shifoxona', color: '#e03131', emoji: '🏥' },
  { key: 'market', label: 'Bozor', color: '#2f9e44', emoji: '🛒' },
  { key: 'pharmacy', label: 'Dorixona', color: '#0ca678', emoji: '💊' },
  { key: 'school', label: 'Maktab/Bog‘cha', color: '#7048e8', emoji: '🏫' },
  { key: 'mosque', label: 'Masjid', color: '#5c940d', emoji: '🕌' },
  { key: 'mahalla', label: 'Mahalla', color: '#0c8599', emoji: '🏘️' },
  { key: 'station', label: 'Bekat', color: '#f08c00', emoji: '🚌' },
  { key: 'landmark', label: 'Mo‘ljal', color: '#495057', emoji: '📍' },
];

const _byKey: Record<string, PlaceCategory> = Object.fromEntries(
  PLACE_CATEGORIES.map((c) => [c.key, c]),
);

export function placeCategory(key: string | null | undefined): PlaceCategory {
  return (key && _byKey[key]) || _byKey.landmark;
}
