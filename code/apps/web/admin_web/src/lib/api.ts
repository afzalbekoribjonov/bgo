import type {
  AdminDriver,
  AdminDriverMessage,
  AdminOrder,
  AdminRestaurant,
  CreateAreaInput,
  CreateDriverInput,
  CreateMarkerInput,
  CreateRestaurantInput,
  CreateRoadInput,
  AdminCustomer,
  CustomerComplaint,
  CustomerMessage,
  ComplaintStatus,
  DriverOrderHistoryItem,
  DriverStats,
  GeoPlace,
  I18nString,
  LiveDrivers,
  MapMarker,
  MapRoad,
  MarketCategory,
  MarketComment,
  MarketPickupLocation,
  MarketplaceCategory,
  MarketplaceSeller,
  MarketProduct,
  MarketSettings,
  MarketSupportMessage,
  MarketSupportThread,
  OrderDetail,
  OrdersQuery,
  OwnerCandidate,
  PagedResult,
  PartnerApplication,
  SellerType,
  CreateSellerInput,
  UpdateSellerInput,
  PromoCode,
  Report,
  ReportPeriod,
  ReportRange,
  Restaurant,
  RestaurantMenuView,
  ServiceArea,
  Stats,
  SuspiciousDriversResponse,
  StoreOrder,
  StoreOrdersPage,
  StoreOrderStatus,
  SupportChatMessage,
  SupportConversation,
  SupportConversationStatus,
  SupportFaqItem,
  SupportUserRole,
  Tariff,
  UpdateDriverInput,
  UpdateRestaurantInput,
  UpdateRoadInput,
} from './types';
import { clearToken, getToken } from './auth';

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

async function api<T>(path: string, opts?: RequestInit): Promise<T> {
  const token = getToken();
  const res = await fetch(`${BASE}${path}`, {
    cache: 'no-store',
    ...opts,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts?.headers ?? {}),
    },
  });
  if (res.status === 401 || res.status === 403) {
    // Sessiya tugagan / ruxsat yo'q — qayta login
    clearToken();
    if (typeof window !== 'undefined') window.location.reload();
    throw new Error('Avtorizatsiya talab qilinadi');
  }
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`);
  }
  return body?.data as T;
}

export const getStats = () => api<Stats>('/admin/stats');
export const getReport = (period: ReportPeriod) =>
  api<Report>(`/admin/reports?period=${period}`);
/** Ixtiyoriy sana oralig'i (istalgan kun/oy) — YYYY-MM-DD. */
export const getReportRange = (from: string, to: string) =>
  api<ReportRange>(`/admin/reports/range?from=${from}&to=${to}`);
export const getOrders = (query: OrdersQuery & { driverId?: string } = {}) => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value) params.set(key, String(value));
  }
  const qs = params.toString();
  return api<AdminOrder[]>(`/admin/orders${qs ? `?${qs}` : ''}`);
};
export const cancelOrder = (id: string) =>
  api<unknown>(`/admin/orders/${id}/cancel`, { method: 'POST' });
/** Bitta buyurtmaning to'liq holati (alohida sahifa). */
export const getOrderDetail = (id: string, type: 'FOOD' | 'TAXI' | 'PARCEL') =>
  api<OrderDetail>(`/admin/orders/${id}/detail?type=${type}`);
/** Jonli xarita: online haydovchilar (joylashuv + yo'nalish + bandlik). */
export const getLiveDrivers = () => api<LiveDrivers>('/admin/live-drivers');
export const getSuspiciousDrivers = () =>
  api<SuspiciousDriversResponse>('/admin/suspicious-drivers');
export const getRestaurants = () => api<Restaurant[]>('/restaurants');
export const getManageRestaurants = () =>
  api<AdminRestaurant[]>('/restaurants/manage/all');
export const getRestaurantMenu = (id: string) =>
  api<RestaurantMenuView>(`/restaurants/${id}/menu`);
export const createRestaurant = (body: CreateRestaurantInput) =>
  api<AdminRestaurant>('/restaurants', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateRestaurant = (id: string, body: UpdateRestaurantInput) =>
  api<AdminRestaurant>(`/restaurants/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const assignRestaurantOwner = (id: string, ownerUserId: string) =>
  api<AdminRestaurant>(`/restaurants/${id}/owner`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ownerUserId }),
  });
