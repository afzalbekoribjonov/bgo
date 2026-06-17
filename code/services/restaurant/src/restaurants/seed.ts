import { Category, MenuItem, Restaurant } from './entities';

/** Dev uchun namunaviy katalog (Beshariq). plan/03-databases.md */
export function buildSeed(): {
  restaurants: Restaurant[];
  categories: Category[];
  menuItems: MenuItem[];
} {
  const now = new Date().toISOString();

  const restaurants: Restaurant[] = [
    {
      id: 'r1',
      name: 'Milliy Taomlar',
      lat: 40.421,
      lng: 70.609,
      address: 'Beshariq markazi',
      phone: '+998900000001',
      status: 'ACTIVE',
      commissionPercent: 12,
      isOpen: true,
      rating: 4.7,
      createdAt: now,
    },
    {
      id: 'r2',
      name: 'Fast Food Beshariq',
      lat: 40.4185,
      lng: 70.6125,
      address: "Beshariq, Mustaqillik ko'chasi",
      phone: '+998900000002',
      status: 'ACTIVE',
      commissionPercent: 15,
      isOpen: true,
      rating: 4.4,
      createdAt: now,
    },
  ];

  const categories: Category[] = [
    { id: 'c1', restaurantId: 'r1', sortOrder: 1, name: { uz: 'Issiq taomlar', uz_Cyrl: 'Иссиқ таомлар', ru: 'Горячие блюда' } },
    { id: 'c2', restaurantId: 'r1', sortOrder: 2, name: { uz: 'Salatlar', uz_Cyrl: 'Салатлар', ru: 'Салаты' } },
    { id: 'c3', restaurantId: 'r1', sortOrder: 3, name: { uz: 'Ichimliklar', uz_Cyrl: 'Ичимликлар', ru: 'Напитки' } },
    { id: 'c4', restaurantId: 'r2', sortOrder: 1, name: { uz: 'Burgerlar', uz_Cyrl: 'Бургерлар', ru: 'Бургеры' } },
    { id: 'c5', restaurantId: 'r2', sortOrder: 2, name: { uz: 'Ichimliklar', uz_Cyrl: 'Ичимликлар', ru: 'Напитки' } },
  ];

  const menuItems: MenuItem[] = [
    { id: 'm1', restaurantId: 'r1', categoryId: 'c1', price: 30000, isAvailable: true, createdAt: now, name: { uz: 'Osh', uz_Cyrl: 'Ош', ru: 'Плов' }, description: { uz: "An'anaviy palov", uz_Cyrl: 'Анъанавий палов', ru: 'Традиционный плов' } },
    { id: 'm2', restaurantId: 'r1', categoryId: 'c1', price: 28000, isAvailable: true, createdAt: now, name: { uz: 'Manti', uz_Cyrl: 'Манти', ru: 'Манты' } },
    { id: 'm3', restaurantId: 'r1', categoryId: 'c1', price: 27000, isAvailable: true, createdAt: now, name: { uz: "Lag'mon", uz_Cyrl: 'Лағмон', ru: 'Лагман' } },
    { id: 'm4', restaurantId: 'r1', categoryId: 'c2', price: 12000, isAvailable: true, createdAt: now, name: { uz: 'Achichuq', uz_Cyrl: 'Аччиқ-чучук', ru: 'Ачичук' } },
    { id: 'm5', restaurantId: 'r1', categoryId: 'c3', price: 5000, isAvailable: true, createdAt: now, name: { uz: 'Choy', uz_Cyrl: 'Чой', ru: 'Чай' } },
    { id: 'm6', restaurantId: 'r2', categoryId: 'c4', price: 25000, isAvailable: true, createdAt: now, name: { uz: 'Gamburger', uz_Cyrl: 'Гамбургер', ru: 'Гамбургер' } },
    { id: 'm7', restaurantId: 'r2', categoryId: 'c4', price: 22000, isAvailable: true, createdAt: now, name: { uz: 'Lavash', uz_Cyrl: 'Лаваш', ru: 'Лаваш' } },
    { id: 'm8', restaurantId: 'r2', categoryId: 'c5', price: 8000, isAvailable: false, createdAt: now, name: { uz: 'Kola', uz_Cyrl: 'Кола', ru: 'Кола' } },
  ];

  return { restaurants, categories, menuItems };
}
