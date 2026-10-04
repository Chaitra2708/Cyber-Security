/**
 * SecureMart - Home page.
 * Hero + featured products (from MySQL via API) + categories + why-us.
 */
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../services/api.js';
import ProductCard from '../components/ProductCard.jsx';

const CAT_ICONS = {
  Beverages: '🥤',
  Snacks: '🍿',
  Bakery: '🥐',
  Produce: '🍎',
  Household: '🧼',
};

export default function Home() {
  const [featured, setFeatured] = useState([]);
  const [categories, setCategories] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const [p, c] = await Promise.all([
          api.products({ limit: 4, sort: 'newest' }),
          api.categories(),
        ]);
        if (alive) {
          setFeatured(p.products || []);
          setCategories(c.categories || []);
        }
      } catch (e) {
        if (alive) setError(e.message);
      }
    })();
    return () => { alive = false; };
  }, []);

  return (
    <>
      <section className="hero">
        <div className="container">
          <h1>SecureMart</h1>
          <p>Smart, secure and simple online shopping</p>
          <div className="hero-actions">
            <Link to="/products" className="btn btn-accent">Browse Products</Link>
            <Link to="/login" className="btn btn-outline">Login</Link>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <h2 className="section-title">Featured Products</h2>
          <p className="section-sub">Live catalogue loaded from the SecureMart database.</p>
          {error && <div className="error-box">Could not load products: {error}</div>}
          <div className="grid grid-4">
            {featured.map((p) => <ProductCard key={p.id} product={p} />)}
          </div>
          {featured.length > 0 && (
            <div style={{ textAlign: 'center', marginTop: 24 }}>
              <Link to="/products" className="btn btn-outline">View all products</Link>
            </div>
          )}
        </div>
      </section>

      <section className="section" style={{ background: '#eef2ff' }}>
        <div className="container">
          <h2 className="section-title">Categories</h2>
          <p className="section-sub">Browse the catalogue by department.</p>
          <div className="grid grid-4">
            {categories.map((c) => (
              <Link key={c.id} to={`/products?category=${c.slug}`} className="cat-tile">
                <div className="icon" aria-hidden="true">{CAT_ICONS[c.name] || '📦'}</div>
                <h4>{c.name}</h4>
                <span>{c.product_count} products</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <h2 className="section-title">Why SecureMart</h2>
          <p className="section-sub">Built as an academic demonstration of secure web design.</p>
          <div className="features">
            <div className="feature">
              <div aria-hidden="true">🔐</div>
              <h4>Secure by design</h4>
              <p>Passwords are hashed with bcrypt and every API call is authenticated with signed JWT tokens.</p>
            </div>
            <div className="feature">
              <div aria-hidden="true">🛡️</div>
              <h4>Enforced authorization</h4>
              <p>Role checks run on the server for every admin operation — never only in the browser.</p>
            </div>
            <div className="feature">
              <div aria-hidden="true">⚡</div>
              <h4>Real-time catalogue</h4>
              <p>Products, cart and orders are read live from MySQL through a REST API.</p>
            </div>
            <div className="feature">
              <div aria-hidden="true">📋</div>
              <h4>Audited actions</h4>
              <p>Sign-ins, order creation and admin changes are recorded in an audit trail.</p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