/** Telefon bo'yicha foydalanuvchini qidiradi (ega biriktirishdan oldin ko'rsatish). */
export const lookupRestaurantOwner = (phone: string) =>
  api<OwnerCandidate | null>('/restaurants/owner-lookup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone }),
  });
/** Egani telefon raqami bo'yicha biriktiradi — userId avtomatik topiladi. */
export const assignRestaurantOwnerByPhone = (id: string, phone: string) =>
  api<AdminRestaurant>(`/restaurants/${id}/owner-by-phone`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone }),
  });

// ----- Haydovchilar (admin onboarding + 8 xonali kod) -----
export const getDrivers = () => api<AdminDriver[]>('/auth/admin/drivers');
export const getDriver = (id: string) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}`);
export const createDriver = (body: CreateDriverInput) =>
  api<AdminDriver>('/auth/admin/drivers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateDriver = (id: string, body: UpdateDriverInput) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const regenerateDriverCode = (id: string) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}/regenerate-code`, {
    method: 'POST',
  });
export const topupDriver = (id: string, amount: number, note?: string) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}/topup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ amount, note }),
  });
/** Haydovchi(lar)ga xabar: driverUserId yo'q = hammaga (broadcast). */
export const sendDriverMessage = (body: {
  driverUserId?: string;
  title?: string;
  body: string;
}) =>
  api<AdminDriverMessage>('/auth/admin/drivers/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const getDriverMessages = () =>
  api<AdminDriverMessage[]>('/auth/admin/drivers/messages');
/** Ma'lum muddatga bloklash — sabab majburiy, minutes = necha daqiqaga. */
export const blockDriver = (id: string, reason: string, minutes: number) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}/block`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reason, minutes }),
  });
/** Darhol blokdan chiqarish (masalan ofisda jarima to'langach). */
export const unblockDriver = (id: string) =>
  api<AdminDriver>(`/auth/admin/drivers/${id}/unblock`, { method: 'POST' });
export const getDriverHistory = (id: string) =>
  api<DriverOrderHistoryItem[]>(`/admin/drivers/${id}/history`);
export const getDriverStats = (id: string, period: 'today' | 'week' | 'month' | 'all') =>
  api<DriverStats>(`/admin/drivers/${id}/stats?period=${period}`);
export const getPromos = () => api<PromoCode[]>('/admin/promos');
export const createPromo = (body: {
  code: string;
  type: 'PERCENT' | 'FIXED';
  value: number;
  minOrder: number;
}) =>
  api<PromoCode>('/admin/promos', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const togglePromo = (id: string, active: boolean) =>
  api<PromoCode>(`/admin/promos/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ active }),
  });
export const deletePromo = (id: string) =>
  api<unknown>(`/admin/promos/${id}`, { method: 'DELETE' });

export const getTariff = () => api<Tariff>('/admin/tariff');
export const updateTariff = (body: {
  deliveryFee: number;
  foodCommissionPercent: number;
  courierSharePercent: number;
  taxiBaseFare: number;
  taxiPerKm: number;
  taxiMinFare: number;
  taxiCommissionPercent: number;
  taxiWaitPerMin: number;
  taxiWaitFreeMin: number;
  taxiPickupSurchargePerKm: number;
  taxiPickupSurchargeThresholdKm: number;
  taxiComfortPerKmExtra: number;
  taxiComfortBaseExtra: number;
  parcelBaseFare: number;
  parcelPerKm: number;
  parcelMinFare: number;
  parcelCommissionPercent: number;
  foodServiceThreshold: number;
  foodServiceFeeUnder: number;
  foodServiceFeeOver: number;
  homeModeTaxiCommissionPercent: number;
  homeModeParcelCommissionPercent: number;
  homeModeMaxDetourPercent: number;
  homeModeMaxHomeDistanceKm: number;
}) =>
  api<Tariff>('/admin/tariff', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

// ----- Oshxona paneli kirish ma'lumoti (login/parol) -----
export const getKitchenCredential = (restaurantId: string) =>
  api<{ exists: boolean; username: string | null }>(
    `/auth/admin/kitchen-credentials/${restaurantId}`,
  );
export const setKitchenCredential = (
  restaurantId: string,
  username: string,
  password: string,
) =>
  api<{ restaurantId: string; username: string }>(
    '/auth/admin/kitchen-credentials',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ restaurantId, username, password }),
    },
  );

