export interface GeoPlace {
  id: string;
  areaId: string;
  label: string;
  lat: number;
  lng: number;
  category: string | null;
  sortOrder: number;
}

export interface ServiceArea {
  id: string;
  name: string;
  centerLat: number;
  centerLng: number;
  boundary: number[][][];
  isActive: boolean;
  places: GeoPlace[];
}

export interface CreateAreaInput {
  name: string;
  centerLat: number;
  centerLng: number;
  boundary: number[][][];
  isActive?: boolean;
}

/** 'farmland' — dehqonchilik maydoni: chiziq emas, yopiq yashil poligon. */
export type RoadKind = 'street' | 'main' | 'center' | 'farmland';

export interface MapRoad {
  id: string;
  areaId: string;
  name: string;
  kind: RoadKind;
  points: number[][]; // [[lat, lng], ...]
  isOneWay: boolean;
  isUnderConstruction: boolean;
  hasTrafficLight: boolean;
  isRestricted: boolean;
  speedLimit: number | null;
}

export interface CreateRoadInput {
  name: string;
  kind: RoadKind;
  points: number[][]; // [[lat, lng], ...]
  isOneWay?: boolean;
  isUnderConstruction?: boolean;
  hasTrafficLight?: boolean;
  isRestricted?: boolean;
  speedLimit?: number | null;
}

export interface UpdateRoadInput {
  name?: string;
  kind?: RoadKind;
  isOneWay?: boolean;
  isUnderConstruction?: boolean;
  hasTrafficLight?: boolean;
  isRestricted?: boolean;
  speedLimit?: number | null;
}

export type MarkerKind =
  | 'shop'
  | 'sticker'
  | 'construction'
  | 'traffic_light'
  | 'restriction'
  | 'farm';

export interface MapMarker {
  id: string;
  areaId: string;
  lat: number;
  lng: number;
  kind: MarkerKind;
  label: string | null;
  color: string | null;
}

export interface CreateMarkerInput {
  lat: number;
  lng: number;
  kind: MarkerKind;
  label?: string;
  color?: string;
}

export interface VerticalStat {
  count: number;
  revenue: number;
  profit: number;
}

export interface Stats {
  totalOrders: number;
  activeOrders: number;
  todayOrders: number;
  revenue: number;
  profit: number;
  byStatus: Record<string, number>;
  byVertical?: { food: VerticalStat; taxi: VerticalStat; parcel: VerticalStat };
}

export interface Tariff {
  id: string;
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
}

export interface PromoCode {
  id: string;
  code: string;
  type: 'PERCENT' | 'FIXED';
  value: number;
  minOrder: number;
  maxDiscount: number | null;
  active: boolean;
  usedCount: number;
}

export interface AdminOrder {
  id: string;
  publicNo: number;
  type: string;
  status: string;
  total: number;
  address: { text: string };
  createdAt: string;
  driverId?: string;
}

export interface Restaurant {
  id: string;
  name: string;
  address: string;
  isOpen: boolean;
  rating: number;
}

export interface AdminRestaurant {
  id: string;
  name: string;
  address: string;
  phone: string;
  lat: number;
  lng: number;
  isOpen: boolean;
  rating: number;
  status: 'ACTIVE' | 'PENDING' | 'BLOCKED';
  commissionPercent: number;
  ownerUserId: string | null;
  ownerPhone: string | null;
  ownerName: string | null;
  createdAt: string;
}

export interface OwnerCandidate {
  id: string;
  phone: string;
  fullName: string | null;
}

export interface CreateRestaurantInput {
  name: string;
  address: string;
  phone: string;
  commissionPercent?: number;
}

export interface UpdateRestaurantInput {
  name?: string;
  address?: string;
  phone?: string;
  lat?: number;
  lng?: number;
  isOpen?: boolean;
  commissionPercent?: number;
  status?: 'ACTIVE' | 'PENDING' | 'BLOCKED';
}

export interface MenuItemView {
  id: string;
  name: string;
  description: string | null;
  price: number;
  imageUrl: string | null;
  isAvailable: boolean;
}

export interface MenuCategoryView {
  id: string;
  name: string;
  items: MenuItemView[];
}

export interface RestaurantMenuView {
  restaurant: { id: string; name: string };
  categories: MenuCategoryView[];
}

