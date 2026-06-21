export type PartnerType = 'RESTAURANT' | 'DRIVER';
export type PartnerStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

/** Hamkorlik arizasi. plan/08-admin-workspace.md */
export interface PartnerApplication {
  id: string;
  userId: string;
  phone: string;
  fullName: string;
  type: PartnerType;
  note?: string;
  status: PartnerStatus;
  createdAt: string;
  updatedAt: string;
}

export interface NewPartnerApplication {
  userId: string;
  phone: string;
  fullName: string;
  type: PartnerType;
  note?: string;
}
