import { useState } from 'react';
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { clearAdminSession, getAdminUser } from '../utils/adminSession';

const menuItems = [
  { path: '/dashboard', label: 'Dashboard' },
  { path: '/users', label: 'Users' },
  { path: '/products', label: 'Products' },
  { path: '/classes', label: 'Classes' },
  { path: '/bookings', label: 'Bookings' },
  { path: '/notifications', label: 'Notifications' },
  { path: '/videos', label: 'Videos' },
  { path: '/vouchers', label: 'Vouchers' },
  { path: '/coins', label: 'Coins' },
];

export default function AdminLayout() {
  const location = useLocation();
  const navigate = useNavigate();
  const user = getAdminUser();
  const [menuOpen, setMenuOpen] = useState(false);

  const handleLogout = () => {
    clearAdminSession();
    navigate('/login', { replace: true });
  };

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div>
          <div className="brand">Tây Mỗ Admin</div>
          <div className="sidebar-subtitle">Hệ thống quản trị sân pickleball</div>
        </div>

        <nav className="nav-menu">
          {menuItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={location.pathname === item.path ? 'nav-link active' : 'nav-link'}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="sidebar-account-card">
          <div className="sidebar-account-label">Tài khoản hiện tại</div>
          <strong>{user?.fullName || user?.name || 'Admin'}</strong>
          <span>{user?.email || 'Chưa có email'}</span>
          <span className="sidebar-role-chip">{user?.role || 'ADMIN'}</span>
        </div>
      </aside>

      <main className="content-area">
        <header className="topbar">
          <div>
            <h1>Admin Dashboard</h1>
            <div className="dashboard-subtitle">Bạn cần đăng nhập lại khi mở phiên quản trị mới.</div>
          </div>

          <div className="topbar-account-wrap">
            <button className="admin-badge admin-badge-button" onClick={() => setMenuOpen((v) => !v)}>
              <span>{user?.role || 'Admin'}</span>
              <span className="admin-badge-caret">▾</span>
            </button>
            {menuOpen && (
              <div className="topbar-account-menu">
                <div className="topbar-account-name">{user?.fullName || user?.name || 'Admin'}</div>
                <div className="topbar-account-email">{user?.email || 'Chưa có email'}</div>
                <button className="topbar-logout-btn" onClick={handleLogout}>Đăng xuất</button>
              </div>
            )}
          </div>
        </header>
        <section className="page-content">
          <Outlet />
        </section>
      </main>
    </div>
  );
}