export const getPartners = (status?: string) =>
  api<PartnerApplication[]>(
    `/auth/admin/partners${status ? `?status=${status}` : ''}`,
  );
export const updatePartnerStatus = (
  id: string,
  status: 'APPROVED' | 'REJECTED',
) =>
  api<PartnerApplication>(`/auth/admin/partners/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });

// ----- Geo (xizmat hududlari + joylar) -----
export const getGeoAreas = () => api<ServiceArea[]>('/admin/geo/areas');
export const createGeoArea = (body: CreateAreaInput) =>
  api<ServiceArea>('/admin/geo/areas', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateGeoArea = (id: string, body: { isActive?: boolean; name?: string }) =>
  api<ServiceArea>(`/admin/geo/areas/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoArea = (id: string) =>
  api<unknown>(`/admin/geo/areas/${id}`, { method: 'DELETE' });
export const addGeoPlace = (
  areaId: string,
  body: { label: string; lat: number; lng: number; category?: string },
) =>
  api<GeoPlace>(`/admin/geo/areas/${areaId}/places`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoPlace = (id: string) =>
  api<unknown>(`/admin/geo/places/${id}`, { method: 'DELETE' });

// ----- Geo yo'llar (Beshariq navigatsiya qatlami) -----
export const getGeoRoads = () => api<MapRoad[]>('/admin/geo/roads');
export const addGeoRoad = (areaId: string, body: CreateRoadInput) =>
  api<MapRoad>(`/admin/geo/areas/${areaId}/roads`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoRoad = (id: string) =>
  api<unknown>(`/admin/geo/roads/${id}`, { method: 'DELETE' });
export const updateGeoRoad = (id: string, body: UpdateRoadInput) =>
  api<MapRoad>(`/admin/geo/roads/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const importOsmRoads = () =>
  api<{ imported: number }>('/admin/geo/import-osm-roads', { method: 'POST' });
export const importOsmPlaces = () =>
  api<{ imported: number; skipped: number }>('/admin/geo/import-osm-places', {
    method: 'POST',
  });
export const getGeoMarkers = (areaId?: string) =>
  api<MapMarker[]>(`/admin/geo/markers${areaId ? `?areaId=${areaId}` : ''}`);
export const addGeoMarker = (areaId: string, body: CreateMarkerInput) =>
  api<MapMarker>(`/admin/geo/areas/${areaId}/markers`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoMarker = (id: string) =>
  api<unknown>(`/admin/geo/markers/${id}`, { method: 'DELETE' });

// ----- Market (Beshariq Market) -----
export const getMarketCategories = () => api<MarketCategory[]>('/market/admin/categories');
export const createMarketCategory = (body: { name: I18nString; sortOrder?: number }) =>
  api<MarketCategory>('/market/admin/categories', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateMarketCategory = (
  id: string,
  body: { name?: I18nString; sortOrder?: number },
) =>
  api<MarketCategory>(`/market/admin/categories/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteMarketCategory = (id: string) =>
  api<unknown>(`/market/admin/categories/${id}`, { method: 'DELETE' });

export const getMarketProducts = (
  query: { categoryId?: string; q?: string; page?: number; pageSize?: number } = {},
) => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value) params.set(key, String(value));
  }
  const qs = params.toString();
  return api<PagedResult<MarketProduct>>(`/market/admin/products${qs ? `?${qs}` : ''}`);
};
export const getMarketSettings = () => api<MarketSettings>('/market/admin/settings');
export const updateMarketSettings = (body: {
  minOrderAmount?: number;
  isAcceptingOrders?: boolean;
}) =>
  api<MarketSettings>('/market/admin/settings', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const createMarketProduct = (body: {
  categoryId: string;
  name: I18nString;
  description?: I18nString;
  price: number;
  stockQty?: number;
  imageUrls?: string[];
  sizes?: string[];
  isActive?: boolean;
}) =>
  api<MarketProduct>('/market/admin/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateMarketProduct = (
  id: string,
  body: Partial<{
    categoryId: string;
    name: I18nString;
    description: I18nString;
    price: number;
    imageUrls: string[];
    sizes: string[];
    isActive: boolean;
  }>,
) =>
  api<MarketProduct>(`/market/admin/products/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const adjustMarketStock = (id: string, delta: number) =>
  api<MarketProduct>(`/market/admin/products/${id}/stock`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ delta }),
  });
export const deleteMarketProduct = (id: string) =>
  api<unknown>(`/market/admin/products/${id}`, { method: 'DELETE' });
export const getMarketComments = (productId: string) =>
  api<MarketComment[]>(`/market/products/${productId}/comments`);
export const deleteMarketComment = (id: string) =>
  api<unknown>(`/market/admin/comments/${id}`, { method: 'DELETE' });

export const getMarketPickupLocations = () =>
  api<MarketPickupLocation[]>('/market/admin/pickup-locations');
export const createMarketPickupLocation = (body: {
  name: string;
  address: string;
  lat: number;
  lng: number;
}) =>
  api<MarketPickupLocation>('/market/admin/pickup-locations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateMarketPickupLocation = (
  id: string,
  body: Partial<{ name: string; address: string; lat: number; lng: number; isActive: boolean }>,
) =>
  api<MarketPickupLocation>(`/market/admin/pickup-locations/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

export const getMarketSupportThreads = () =>
  api<MarketSupportThread[]>('/market/support/admin/threads');
export const getMarketSupportMessages = (customerId: string) =>
  api<MarketSupportMessage[]>(`/market/support/admin/threads/${customerId}`);
export const sendMarketSupportReply = (customerId: string, text: string) =>
  api<MarketSupportMessage>(`/market/support/admin/threads/${customerId}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

// Yordam (AI support chat — customer_app + driver_app)
export const getSupportConversations = (filter: {
  status?: SupportConversationStatus;
  role?: SupportUserRole;
  page?: number;
  pageSize?: number;
}) => {
  const params = new URLSearchParams();
  if (filter.status) params.set('status', filter.status);
  if (filter.role) params.set('role', filter.role);
  params.set('page', String(filter.page ?? 1));
  params.set('pageSize', String(filter.pageSize ?? 20));
  return api<{
    items: SupportConversation[];
    total: number;
    page: number;
    pageSize: number;
  }>(`/support/admin/conversations?${params.toString()}`);
};
export const getSupportConversationMessages = (id: string) =>
  api<{ conversation: SupportConversation; messages: SupportChatMessage[] }>(
    `/support/admin/conversations/${id}/messages`,
  );
export const sendSupportAdminReply = (id: string, text: string) =>
  api<SupportChatMessage>(`/support/admin/conversations/${id}/messages`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });
export const getSupportFaqItems = () =>
  api<SupportFaqItem[]>('/support/admin/faq');
export const createSupportFaqItem = (dto: {
  label: I18nString;
  answer: I18nString;
  roles?: SupportUserRole[];
  sortOrder?: number;
}) =>
  api<SupportFaqItem>('/support/admin/faq', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(dto),
  });
export const updateSupportFaqItem = (
  id: string,
  patch: Partial<{
    label: I18nString;
    answer: I18nString;
    roles: SupportUserRole[];
    sortOrder: number;
    isActive: boolean;
  }>,
) =>
  api<SupportFaqItem>(`/support/admin/faq/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(patch),
  });
export const deleteSupportFaqItem = (id: string) =>
  api<{ ok: boolean }>(`/support/admin/faq/${id}`, { method: 'DELETE' });

// E'tirozli mijozlar (haydovchidan AI orqali kelgan shikoyatlar)
export const getSupportComplaints = (status?: ComplaintStatus) =>
  api<CustomerComplaint[]>(
    `/support/admin/complaints${status ? `?status=${status}` : ''}`,
  );
export const resolveSupportComplaint = (id: string) =>
  api<CustomerComplaint>(`/support/admin/complaints/${id}/resolve`, { method: 'POST' });
export const dismissSupportComplaint = (id: string) =>
  api<CustomerComplaint>(`/support/admin/complaints/${id}/dismiss`, { method: 'POST' });

// Mijozni bloklash/blokdan chiqarish + mijozlarga xabar yuborish
export const getCustomer = (userId: string) =>
  api<AdminCustomer>(`/auth/admin/customers/${userId}`);
export const blockCustomer = (userId: string, reason: string) =>
  api<AdminCustomer>(`/auth/admin/customers/${userId}/block`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reason }),
  });
