/**
 * SecureMart - Product card used on Home and Products pages.
 */
import { Link } from 'react-router-dom';

const EMOJI = {
  Beverages: '🥤',
  Snacks: '🍿',
  Bakery: '🥐',
  Produce: '🍎',
  Household: '🧼',
};

export default function ProductCard({ product }) {
  const emoji = EMOJI[product.category] || '🛒';
  return (
    <article className="card">
      <div className="card-media" aria-hidden="true">{emoji}</div>
      <div className="card-body">
        <span className="card-cat">{product.category}</span>
        <h3>{product.name}</h3>
        <p className="card-desc">
          {String(product.description || '').slice(0, 90)}
          {String(product.description || '').length > 90 ? '…' : ''}
        </p>
        <div className="card-meta">
          <span className="price">${Number(product.price).toFixed(2)}</span>
          <span className={`stock ${product.stock <= 10 ? 'low' : ''}`}>
            {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
          </span>
        </div>
        <Link to={`/products/${product.id}`} className="btn btn-block" style={{ marginTop: 10 }}>
          View Details
        </Link>
      </div>
    </article>
  );
}
