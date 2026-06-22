'use client';

import { useEffect, useState } from 'react';
import { getTariff, updateTariff } from '@/lib/api';
import type { Tariff } from '@/lib/types';

export default function TariffPage() {
  const [tariff, setTariff] = useState<Tariff | null>(null);
  const [fee, setFee] = useState('');
  const [pct, setPct] = useState('');
  const [courierPct, setCourierPct] = useState('');
  const [taxiBase, setTaxiBase] = useState('');
  const [taxiPerKm, setTaxiPerKm] = useState('');
  const [taxiMin, setTaxiMin] = useState('');
  const [taxiPct, setTaxiPct] = useState('');
  const [taxiWait, setTaxiWait] = useState('');
  const [parcelBase, setParcelBase] = useState('');
  const [parcelPerKm, setParcelPerKm] = useState('');
  const [parcelMin, setParcelMin] = useState('');
  const [parcelPct, setParcelPct] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    getTariff()
      .then((t) => {
        setTariff(t);
        setFee(String(t.deliveryFee));
        setPct(String(t.foodCommissionPercent));
        setCourierPct(String(t.courierSharePercent));
        setTaxiBase(String(t.taxiBaseFare));
        setTaxiPerKm(String(t.taxiPerKm));
        setTaxiMin(String(t.taxiMinFare));
        setTaxiPct(String(t.taxiCommissionPercent));
        setTaxiWait(String(t.taxiWaitPerMin));
        setParcelBase(String(t.parcelBaseFare));
        setParcelPerKm(String(t.parcelPerKm));
        setParcelMin(String(t.parcelMinFare));
        setParcelPct(String(t.parcelCommissionPercent));
      })
      .catch((e) => setError(e.message));
  }, []);

  async function save() {
    setLoading(true);
    setError(null);
    setSaved(false);
    try {
      const t = await updateTariff({
        deliveryFee: parseInt(fee, 10) || 0,
        foodCommissionPercent: parseInt(pct, 10) || 0,
        courierSharePercent: parseInt(courierPct, 10) || 0,
        taxiBaseFare: parseInt(taxiBase, 10) || 0,
        taxiPerKm: parseInt(taxiPerKm, 10) || 0,
        taxiMinFare: parseInt(taxiMin, 10) || 0,
        taxiCommissionPercent: parseInt(taxiPct, 10) || 0,
        taxiWaitPerMin: parseInt(taxiWait, 10) || 0,
        parcelBaseFare: parseInt(parcelBase, 10) || 0,
        parcelPerKm: parseInt(parcelPerKm, 10) || 0,
        parcelMinFare: parseInt(parcelMin, 10) || 0,
        parcelCommissionPercent: parseInt(parcelPct, 10) || 0,
      });
      setTariff(t);
      setSaved(true);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  const onlyDigits = (v: string) => v.replace(/[^0-9]/g, '');

  // Tarif tushuntirishi (jonli hisob)
  const feeNum = parseInt(fee, 10) || 0;
  const courierPctNum = parseInt(courierPct, 10) || 0;
  const courierEarn = Math.round((feeNum * courierPctNum) / 100);
  const deliveryProfit = feeNum - courierEarn;

  return (
    <div className="container">
      <h1 className="h1">Tariflar</h1>
      {error && <p className="error">{error}</p>}
      {!tariff && !error && <p className="muted">Yuklanmoqda…</p>}
      {tariff && (
        <div className="card" style={{ maxWidth: 480 }}>
          <label>Yetkazib berish narxi (so&apos;m)</label>
          <input
            value={fee}
            inputMode="numeric"
            onChange={(e) => setFee(e.target.value.replace(/[^0-9]/g, ''))}
          />
          <label style={{ marginTop: 12 }}>Oshxona komissiyasi (%)</label>
          <input
            value={pct}
            inputMode="numeric"
            onChange={(e) => setPct(e.target.value.replace(/[^0-9]/g, ''))}
          />
          <p className="muted" style={{ marginTop: 8 }}>
            Komissiya — har ovqat buyurtmasidan bizning ulush (foyda).
          </p>
          <label style={{ marginTop: 12 }}>Kuryer ulushi (%)</label>
          <input
            value={courierPct}
            inputMode="numeric"
            onChange={(e) =>
              setCourierPct(e.target.value.replace(/[^0-9]/g, ''))
            }
          />
          <p className="muted" style={{ marginTop: 8 }}>
            Yetkazib berish narxidan haydovchiga to&apos;lanadigan ulush. Qolgani —
            bizning yetkazish foydamiz.
          </p>
          <div
            className="muted"
            style={{
              marginTop: 12,
              padding: 10,
              borderRadius: 8,
              background: 'var(--surface-2, #f4f4f5)',
              fontSize: 13,
            }}
          >
            Har yetkazishda: haydovchi <b>{courierEarn.toLocaleString('ru-RU')}</b>{' '}
            so&apos;m, bizning yetkazish foydasi{' '}
            <b>{deliveryProfit.toLocaleString('ru-RU')}</b> so&apos;m.
          </div>
          <hr style={{ margin: '16px 0', border: 0, borderTop: '1px solid var(--border, #e5e5e5)' }} />
          <strong>🚕 Taksi tarifi</strong>
          <label style={{ marginTop: 12 }}>Boshlang&apos;ich haq (so&apos;m)</label>
          <input
            value={taxiBase}
            inputMode="numeric"
            onChange={(e) => setTaxiBase(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Har km uchun (so&apos;m)</label>
          <input
            value={taxiPerKm}
            inputMode="numeric"
            onChange={(e) => setTaxiPerKm(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Minimal haq (so&apos;m)</label>
          <input
            value={taxiMin}
            inputMode="numeric"
            onChange={(e) => setTaxiMin(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Platforma komissiyasi (%)</label>
          <input
            value={taxiPct}
            inputMode="numeric"
            onChange={(e) => setTaxiPct(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Pulli kutish (har daqiqa, so&apos;m)</label>
          <input
            value={taxiWait}
            inputMode="numeric"
            onChange={(e) => setTaxiWait(onlyDigits(e.target.value))}
          />
          <p className="muted" style={{ marginTop: 8 }}>
            Taksi haqi = max(minimal, boshlang&apos;ich + har km × masofa) + kutish
            haqi. Manzilsiz chaqirsa narx yakunda hisoblanadi.
          </p>
          <hr style={{ margin: '16px 0', border: 0, borderTop: '1px solid var(--border, #e5e5e5)' }} />
          <strong>📦 Dostavka tarifi</strong>
          <label style={{ marginTop: 12 }}>Boshlang&apos;ich haq (so&apos;m)</label>
          <input
            value={parcelBase}
            inputMode="numeric"
            onChange={(e) => setParcelBase(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Har km uchun (so&apos;m)</label>
          <input
            value={parcelPerKm}
            inputMode="numeric"
            onChange={(e) => setParcelPerKm(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Minimal haq (so&apos;m)</label>
          <input
            value={parcelMin}
            inputMode="numeric"
            onChange={(e) => setParcelMin(onlyDigits(e.target.value))}
          />
          <label style={{ marginTop: 12 }}>Platforma komissiyasi (%)</label>
          <input
            value={parcelPct}
            inputMode="numeric"
            onChange={(e) => setParcelPct(onlyDigits(e.target.value))}
          />
          <p className="muted" style={{ marginTop: 8 }}>
            O&apos;lcham koeffitsienti: kichik ×1, o&apos;rta ×1.3, katta ×1.6.
          </p>
          {saved && <p style={{ color: 'var(--green, green)' }}>Saqlandi ✓</p>}
          <button
            className="btn"
            style={{ marginTop: 12 }}
            disabled={loading}
            onClick={save}
          >
            {loading ? '...' : 'Saqlash'}
          </button>
        </div>
      )}
    </div>
  );
}