export const unblockCustomer = (userId: string) =>
  api<AdminCustomer>(`/auth/admin/customers/${userId}/unblock`, { method: 'PATCH' });
export const sendCustomerMessage = (dto: { customerId?: string; title?: string; body: string }) =>
  api<CustomerMessage>('/auth/admin/customers/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(dto),
  });
export const getCustomerMessages = () =>
  api<CustomerMessage[]>('/auth/admin/customers/messages');

export const getStoreOrders = (query: {
  status?: string;
  deliveryMethod?: string;
  from?: string;
  to?: string;
  q?: string;
  /** READY_FOR_PICKUP holatida 3 kundan ortiq turgan buyurtmalar. */
  overduePickup?: boolean;
  page?: number;
  pageSize?: number;
} = {}) => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value) params.set(key, String(value));
  }
  const qs = params.toString();
  return api<StoreOrdersPage>(`/store/admin/orders${qs ? `?${qs}` : ''}`);
};
export const completeStorePickup = (id: string) =>
  api<StoreOrder>(`/store/admin/orders/${id}/complete-pickup`, { method: 'POST' });
export const cancelStoreOrder = (id: string) =>
  api<StoreOrder>(`/store/admin/orders/${id}/cancel`, { method: 'POST' });
/** Holatni qo'lda o'zgartirish — server faqat ruxsat etilgan o'tishlarga yo'l qo'yadi. */
export const setStoreOrderStatus = (id: string, status: StoreOrderStatus) =>
  api<StoreOrder>(`/store/admin/orders/${id}/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });

/**
 * Rasmni serverga multipart yuklaydi. Server ImageKit sozlangan bo'lsa
 * CDN'ga, bo'lmasa lokal diskka saqlab, tayyor URL qaytaradi — frontend
 * uchun farqi yo'q.
 */
async function uploadImage(path: string, file: File): Promise<string> {
  const token = getToken();
  const form = new FormData();
  form.append('file', file);
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  const body = await res.json().catch(() => null);
  if (!res.ok || !body?.success) {
    throw new Error(body?.error?.message ?? body?.message ?? 'Rasm yuklashda xatolik');
  }
  return body.data.url as string;
}

export const uploadMarketImage = (file: File) => uploadImage('/market/upload', file);
export const uploadMarketplaceImage = (file: File) => uploadImage('/marketplace/upload', file);

// ----- Marketplace (Do'konlar + Qurilishda foydali) -----
export const getMarketplaceSellers = (sellerType?: SellerType) =>
  api<MarketplaceSeller[]>(
    `/marketplace/admin/sellers${sellerType ? `?sellerType=${sellerType}` : ''}`,
  );
export const createMarketplaceSeller = (body: CreateSellerInput) =>
  api<MarketplaceSeller>('/marketplace/admin/sellers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateMarketplaceSeller = (id: string, body: UpdateSellerInput) =>
  api<MarketplaceSeller>(`/marketplace/admin/sellers/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteMarketplaceSeller = (id: string) =>
  api<unknown>(`/marketplace/admin/sellers/${id}`, { method: 'DELETE' });

export const getMarketplaceCategories = (sellerType?: SellerType) =>
  api<MarketplaceCategory[]>(
    `/marketplace/admin/categories${sellerType ? `?sellerType=${sellerType}` : ''}`,
  );
export const createMarketplaceCategory = (body: {
  name: I18nString;
  sellerType: SellerType;
  sortOrder?: number;
}) =>
  api<MarketplaceCategory>('/marketplace/admin/categories', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateMarketplaceCategory = (
  id: string,
  body: { name?: I18nString; sortOrder?: number },
) =>
  api<MarketplaceCategory>(`/marketplace/admin/categories/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteMarketplaceCategory = (id: string) =>
  api<unknown>(`/marketplace/admin/categories/${id}`, { method: 'DELETE' });

// ----- Sotuvchi paneli kirish ma'lumoti (login/parol) -----
export const getSellerCredential = (sellerId: string) =>
  api<{ exists: boolean; username: string | null }>(
    `/auth/admin/seller-credentials/${sellerId}`,
  );
export const setSellerCredential = (
  sellerId: string,
  username: string,
  password: string,
  sellerType: SellerType,
) =>
  api<{ sellerId: string; username: string }>('/auth/admin/seller-credentials', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sellerId, username, password, sellerType }),
  });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/ /g, ' ').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('ru-RU');
}