export interface AdminDriver {
  id: string;
  userId: string;
  phone: string;
  fullName: string;
  age: number | null;
  carName: string | null;
  carYear: number | null;
  plateNumber: string | null;
  licenseInfo: string | null;
  loginCode: string;
  isActive: boolean;
  isOnline: boolean;
  /** Comfort tarifi yoqilganmi (faqat admin boshqaradi). */
  isComfort: boolean;
  balance: number;
  rating: number;
  /** Vaqtinchalik bloklash — o'tmishda/null bo'lsa bloklanmagan. */
  blockedUntil: string | null;
  blockReason: string | null;
  /** Ketma-ket bekor qilingan buyurtmalar soni. */
  consecutiveCancellations: number;
  createdAt: string;
  updatedAt: string;
}

/** Admin → haydovchi xabari (driverUserId null = hammaga yuborilgan). */
export interface AdminDriverMessage {
  id: string;
  driverUserId: string | null;
  title: string | null;
  body: string;
  createdAt: string;
}

export interface DriverOrderHistoryItem {
  id: string;
  publicNo?: number;
  type: 'FOOD' | 'TAXI' | 'PARCEL';
  status: string;
  total: number;
  earning: number;
  commission?: number;
  customerName?: string | null;
  customerPhone?: string | null;
  distanceKm?: number | null;
  durationMin?: number | null;
  createdAt: string;
  updatedAt?: string;
  address?: string | null;
  cancelledBy?: 'customer' | 'kitchen' | 'driver' | 'admin' | 'system';
  cancelledAt?: string;
  cancelReason?: string;
}

export interface DriverStats {
  period: 'today' | 'week' | 'month' | 'all';
  orders: number;
  earning: number;
  profit: number;
  cancelled?: number;
  byVertical?: {
    food: { orders: number; earning: number };
    taxi: { orders: number; earning: number };
    parcel: { orders: number; earning: number };
  };
}

export interface CreateDriverInput {
  phone: string;
  fullName: string;
  age?: number;
  carName?: string;
  carYear?: number;
  plateNumber?: string;
  licenseInfo?: string;
}

export interface UpdateDriverInput {
  fullName?: string;
  age?: number;
  carName?: string;
  carYear?: number;
  plateNumber?: string;
  licenseInfo?: string;
  isActive?: boolean;
  /** Comfort tarifi — faqat admin yoqadi/o'chiradi. */
  isComfort?: boolean;
  rating?: number;
}

export type ReportPeriod = 'today' | 'week' | 'month';

export interface ReportDayPoint {
  date: string; // YYYY-MM-DD
  orders: number;
  revenue: number;
  profit: number;
}

export interface Report {
  period: ReportPeriod;
  from: string;
  to: string;
  summary: {
    totalOrders: number;
    delivered: number;
    cancelled: number;
    revenue: number;
    profit: number;
    avgOrder: number;
  };
  daily: ReportDayPoint[];
  byVertical?: {
    food: { revenue: number; profit: number; delivered: number };
    taxi: { revenue: number; profit: number; delivered: number };
    parcel: { revenue: number; profit: number; delivered: number };
  };
}

/** Ixtiyoriy sana oralig'i hisoboti (istalgan kun/oy) — Report bilan bir xil, `period` yo'q. */
export interface ReportRange {
  from: string;
  to: string;
  summary: {
    totalOrders: number;
    delivered: number;
    cancelled: number;
    revenue: number;
    profit: number;
    avgOrder: number;
  };
  daily: ReportDayPoint[];
  byVertical: {
    food: { revenue: number; profit: number; delivered: number };
    taxi: { revenue: number; profit: number; delivered: number };
    parcel: { revenue: number; profit: number; delivered: number };
  };
}

export interface OrderStatusHistoryEntry {
  status: string;
  at: string;
  by?: 'customer' | 'kitchen' | 'driver' | 'admin' | 'system';
  driverId?: string;
  driverName?: string | null;
  reason?: string;
}

interface OrderDetailPerson {
  id: string;
  name: string | null;
  phone: string | null;
}

interface OrderDetailDriver extends OrderDetailPerson {
  car: string | null;
  plate: string | null;
}

/** Bitta buyurtmaning to'liq holati (alohida sahifa) — tur bo'yicha maydonlar farqlanadi. */
export interface OrderDetail {
  id: string;
  publicNo: number;
  type: 'FOOD' | 'TAXI' | 'PARCEL';
  status: string;
  createdAt: string;
  updatedAt: string;
  customer: OrderDetailPerson;
  driver: OrderDetailDriver | null;
  paymentType: string;
  rating: number | null;
  ratingComment: string | null;
  statusHistory: OrderStatusHistoryEntry[];

