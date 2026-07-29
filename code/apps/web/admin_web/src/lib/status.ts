export const ORDER_STATUSES = [
  'PENDING',
  'ACCEPTED',
  'PREPARING',
  'READY',
  'ASSIGNED',
  'PICKED_UP',
  'DELIVERED',
  'CANCELLED',
] as const;

const LABELS: Record<string, string> = {
  PENDING: 'Yangi',
  ACCEPTED: 'Qabul qilindi',
  PREPARING: 'Tayyorlanmoqda',
  READY: 'Tayyor',
  ASSIGNED: 'Biriktirildi',
  ARRIVED: 'Yetib keldi',
  IN_PROGRESS: "Yo'lda",
  IN_TRANSIT: "Yo'lda",
  PICKED_UP: "Yo'lda",
  DELIVERED: 'Yetkazildi',
  COMPLETED: 'Yakunlandi',
  CANCELLED: 'Bekor qilindi',
  FAILED: 'Bajarilmadi',
};

const COLORS: Record<string, string> = {
  PENDING: '#ed8936',
  ACCEPTED: '#3182ce',
  PREPARING: '#3182ce',
  READY: '#2e7d32',
  ASSIGNED: '#3182ce',
  ARRIVED: '#0891b2',
  IN_PROGRESS: '#ed8936',
  IN_TRANSIT: '#ed8936',
  PICKED_UP: '#ed8936',
  DELIVERED: '#2e7d32',
  COMPLETED: '#2e7d32',
  CANCELLED: '#e53e3e',
  FAILED: '#e53e3e',
};

export const statusLabel = (s: string) => LABELS[s] ?? s;
export const statusColor = (s: string) => COLORS[s] ?? '#718096';
