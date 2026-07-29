'use client';

import { useEffect, useState } from 'react';
import { getTariff, updateTariff } from '@/lib/api';
import { useToast } from '@/components/toast';
import type { Tariff } from '@/lib/types';

type Tab = 'food' | 'taxi' | 'parcel';

const TAB_ITEMS: { key: Tab; label: string; icon: string }[] = [
  { key: 'food', label: 'Ovqat', icon: '🍽️' },
  { key: 'taxi', label: 'Taksi', icon: '🚕' },
  { key: 'parcel', label: 'Dostavka', icon: '📦' },
];

function NumInput({
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

export default function TariffPage() {
  const toast = useToast();
  const [tab, setTab] = useState<Tab>('food');
  const [tariff, setTariff] = useState<Tariff | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // ----- Food fields -----
  const [deliveryFee, setDeliveryFee] = useState('');
  const [foodPct, setFoodPct] = useState('');
  const [courierPct, setCourierPct] = useState('');
  const [foodThreshold, setFoodThreshold] = useState('');
  const [foodFeeUnder, setFoodFeeUnder] = useState('');
  const [foodFeeOver, setFoodFeeOver] = useState('');

  // ----- Taxi fields -----
  const [taxiBase, setTaxiBase] = useState('');
  const [taxiPerKm, setTaxiPerKm] = useState('');
  const [taxiMin, setTaxiMin] = useState('');
  const [taxiPct, setTaxiPct] = useState('');
  const [taxiWait, setTaxiWait] = useState('');
  const [taxiWaitFree, setTaxiWaitFree] = useState('');
  const [pickupPerKm, setPickupPerKm] = useState('');
  const [pickupThreshold, setPickupThreshold] = useState('');
  const [comfortPerKm, setComfortPerKm] = useState('');
  const [comfortBase, setComfortBase] = useState('');

  // ----- Parcel fields -----
  const [parcelBase, setParcelBase] = useState('');
  const [parcelPerKm, setParcelPerKm] = useState('');
  const [parcelMin, setParcelMin] = useState('');
  const [parcelPct, setParcelPct] = useState('');

  useEffect(() => {
    setLoading(true);
    getTariff()
      .then((t) => {
        setTariff(t);
        setDeliveryFee(String(t.deliveryFee));
        setFoodPct(String(t.foodCommissionPercent));
        setCourierPct(String(t.courierSharePercent));
        setFoodThreshold(String(t.foodServiceThreshold));
        setFoodFeeUnder(String(t.foodServiceFeeUnder));
        setFoodFeeOver(String(t.foodServiceFeeOver));
        setTaxiBase(String(t.taxiBaseFare));
        setTaxiPerKm(String(t.taxiPerKm));
        setTaxiMin(String(t.taxiMinFare));
        setTaxiPct(String(t.taxiCommissionPercent));
        setTaxiWait(String(t.taxiWaitPerMin));
        setTaxiWaitFree(String(t.taxiWaitFreeMin));
        setPickupPerKm(String(t.taxiPickupSurchargePerKm));
        setPickupThreshold(String(t.taxiPickupSurchargeThresholdKm));
        setComfortPerKm(String(t.taxiComfortPerKmExtra ?? 500));
        setComfortBase(String(t.taxiComfortBaseExtra ?? 500));
        setParcelBase(String(t.parcelBaseFare));
        setParcelPerKm(String(t.parcelPerKm));
        setParcelMin(String(t.parcelMinFare));
        setParcelPct(String(t.parcelCommissionPercent));
      })
      .catch((e) => toast((e as Error).message, 'error'))
      .finally(() => setLoading(false));
  }, [toast]);

  async function save() {
    setSaving(true);
    try {
      const updated = await updateTariff({
        deliveryFee: parseInt(deliveryFee, 10) || 0,
        foodCommissionPercent: parseInt(foodPct, 10) || 0,
        courierSharePercent: parseInt(courierPct, 10) || 0,
        foodServiceThreshold: parseInt(foodThreshold, 10) || 0,
        foodServiceFeeUnder: parseInt(foodFeeUnder, 10) || 0,
        foodServiceFeeOver: parseInt(foodFeeOver, 10) || 0,
        taxiBaseFare: parseInt(taxiBase, 10) || 0,
        taxiPerKm: parseInt(taxiPerKm, 10) || 0,
        taxiMinFare: parseInt(taxiMin, 10) || 0,
        taxiCommissionPercent: parseInt(taxiPct, 10) || 0,
        taxiWaitPerMin: parseInt(taxiWait, 10) || 0,
        taxiWaitFreeMin: parseInt(taxiWaitFree, 10) || 0,
        taxiPickupSurchargePerKm: parseInt(pickupPerKm, 10) || 0,
        taxiPickupSurchargeThresholdKm: parseFloat(pickupThreshold) || 0,
        taxiComfortPerKmExtra: parseInt(comfortPerKm, 10) || 0,
        taxiComfortBaseExtra: parseInt(comfortBase, 10) || 0,
        parcelBaseFare: parseInt(parcelBase, 10) || 0,
        parcelPerKm: parseInt(parcelPerKm, 10) || 0,
        parcelMinFare: parseInt(parcelMin, 10) || 0,
        parcelCommissionPercent: parseInt(parcelPct, 10) || 0,
      });
      setTariff(updated);
      toast('Tariflar saqlandi ✓', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  // Live preview helpers
  const feeN = parseInt(deliveryFee, 10) || 0;
  const courierPctN = parseInt(courierPct, 10) || 0;
  const courierEarn = Math.round((feeN * courierPctN) / 100);
  const deliveryProfit = feeN - courierEarn;

  const foodThreshN = parseInt(foodThreshold, 10) || 0;
  const foodFeeUnderN = parseInt(foodFeeUnder, 10) || 0;
  const foodFeeOverN = parseInt(foodFeeOver, 10) || 0;

  const taxiBaseN = parseInt(taxiBase, 10) || 0;
  const taxiPerKmN = parseInt(taxiPerKm, 10) || 0;
  const sampleKm = 5;
  const sampleFare = Math.max(parseInt(taxiMin, 10) || 0, taxiBaseN + taxiPerKmN * sampleKm);

  const parcelBaseN = parseInt(parcelBase, 10) || 0;
  const parcelPerKmN = parseInt(parcelPerKm, 10) || 0;
  const sampleParcel = Math.max(parseInt(parcelMin, 10) || 0, parcelBaseN + parcelPerKmN * sampleKm);

  if (loading) {
    return (
      <div className="container">
        <div className="sk sk-title" style={{ width: '25%', marginBottom: 20 }} />
        <div className="card">
          <div className="card-body">
            {[...Array(6)].map((_, i) => (
              <div key={i} style={{ marginBottom: 18 }}>
                <div className="sk sk-line sk-line-sm" style={{ marginBottom: 8 }} />
                <div className="sk" style={{ height: 40, borderRadius: 8, maxWidth: 240 }} />
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!tariff) {
    return (
      <div className="container">
        <div className="card">
          <div className="empty">
            <div className="empty-icon">⚙️</div>
            <div className="empty-title">Tarif yuklanmadi</div>
            <div className="empty-desc">Backend bilan aloqani tekshiring</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Tariflar</h1>
          <p className="page-subtitle">Narxlar va komissiyalar boshqaruvi</p>
        </div>
        <button className="btn" disabled={saving} onClick={save}>
          {saving ? (
            <>
              <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
              Saqlanmoqda&hellip;
            </>
          ) : (
            "Hamma o'zgarishlarni saqlash"
          )}
        </button>
      </div>

      {/* Section tabs */}
      <div className="section-tabs" style={{ marginBottom: 20 }}>
        {TAB_ITEMS.map((t) => (
          <button
            key={t.key}
            className={`section-tab ${tab === t.key ? 'active' : ''}`}
            onClick={() => setTab(t.key)}
          >
            <span>{t.icon}</span>
            {t.label}
          </button>
        ))}
      </div>

      {/* ===== FOOD ===== */}
      {tab === 'food' && (
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          {/* Yetkazish */}
          <div className="card" style={{ flex: 1, minWidth: 280 }}>
            <div className="card-header">
              <span className="card-title">🚚 Yetkazib berish</span>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput
                  label="Yetkazib berish narxi"
                  value={deliveryFee}
                  onChange={setDeliveryFee}
                  suffix="so'm"
                  hint="Mijoz to'laydigan umumiy yetkazish narxi."
                />
                <NumInput
                  label="Kuryer ulushi"
                  value={courierPct}
                  onChange={setCourierPct}
                  suffix="%"
                />
                <NumInput
                  label="Oshxona komissiyasi (eski)"
                  value={foodPct}
                  onChange={setFoodPct}
                  suffix="%"
                  hint="Ovqat buyurtmasidan olinadigan platforma ulushi (%)."
                />
              </div>
              {/* Live preview */}
              <div
                style={{
                  marginTop: 16,
                  padding: '12px 14px',
                  background: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  fontSize: 13,
                  lineHeight: 1.8,
                }}
              >
                <div style={{ fontWeight: 700, marginBottom: 6, color: 'var(--text-2)' }}>
                  Jonli hisob
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Mijoz to&lsquo;laydi:{' '}
                  <b style={{ color: 'var(--text)' }}>
                    {feeN.toLocaleString('ru-RU')} so&lsquo;m
                  </b>
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Kuryer oladi:{' '}
                  <b style={{ color: 'var(--green)' }}>
                    {courierEarn.toLocaleString('ru-RU')} so&lsquo;m
                  </b>
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Platforma foydasi:{' '}
                  <b style={{ color: 'var(--primary)' }}>
                    {deliveryProfit.toLocaleString('ru-RU')} so&lsquo;m
                  </b>
                </div>
              </div>
            </div>
          </div>

          {/* Xizmat haqi (ustama) */}
          <div className="card" style={{ flex: 1, minWidth: 280 }}>
            <div className="card-header">
              <span className="card-title">💡 Xizmat haqi (ustama)</span>
            </div>
            <div className="card-body">
              <div
                className="info-block blue"
                style={{ marginBottom: 16, fontSize: 13, lineHeight: 1.6 }}
              >
                Har taomga qo&lsquo;shiladigan ustama — platforma yagona ovqat daromadi.
                Mijozga taom narxi ustiga qo&lsquo;shib ko&lsquo;rsatiladi; haydovchi
                balansidan yechiladi.
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput
                  label="Chegara narx"
                  value={foodThreshold}
                  onChange={setFoodThreshold}
                  suffix="so'm"
                  hint="Bu narxdan past va undan yuqori bo'yicha turli ustama."
                />
                <NumInput
                  label="Chegara va undan past uchun ustama"
                  value={foodFeeUnder}
                  onChange={setFoodFeeUnder}
                  suffix="so'm"
                />
                <NumInput
                  label="Chegaradan yuqori uchun ustama"
                  value={foodFeeOver}
                  onChange={setFoodFeeOver}
                  suffix="so'm"
                />
              </div>
              <div
                style={{
                  marginTop: 16,
                  padding: '12px 14px',
                  background: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  fontSize: 13,
                  lineHeight: 1.8,
                }}
              >
                <div style={{ fontWeight: 700, marginBottom: 6, color: 'var(--text-2)' }}>
                  Misol
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  15 000 so&lsquo;mlik taom →{' '}
                  <b style={{ color: 'var(--green)' }}>
                    +{foodFeeUnderN.toLocaleString('ru-RU')} so&lsquo;m
                  </b>{' '}
                  ustama
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  25 000 so&lsquo;mlik taom →{' '}
                  <b style={{ color: 'var(--primary)' }}>
                    +{foodFeeOverN.toLocaleString('ru-RU')} so&lsquo;m
                  </b>{' '}
                  ustama
                </div>
                <div style={{ color: 'var(--text-3)', marginTop: 4 }}>
                  Chegara:{' '}
                  <b style={{ color: 'var(--text)' }}>
                    {foodThreshN.toLocaleString('ru-RU')} so&lsquo;m
                  </b>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ===== TAXI ===== */}
      {tab === 'taxi' && (
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          {/* Asosiy */}
          <div className="card" style={{ flex: 1, minWidth: 280 }}>
            <div className="card-header">
              <span className="card-title">🚕 Asosiy taksi tariflari</span>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput label="Boshlang'ich haq" value={taxiBase} onChange={setTaxiBase} suffix="so'm" />
                <NumInput label="Har km uchun" value={taxiPerKm} onChange={setTaxiPerKm} suffix="so'm/km" />
                <NumInput label="Minimal haq" value={taxiMin} onChange={setTaxiMin} suffix="so'm" hint="Hisoblanganidan kichik bo'lsa minimal narx qo'llaniladi." />
                <NumInput label="Platforma komissiyasi" value={taxiPct} onChange={setTaxiPct} suffix="%" hint="Safar narxidan platforma ulushi (%)." />
              </div>
              <div
                style={{
                  marginTop: 16,
                  padding: '12px 14px',
                  background: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  fontSize: 13,
                  lineHeight: 1.8,
                }}
              >
                <div style={{ fontWeight: 700, marginBottom: 6, color: 'var(--text-2)' }}>
                  {sampleKm} km uchun misol
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Hisoblangan: {taxiBaseN.toLocaleString('ru-RU')} + {taxiPerKmN.toLocaleString('ru-RU')} × {sampleKm}
                  {' = '}<b>{(taxiBaseN + taxiPerKmN * sampleKm).toLocaleString('ru-RU')}</b>
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Safar narxi: <b style={{ color: 'var(--text)' }}>{sampleFare.toLocaleString('ru-RU')} so&lsquo;m</b>
                </div>
              </div>
            </div>
          </div>

          {/* Kutish va olib ketish */}
          <div className="card" style={{ flex: 1, minWidth: 280 }}>
            <div className="card-header">
              <span className="card-title">⏱️ Kutish va olib ketish</span>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput
                  label="Bepul kutish"
                  value={taxiWaitFree}
                  onChange={setTaxiWaitFree}
                  suffix="daqiqa"
                  hint="Haydovchi kelgach shu daqiqagacha bepul kutadi."
                />
                <NumInput
                  label="Pulli kutish narxi"
                  value={taxiWait}
                  onChange={setTaxiWait}
                  suffix="so'm/min"
                  hint="Bepul vaqtdan keyin har daqiqa uchun qo'shiladi."
                />
                <NumInput
                  label="Olib ketish ustamasi"
                  value={pickupPerKm}
                  onChange={setPickupPerKm}
                  suffix="so'm/km"
                  hint="Haydovchi siz bilan qo'shiladigan masofadan ko'p yursa har km uchun."
                />
                <NumInput
                  label="Ustama chegarasi"
                  value={pickupThreshold}
                  onChange={setPickupThreshold}
                  suffix="km"
                  decimal
                  hint="Bu masofadan oshiq yursagina olib ketish ustamasi qo'llaniladi."
                />
              </div>
            </div>
          </div>

          {/* Comfort tarifi ustamalari */}
          <div className="card" style={{ flex: 1, minWidth: 280 }}>
            <div className="card-header">
              <span className="card-title">👑 Comfort tarifi</span>
            </div>
            <div className="card-body">
              <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 14 }}>
                Comfort — admin yoqqan mashinalar uchun qimmatroq tarif.
                Bu ustamalar Start narxiga qo&apos;shiladi; Comfort buyurtmalar
                faqat Comfort belgilangan haydovchilarga boradi.
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput
                  label="Km ustamasi"
                  value={comfortPerKm}
                  onChange={setComfortPerKm}
                  suffix="so'm/km"
                  hint="Har km Start narxidan shuncha qimmat."
                />
                <NumInput
                  label="Boshlang'ich (yonish) ustamasi"
                  value={comfortBase}
                  onChange={setComfortBase}
                  suffix="so'm"
                  hint="Boshlang'ich haq Start'dan shuncha qimmat (minimal narxga ham qo'shiladi)."
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ===== PARCEL ===== */}
      {tab === 'parcel' && (
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          <div className="card" style={{ flex: 1, minWidth: 280, maxWidth: 480 }}>
            <div className="card-header">
              <span className="card-title">📦 Dostavka tariflari</span>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <NumInput label="Boshlang'ich haq" value={parcelBase} onChange={setParcelBase} suffix="so'm" />
                <NumInput label="Har km uchun" value={parcelPerKm} onChange={setParcelPerKm} suffix="so'm/km" />
                <NumInput label="Minimal haq" value={parcelMin} onChange={setParcelMin} suffix="so'm" hint="Hisoblangandan kichik bo'lsa minimal narx ishlatiladi." />
                <NumInput label="Platforma komissiyasi" value={parcelPct} onChange={setParcelPct} suffix="%" hint="Dostavka narxidan platforma ulushi (%)." />
              </div>
              <div
                style={{
                  marginTop: 16,
                  padding: '12px 14px',
                  background: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  fontSize: 13,
                  lineHeight: 1.8,
                }}
              >
                <div style={{ fontWeight: 700, marginBottom: 6, color: 'var(--text-2)' }}>
                  {sampleKm} km uchun misol (kichik baxmal)
                </div>
                <div style={{ color: 'var(--text-3)' }}>
                  Safar narxi: <b style={{ color: 'var(--text)' }}>{sampleParcel.toLocaleString('ru-RU')} so&lsquo;m</b>
                </div>
                <div style={{ color: 'var(--text-3)', marginTop: 4, fontSize: 12 }}>
                  O&lsquo;lcham koefitsienti: kichik &times;1 &middot; o&lsquo;rta &times;1.3 &middot; katta &times;1.6
                </div>
              </div>
            </div>
          </div>
          <div
            className="info-block amber"
            style={{ flex: 1, minWidth: 260, maxWidth: 400, alignSelf: 'flex-start' }}
          >
            <div style={{ fontWeight: 700, marginBottom: 6, fontSize: 13.5 }}>Eslatma</div>
            <p style={{ fontSize: 13, lineHeight: 1.7, margin: 0 }}>
              Dostavka narxi = max(minimal, boshlang&lsquo;ich + km &times; narx) &times; o&lsquo;lcham koefitsienti.
              Platforma komissiyasi yakuniy narxdan yechiladi.
            </p>
          </div>
        </div>
      )}

      {/* Save button bottom */}
      <div style={{ marginTop: 24, display: 'flex', gap: 12, alignItems: 'center' }}>
        <button className="btn" disabled={saving} onClick={save}>
          {saving ? (
            <>
              <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
              Saqlanmoqda&hellip;
            </>
          ) : (
            '💾 Hamma o&rsquo;zgarishlarni saqlash'
          )}
        </button>
        <span style={{ fontSize: 12.5, color: 'var(--text-muted)' }}>
          Barcha 3 bo&lsquo;limdagi o&lsquo;zgarishlar birga saqlanadi
        </span>
      </div>
    </div>
  );
}
