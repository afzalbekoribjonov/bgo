import {
  NewPartnerApplication,
  PartnerApplication,
  PartnerStatus,
} from './partner.entity';

/**
 * Hamkorlik arizalari repository interfeysi (abstrakt).
 * Implementatsiya: PrismaPartnerRepository (PostgreSQL auth_db).
 */
export abstract class PartnerRepository {
  abstract create(data: NewPartnerApplication): Promise<PartnerApplication>;
  abstract findById(id: string): Promise<PartnerApplication | null>;
  abstract findByUser(userId: string): Promise<PartnerApplication[]>;
  abstract findAll(status?: PartnerStatus): Promise<PartnerApplication[]>;
  /** Foydalanuvchining ko'rib chiqilmagan (PENDING) arizasi (turi bo'yicha). */
  abstract findPending(
    userId: string,
    type: PartnerApplication['type'],
  ): Promise<PartnerApplication | null>;
  abstract updateStatus(
    id: string,
    status: PartnerStatus,
  ): Promise<PartnerApplication>;
}
