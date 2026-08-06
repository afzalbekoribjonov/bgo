export function NumInput({
  label,
  value,
  onChange,
  suffix,
  hint,
  decimal,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  suffix?: string;
  hint?: string;
  decimal?: boolean;
}) {
  return (
    <div>
      <label>
        {label}
        {suffix && (
          <span style={{ fontSize: 11.5, color: 'var(--text-muted)', marginLeft: 6 }}>
            ({suffix})
          </span>
        )}
      </label>
      <input
        value={value}
        inputMode={decimal ? 'decimal' : 'numeric'}
        onChange={(e) => onChange(decimal ? e.target.value.replace(/[^0-9.]/g, '') : e.target.value.replace(/\D/g, ''))}
        style={{ maxWidth: 240 }}
      />
      {hint && (
        <p style={{ fontSize: 12.5, color: 'var(--text-muted)', margin: '5px 0 0', lineHeight: 1.5 }}>
          {hint}
        </p>
      )}
    </div>
  );
}
