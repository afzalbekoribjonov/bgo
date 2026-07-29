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
          '🛒'
        )}
        {!product.inStock ? (
          <span className="stock-tag out">Tugagan</span>
        ) : product.stockQty <= 5 ? (
          <span className="stock-tag">{product.stockQty} dona qoldi</span>
        ) : null}
      </div>
      <div className="product-card-body">
        <div className="product-card-name">{product.name}</div>
        <div className="product-card-price">{formatSom(product.price)}</div>
        <div className="product-card-meta">
          <span>❤️ {product.likesCount}</span>
          {product.ratingAvg ? <span>⭐ {product.ratingAvg.toFixed(1)}</span> : null}
          {product.sizes.length > 0 && <span>📏 {product.sizes.length}</span>}
        </div>
      </div>
    </Link>
  );
}
