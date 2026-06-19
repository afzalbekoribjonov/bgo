'use client';

import { useEffect, useState } from 'react';
import { getRestaurants } from '@/lib/api';
import type { Restaurant } from '@/lib/types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getRestaurants()
      .then(setRestaurants)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="container">
      <h1 className="h1">Oshxonalar</h1>
      {error && <p className="error">{error}</p>}
      {loading && <p className="muted">Yuklanmoqda…</p>}
      {!loading && !error && restaurants.length === 0 && (
        <p className="empty">Oshxona topilmadi</p>
      )}
      {!loading && restaurants.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Nomi</th>
              <th>Manzil</th>
              <th>Holat</th>
              <th>Reyting</th>
            </tr>
          </thead>
          <tbody>
            {restaurants.map((r) => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td>{r.address}</td>
                <td>
                  <span
                    className="badge"
                    style={{ background: r.isOpen ? '#2e7d32' : '#e53e3e' }}
                  >
                    {r.isOpen ? 'Ochiq' : 'Yopiq'}
                  </span>
                </td>
                <td>⭐ {r.rating.toFixed(1)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