  // FOOD
  restaurant?: { id: string; name: string; address: string; lat: number; lng: number } | null;
  address?: { text: string; lat?: number; lng?: number };
  items?: { nameSnapshot: string; qty: number; priceSnapshot: number; markup: number; lineTotal: number }[];
  itemsTotal?: number;
  serviceFee?: number;
  deliveryFee?: number;
  courierEarning?: number;
  promoCode?: string | null;
  discount?: number;
  total?: number;
  kitchenAcceptedAt?: string | null;
  driverAcceptedAt?: string | null;

  // TAXI
  pickup?: { text: string; lat: number; lng: number };
  destination?: { text: string; lat: number; lng: number } | null;
  metered?: boolean;
  distanceKm?: number;
  pickupDistanceKm?: number;
  pickupSurcharge?: number;
  waitMinutes?: number;
  fare?: number;
  commission?: number;
  driverEarning?: number;

  // PARCEL
  size?: 'SMALL' | 'MEDIUM' | 'LARGE';
  recipientName?: string;
  recipientPhone?: string;
  note?: string | null;
}

export interface OrdersQuery {
  status?: string;
  type?: string;
  from?: string;
  to?: string;
  q?: string;
  sort?: 'createdAt' | 'total';
  order?: 'asc' | 'desc';
}

/** Jonli xaritadagi bitta haydovchi (admin). */
export interface LiveDriver {
  driverId: string;
  lat: number;
  lng: number;
  heading: number | null;
  busy: boolean;
  name: string | null;
  car: string | null;
  plate: string | null;
}

export interface LiveDrivers {
  counts: { online: number; busy: number; free: number };
  drivers: LiveDriver[];
}

// ----- Shubhali haydovchilar -----
export interface SuspiciousTrip {
  id: string;
  publicNo: number;
  type: 'FOOD' | 'TAXI' | 'PARCEL';
  distanceKm: number;
  durationMin: number;
  speedKmh: number | null;
  createdAt: string;
  driverId: string;
}

export interface SuspiciousDriverGroup {
  driverId: string;
  driverName: string | null;
  carName: string | null;
  plateNumber: string | null;
  flagCount: number;
  trips: SuspiciousTrip[];
}

/** Ketma-ket 3tadan ortiq bekor qilgan haydovchi (auth hisoblagichidan). */
export interface CancellationFlaggedDriver {
  driverId: string;
  driverName: string | null;
  carName: string | null;
  plateNumber: string | null;
  consecutiveCancellations: number;
}

export interface SuspiciousDriversResponse {
  speedFlagged: SuspiciousDriverGroup[];
  cancellationFlagged: CancellationFlaggedDriver[];
}

// ----- Market (Beshariq Market) -----
export interface I18nString {
  uz: string;
  uz_Cyrl?: string;
  ru?: string;
}

export interface MarketCategory {
  id: string;
  name: I18nString;
  sortOrder: number;
}

