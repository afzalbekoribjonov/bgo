export type SellerType = 'SHOP' | 'CONSTRUCTION';

export interface Category {
  id: string;
  name: string;
  sortOrder: number;
}

export interface Product {
  id: string;
  sellerId: string;
  categoryId: string | null;
  sellerType: SellerType;
  name: string;
  description: string | null;
  price: number;
  imageUrls: string[];
  /** Mavjud o'lchamlar — bo'sh bo'lsa mahsulot o'lchamsiz. */
  sizes: string[];
  ratingAvg: number | null;
  sellerName: string;
  sellerContactPhone: string;
  sellerAddress: string | null;
  /** Mijozgacha masofa (km) — faqat joylashuv bilan so'ralganda. */
  distanceKm: number | null;
}

export interface SellerProfile {
  id: string;
  name: string;
  description: string | null;
  contactPhone: string;
  sellerType: SellerType;
  address: string | null;
  lat: number | null;
  lng: number | null;
  products: Product[];
}

export interface ChatThread {
  sellerId: string;
  sellerName: string;
  lastMessage: string;
  lastMessageAt: string;
}

export interface ChatMessage {
  id: string;
  sellerId: string;
  customerId: string;
  senderRole: 'CUSTOMER' | 'SELLER';
  text: string;
  seenAt: string | null;
  createdAt: string;
}
