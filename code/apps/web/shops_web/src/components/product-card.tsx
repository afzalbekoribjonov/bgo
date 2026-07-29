'use client';

import Link from 'next/link';
import { formatSom } from '@/lib/api';
import type { Product } from '@/lib/types';

export default function ProductCard({ product }: { product: Product }) {
  return (
    <Link href={`/products/${product.id}`} className="product-card">
      <div className="product-card-img">
        {product.imageUrls[0] ? (
          <img src={product.imageUrls[0]} alt={product.name} />
        ) : (
          '🛍️'
        )}
      </div>
      <div className="product-card-body">
        <div className="product-card-name">{product.name}</div>
        <div className="product-card-price">{formatSom(product.price)}</div>
        <div className="product-card-meta">
          <span className="seller-name">🏪 {product.sellerName}</span>
          {product.distanceKm !== null && (
            <span className="dist-badge">{product.distanceKm} km</span>
          )}
        </div>
        {product.sizes.length > 0 && (
          <div className="product-card-meta">📏 {product.sizes.join(' · ')}</div>
        )}
      </div>
    </Link>
  );
}
