import { DevicePlatform, DeviceToken } from './notification.types';

/** Qurilma tokenlari repository interfeysi (abstrakt). */
export abstract class DeviceTokenRepository {
  /** Token bo'yicha upsert (token unique — qayta ro'yxatda egasi yangilanadi). */
  abstract upsert(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceToken>;
  abstract findByUser(userId: string): Promise<DeviceToken[]>;
  /** Foydalanuvchi o'z tokenini o'chiradi (chiqish/qurilma almashtirish). */
  abstract deleteByToken(userId: string, token: string): Promise<void>;
  /** Eskirgan tokenni tozalash (FCM 404/410 qaytarganda). */
  abstract removeToken(token: string): Promise<void>;
}
