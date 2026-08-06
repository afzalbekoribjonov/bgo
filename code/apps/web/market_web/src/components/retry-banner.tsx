/** Ro'yxat yuklanmasa ko'rsatiladigan xato-holat — bitta bosishda qayta urinish. */
export default function RetryBanner({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <div className="empty">
      <div className="empty-icon">⚠️</div>
      <div className="empty-title">{message}</div>
      <div className="empty-desc">Internet aloqasini tekshiring</div>
      <button className="btn ghost btn-sm" style={{ marginTop: 14 }} onClick={onRetry}>
        🔄 Qayta urinish
      </button>
    </div>
  );
}
