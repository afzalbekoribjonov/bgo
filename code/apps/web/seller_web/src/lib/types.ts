export interface I18nString {
  uz: string;
  uz_Cyrl?: string;
  ru?: string;
}

export interface Product {
  id: string;
  sellerId: string;
  categoryId: string | null;
  sellerType: 'SHOP' | 'CONSTRUCTION';
  name: I18nString;
  description: I18nString | null;
  price: number;
  imageUrls: string[];
  /** Mavjud o'lchamlar — bo'sh bo'lsa mahsulot o'lchamsiz. */
  sizes: string[];
  ratingAvg: number | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Category {
  id: string;
  name: I18nString;
  sellerType: 'SHOP' | 'CONSTRUCTION';
  sortOrder: number;
}

export interface ChatThread {
  customerId: string;
  lastMessage: string;
  lastMessageAt: string;
  unseenCount: number;
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

export interface SellerProfile {
  id: string;
  name: string;
  description: string | null;
  contactPhone: string;
  sellerType: 'SHOP' | 'CONSTRUCTION';
  /** Do'kon manzili — mijozga ko'rsatiladi va "eng yaqin birinchi" uchun. */
  address: string | null;
  lat: number | null;
  lng: number | null;
  isActive: boolean;
}
