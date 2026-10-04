/**
 * SecureMart - Admin area layout (sidebar navigation).
 */
import { Outlet, NavLink, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  async function handleLogout() {
    await logout();
    navigate('/');
  }

  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="brand">SECURE<span>MART</span> Admin</div>
        <nav>
          <NavLink to="/admin" end>Dashboard</NavLink>
          <NavLink to="/admin/users">Users</NavLink>
          <NavLink to="/admin/products">Products</NavLink>
          <NavLink to="/admin/orders">Orders</NavLink>
          <NavLink to="/admin/security">Security</NavLink>
          <NavLink to="/">← Back to store</NavLink>
        </nav>
      </aside>

      <div className="admin-main">
        <div className="admin-topbar">
          <div>
            <h2>Administration</h2>
            <span style={{ color: 'var(--muted)', fontSize: '.88rem' }}>
              Signed in as {user?.name} ({user?.role})
            </span>
          </div>
          <div className="row-actions">
            <Link to="/" className="btn btn-outline btn-sm">View store</Link>
            <button className="btn btn-danger btn-sm" onClick={handleLogout}>Logout</button>
          </div>
        </div>
        <Outlet />
      </div>
    </div>
  );
}
