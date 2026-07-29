'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { getMyRestaurants } from '@/lib/api';
import type { Restaurant } from '@/lib/types';

export default function HomePage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getMyRestaurants()
      .then(setRestaurants)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="container">
      <h2 className="big" style={{ marginBottom: 16 }}>
        Oshxonangizni tanlang
      </h2>
      {loading && <p className="muted">Yuklanmoqda…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && restaurants.length === 0 && (
        <p className="empty">
          Sizga biriktirilgan oshxona yo&apos;q. Administrator bilan bog&apos;laning.
        </p>
      )}
      {restaurants.map((r) => (
        <Link key={r.id} href={`/restaurants/${r.id}/orders`} className="link">
          <div className="card">
            <div className="row">
              <div>
                <div className="title">{r.name}</div>
                <div className="muted">{r.address}</div>
              </div>
              <div className="muted">⭐ {r.rating.toFixed(1)} →</div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}
