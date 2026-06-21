export interface TelegramLink {
  phone: string;
  chatId: string;
  username?: string;
}

/** Telefon ↔ Telegram chat bog'lanishi repository (abstrakt). */
export abstract class TelegramRepository {
  abstract findByPhone(phone: string): Promise<TelegramLink | null>;
  abstract upsert(data: TelegramLink): Promise<TelegramLink>;
}
