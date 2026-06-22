export type DevicePlatform = 'android' | 'ios' | 'web';

export interface DeviceToken {
  id: string;
  userId: string;
  token: string;
  platform: DevicePlatform;
  createdAt: string;
}

/** Push xabar yuki (FCM notification + ixtiyoriy data). */
export interface NotificationPayload {
  title: string;
  body: string;
  /** FCM data — barcha qiymatlar string bo'lishi shart. */
  data?: Record<string, string>;
}

/** Yuborish natijasi (dev rejimda ham e2e tekshira oladi). */
export interface NotificationResult {
  delivered: number;
  channel: 'dev' | 'fcm' | 'none';
}
