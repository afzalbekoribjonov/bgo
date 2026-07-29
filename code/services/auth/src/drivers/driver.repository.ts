import {
  DriverMessageEntity,
  DriverProfileEntity,
  DriverProfilePatch,
  DriverTopupEntity,
  NewDriverMessage,
  NewDriverProfile,
} from './driver.entity';

/** Haydovchi profillari ombori (abstrakt). plan/03-databases.md */
export abstract class DriverRepository {
  abstract findAll(): Promise<DriverProfileEntity[]>;
  abstract findById(id: string): Promise<DriverProfileEntity | null>;
  abstract findByPhone(phone: string): Promise<DriverProfileEntity | null>;
  abstract findByUserId(userId: string): Promise<DriverProfileEntity | null>;
  abstract create(data: NewDriverProfile): Promise<DriverProfileEntity>;
  abstract update(
    id: string,
    patch: DriverProfilePatch,
  ): Promise<DriverProfileEntity>;
  abstract delete(id: string): Promise<void>;

  /**
   * Hisobni to'ldirish (balansga qo'shadi + tarix yozadi). `visible=false` —
   * haydovchiga ko'rsatilmaydigan tuzatish (masalan yashirin jarima qaytarish).
   */
  abstract topup(
    driverId: string,
    amount: number,
    note?: string,
    visible?: boolean,
  ): Promise<DriverProfileEntity>;
  /** Faqat haydovchiga ko'rinadigan yozuvlar (visible=true). */
  abstract listTopups(driverId: string): Promise<DriverTopupEntity[]>;

  // ---------- Xabarlar (admin → haydovchi) ----------

  abstract createMessage(data: NewDriverMessage): Promise<DriverMessageEntity>;
  /** Haydovchiga tegishli xabarlar (broadcast + shaxsiy), yangi birinchi. */
  abstract listMessagesFor(
    driverUserId: string,
    limit: number,
  ): Promise<DriverMessageEntity[]>;
  /** Admin tarixi — barcha yuborilganlar, yangi birinchi. */
  abstract listAllMessages(limit: number): Promise<DriverMessageEntity[]>;
  /** `since`dan keyingi (yoki hammasi, since null bo'lsa) xabarlar soni. */
  abstract countMessagesSince(
    driverUserId: string,
    since: Date | null,
  ): Promise<number>;
  /** Xabarlar o'qildi — messagesReadAt = hozir. */
  abstract markMessagesRead(profileId: string): Promise<void>;
}
