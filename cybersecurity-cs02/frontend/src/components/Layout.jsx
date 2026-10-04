/**
 * SecureMart - Public/customer layout with responsive header, nav, footer.
 * Also shows a live Backend connection badge (GET /api/health).
 */
import { useEffect, useState } from 'react';
import { Outlet, NavLink, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

function HealthBadge() {
  const [state, setState] = useState('checking');
  useEffect(() => {
    let alive = true;
    async function ping() {
      try {
        const res = await fetch('/api/health');
        const data = await res.json();
        if (alive) setState(data && data.status === 'ok' ? 'ok' : 'bad');
      } catch {
        if (alive) setState('bad');
      }
    }
    ping();
    const t = setInterval(ping, 15000);
    return () => { alive = false; clearInterval(t); };
  }, []);
  if (state === 'checking') return null;
  return (
    <span className={`badge-conn ${state === 'ok' ? 'conn-ok' : 'conn-bad'}`}>
      Backend: {state === 'ok' ? 'Connected' : 'Disconnected'}
    </span>
  );
}

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  async function handleLogout() {
    await logout();
    navigate('/');
  }

  return (
    <>
      <header className="site-header">
        <div className="container header-inner">
          <Link to="/" className="logo">SECURE<span>MART</span></Link>
          <nav className="main-nav">
            <NavLink to="/" end>Home</NavLink>
            <NavLink to="/products">Products</NavLink>
            {user && <NavLink to="/dashboard">Dashboard</NavLink>}
            {user && <NavLink to="/cart">Cart</NavLink>}
            {user && <NavLink to="/orders">Orders</NavLink>}
            {user && user.role === 'admin' && <NavLink to="/admin">Admin</NavLink>}

            {!user && <NavLink to="/login">Login</NavLink>}
            {!user && <NavLink to="/register">Register</NavLink>}

            {user && (
              <>
                <span className="nav-divider" />
                <NavLink to="/profile">{user.name?.split(' ')[0] || 'Account'}</NavLink>
                <button className="btn btn-outline btn-sm" onClick={handleLogout}>Logout</button>
              </>
            )}
            <HealthBadge />
          </nav>
        </div>
      </header>

      <main>
        <Outlet />
      </main>

      <footer className="site-footer">
        <div className="container footer-inner">
          <div>
            <strong>SecureMart</strong>
            <p style={{ margin: '6px 0 0', fontSize: '.85rem' }}>
              Fictional marketplace built for the CS-02 academic security laboratory.
              All data is synthetic.
            </p>
          </div>
          <div>
            <strong>Explore</strong>
            <Link to="/">Home</Link>
            <Link to="/products">Products</Link>
            <Link to="/register">Create account</Link>
          </div>
          <div>
            <strong>Laboratory</strong>
            <span style={{ fontSize: '.85rem' }}>Local use only · No real payments</span>
            <span style={{ fontSize: '.85rem' }}>No real personal data</span>
          </div>
        </div>
      </footer>
    </>
  );
}
