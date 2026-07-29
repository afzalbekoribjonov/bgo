/** Joy turlari — xaritada belgilab qo'yish uchun (oshxona, parkovka, ...). */
export interface PlaceCategory {
  key: string;
  label: string;
  color: string;
  emoji: string;
}

export const PLACE_CATEGORIES: PlaceCategory[] = [
  // Ovqat & ichimlik
  { key: 'restaurant', label: 'Oshxona',      color: '#e8590c', emoji: '🍽️' },
  { key: 'cafe',       label: 'Kafe',          color: '#a05c34', emoji: '☕' },
  // Ta'lim
  { key: 'school',      label: 'Maktab',       color: '#7048e8', emoji: '🏫' },
  { key: 'kindergarten',label: "Bog'cha",      color: '#e67700', emoji: '🧸' },
  // Sog'liq
  { key: 'hospital',   label: 'Kasalxona',     color: '#e03131', emoji: '🏥' },
  { key: 'pharmacy',   label: 'Dorixona',      color: '#0ca678', emoji: '💊' },
  // Savdo
  { key: 'market',     label: 'Bozor',         color: '#2f9e44', emoji: '🛒' },
  { key: 'shop',       label: "Do'kon",        color: '#1971c2', emoji: '🏪' },
  // Din & madaniyat
  { key: 'mosque',     label: 'Masjid',        color: '#5c940d', emoji: '🕌' },
  { key: 'museum',     label: 'Muzey',         color: '#495057', emoji: '🏛️' },
  // Sport & dam olish
  { key: 'park',       label: 'Park',          color: '#2f9e44', emoji: '🌳' },
  { key: 'stadium',    label: 'Stadion',       color: '#0c8599', emoji: '🏟️' },
  // Transport
  { key: 'station',    label: 'Bekat',                color: '#f08c00', emoji: '🚌' },
  { key: 'parking',    label: 'Parkovka',             color: '#1971c2', emoji: '🅿️' },
  // Yoqilg'i & avto xizmatlar
  { key: 'fuel',       label: "Yoqilg'i shahobchasi", color: '#e65100', emoji: '⛽' },
  { key: 'car_repair', label: 'Avtoservis/Ustaxona',  color: '#546e7a', emoji: '🔧' },
  { key: 'car_wash',   label: 'Avto yuvish',          color: '#0288d1', emoji: '🚿' },
  // Xizmatlar
  { key: 'bank',       label: 'Bank',                 color: '#1864ab', emoji: '🏦' },
  { key: 'post',       label: 'Pochta',               color: '#d9480f', emoji: '📮' },
  { key: 'hotel',      label: 'Mehmonxona',           color: '#7048e8', emoji: '🏨' },
  { key: 'atm',        label: 'Bankomat',             color: '#00897b', emoji: '🏧' },
  { key: 'toilet',     label: 'Umumiy hojatxona',     color: '#78909c', emoji: '🚻' },
  // Xavfsizlik & yo'l
  { key: 'police',     label: "Politsiya bo'limi",    color: '#283593', emoji: '🚔' },
  { key: 'pedestrian', label: "Peshaxod o'tishi",     color: '#f9a825', emoji: '🚶' },
  // Mahalla & boshqa
  { key: 'mahalla',    label: 'Mahalla',              color: '#0c8599', emoji: '🏘️' },
  { key: 'landmark',   label: "Mo'ljal",              color: '#495057', emoji: '📍' },
];

const _byKey: Record<string, PlaceCategory> = Object.fromEntries(
  PLACE_CATEGORIES.map((c) => [c.key, c]),
);

export function placeCategory(key: string | null | undefined): PlaceCategory {
  return (key && _byKey[key]) || _byKey.landmark;
}
