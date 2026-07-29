export type DevicePlatform = 'android' | 'ios' | 'web';

export interface DeviceToken {
  id: string;
  userId: string;
  token: string;
  platform: DevicePlatform;
  createdAt: string;
}

/** Android push yetkazish sozlamalari (yuqori muhimlik / to'liq ekran). */
export interface AndroidPushOptions {
  /** 'high' — ilova fonda/yopiq bo'lsa ham darhol uyg'otadi. */
  priority?: 'high' | 'normal';
  /** Local bildirishnoma kanali (ilova tomonda ko'rsatiladi). */
  channelId?: string;
  /**
   * true — FCM 'notification' bloki YUBORILMAYDI (faqat data). Shunda ilova
   * fonda/yopiq bo'lsa ham background handler ishlaydi va to'liq ekran (full
   * screen intent) bildirishnomani O'ZI ko'rsatadi. Yangi buyurtma signali shu.
   */
  dataOnly?: boolean;
}

/** Push xabar yuki (FCM notification + ixtiyoriy data). */
export interface NotificationPayload {
  title: string;
  body: string;
  /** FCM data — barcha qiymatlar string bo'lishi shart. */
  data?: Record<string, string>;
  /** Android maxsus yetkazish (yangi buyurtma — yuqori muhimlik, data-only). */
  android?: AndroidPushOptions;
}

/** Yuborish natijasi (dev rejimda ham e2e tekshira oladi). */
export interface NotificationResult {
  delivered: number;
  channel: 'dev' | 'fcm' | 'none';
}