export interface MarketProduct {
  id: string;
  categoryId: string;
  name: I18nString;
  description: I18nString | null;
  price: number;
  stockQty: number;
  imageUrls: string[];
  /** Mavjud o'lchamlar — bo'sh bo'lsa mahsulot o'lchamsiz. */
  sizes: string[];
  likesCount: number;
  ratingAvg: number | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface MarketComment {
  id: string;
  productId: string;
  userId: string;
  text: string;
  createdAt: string;
}

export interface MarketPickupLocation {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  isActive: boolean;
}

export interface MarketSupportThread {
  customerId: string;
  lastMessage: string;
  lastMessageAt: string;
  unseenCount: number;
  /** Mijoz ism/telefoni — best-effort (auth servisi javob bermasa null). */
  customer: { fullName: string | null; phone: string } | null;
}

export interface MarketSupportMessage {
  id: string;
  customerId: string;
  senderRole: 'CUSTOMER' | 'SUPPORT';
  text: string;
  seenAt: string | null;
  createdAt: string;
}

export interface StoreOrderItem {
  productId: string;
  nameSnapshot: string;
  priceSnapshot: number;
  qty: number;
  lineTotal: number;
  /** Tanlangan o'lcham — mahsulot o'lchamsiz bo'lsa yo'q. */
  size?: string;
}

export type StoreOrderStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'ARRIVED'
  | 'PICKED_UP'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'READY_FOR_PICKUP'
  | 'COMPLETED'
  | 'CANCELLED';

export interface StoreOrderStatusEntry {
  status: StoreOrderStatus;
  at: string;
  by?: 'customer' | 'driver' | 'admin' | 'system';
  driverId?: string;
  reason?: string;
}

export interface StoreOrder {
  id: string;
  publicNo: number;
  customerId: string;
  driverId: string | null;
  pickupLocationId: string;
  deliveryMethod: 'DELIVERY' | 'PICKUP';
  address: { text: string; lat: number; lng: number } | null;
  items: StoreOrderItem[];
  itemsTotal: number;
  deliveryFee: number;
  courierEarning: number;
  total: number;
  status: StoreOrderStatus;
  statusHistory?: StoreOrderStatusEntry[];
  rating?: number;
  ratingComment?: string;
  /** Shu bosqichda admin o'tkaza oladigan holatlar (serverdan keladi). */
  allowedTransitions?: StoreOrderStatus[];
  /** Mijoz ism/telefoni — best-effort (auth servisi javob bermasa null). */
  customer?: { fullName: string | null; phone: string } | null;
  createdAt: string;
  updatedAt: string;
}

// ----- Marketplace (Do'konlar + Qurilishda foydali) -----
export type SellerType = 'SHOP' | 'CONSTRUCTION';

export interface MarketplaceSeller {
  id: string;
  name: string;
  description: string | null;
  contactPhone: string;
  sellerType: SellerType;
  /** Do'kon manzili — mijozga ko'rsatiladi va "eng yaqin birinchi" uchun. */
  address: string | null;
  lat: number | null;
  lng: number | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateSellerInput {
  name: string;
  description?: string;
  contactPhone: string;
  sellerType: SellerType;
  address?: string;
  lat?: number;
  lng?: number;
}

export interface UpdateSellerInput {
  name?: string;
  description?: string;
  contactPhone?: string;
  address?: string;
  lat?: number;
  lng?: number;
  isActive?: boolean;
}

export interface MarketplaceCategory {
  id: string;
  name: I18nString;
  sellerType: SellerType;
  sortOrder: number;
}

export interface MarketplaceProduct {
  id: string;
  sellerId: string;
  sellerName: string;
  categoryId: string | null;
  sellerType: SellerType;
  name: I18nString;
  description: I18nString | null;
  price: number;
  imageUrls: string[];
  ratingAvg: number | null;
  isActive: boolean;
  createdAt: string;
}

export type SupportUserRole = 'CUSTOMER' | 'DRIVER';
export type SupportConversationStatus = 'OPEN' | 'ESCALATED' | 'RESOLVED';
export type SupportSenderRole = 'USER' | 'BOT' | 'AI' | 'ADMIN' | 'SYSTEM';

export interface SupportConversation {
  id: string;
  userId: string;
  userRole: SupportUserRole;
  topic: string;
  topicLabel: string | null;
  status: SupportConversationStatus;
  createdAt: string;
  updatedAt: string;
  /** Foydalanuvchi ism/telefoni — best-effort (auth servisi javob bermasa null). */
  userInfo: { fullName: string | null; phone: string } | null;
}

export interface SupportChatMessage {
  id: string;
  conversationId: string;
  senderRole: SupportSenderRole;
  text: string;
  internalNote: string | null;
  createdAt: string;
}

export interface SupportFaqItem {
  id: string;
  roles: SupportUserRole[];
  label: I18nString;
  answer: I18nString;
  sortOrder: number;
  isActive: boolean;
}

export type ComplaintStatus = 'OPEN' | 'RESOLVED' | 'DISMISSED';

/** Haydovchidan AI orqali kelgan mijoz shikoyati (E'tirozli mijozlar). */
export interface CustomerComplaint {
  id: string;
  driverUserId: string;
  conversationId: string;
  orderPublicNo: number | null;
  orderType: 'FOOD' | 'TAXI' | 'PARCEL' | null;
  customerId: string | null;
  summary: string;
  status: ComplaintStatus;
  createdAt: string;
  updatedAt: string;
  driverInfo: { fullName: string | null; phone: string } | null;
  customerInfo: { fullName: string | null; phone: string } | null;
}

/** Admin → mijoz xabari (DriverMessage bilan bir xil naqsh). */
export interface CustomerMessage {
  id: string;
  customerId: string | null;
  title: string | null;
  body: string;
  createdAt: string;
}

/** Mijoz (block/unblock javobi) — auth UserEntity'ning admin ko'rinishi. */
export interface AdminCustomer {
  id: string;
  phone: string;
  fullName?: string;
  isBlocked: boolean;
  blockedReason?: string | null;
  blockedAt?: string | null;
  createdAt: string;
}

export interface PartnerApplication {
  id: string;
  phone: string;
  fullName: string;
  type: 'RESTAURANT' | 'DRIVER';
  note: string | null;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  createdAt: string;
}
