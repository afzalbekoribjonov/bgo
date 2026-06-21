/** Saqlangan manzil. plan/05-customer-app.md */
export interface Address {
  id: string;
  userId: string;
  label: string;
  text: string;
  lat?: number;
  lng?: number;
  isDefault: boolean;
  createdAt: string;
}

export interface NewAddress {
  userId: string;
  label: string;
  text: string;
  lat?: number;
  lng?: number;
  isDefault: boolean;
}

export interface AddressPatch {
  label?: string;
  text?: string;
  lat?: number;
  lng?: number;
  isDefault?: boolean;
}
