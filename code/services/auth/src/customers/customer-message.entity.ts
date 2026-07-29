/** Admin → mijoz xabari (customerId null = hammaga). */
export interface CustomerMessageEntity {
  id: string;
  customerId?: string | null;
  title?: string | null;
  body: string;
  createdAt: string;
}

/** Yangi xabar (repo). */
export interface NewCustomerMessage {
  customerId?: string | null;
  title?: string | null;
  body: string;
}
