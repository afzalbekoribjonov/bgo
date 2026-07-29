import { NewParcelMessage, ParcelMessage } from './entities';

/** Dostavka suhbat xabarlari repository interfeysi (abstrakt). */
export abstract class ParcelMessageRepository {
  abstract listByParcel(parcelId: string): Promise<ParcelMessage[]>;
  abstract countByParcel(parcelId: string): Promise<number>;
  abstract create(data: NewParcelMessage): Promise<ParcelMessage>;
  /** Dostavka yakunlanganda suhbatni o'chirish (saqlanib qolmasligi uchun). */
  abstract deleteByParcel(parcelId: string): Promise<void>;
}
