import { useMemo, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import api from '../services/api';
import { isAdminAuthenticated, saveAdminSession } from '../utils/adminSession';

const highlights = [
  'Quản lý sân, lớp học, video và thông báo tập trung',
  'Đăng nhập theo phiên để mỗi lần mở lại đều cần xác thực',
  'Giao diện gọn hơn, dễ nhìn hơn cho admin và staff',
];

export default function LoginPage() {
  const navigate = useNavigate();
  const authenticated = useMemo(() => isAdminAuthenticated(), []);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await api.post('/auth/login', { email: email.trim(), password });
      const token = res.data?.data?.token;
      const user = res.data?.data?.user;

      if (!token || !user) {
        throw new Error('Dữ liệu đăng nhập không hợp lệ');
      }

      if (user.role !== 'ADMIN' && user.role !== 'STAFF') {
        throw new Error('Tài khoản không có quyền vào admin');
      }

      saveAdminSession(token, user);
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Đăng nhập thất bại');
    } finally {
      setLoading(false);
    }
  };

  if (authenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <div className="login-page">
      <div className="login-hero">
        <div className="login-hero-badge">Admin Console</div>
        <h1>Tây Mỗ Pickleball Club</h1>
        <p>
          Khu vực quản trị dành cho admin và staff. Phiên đăng nhập chỉ lưu trong lần mở hiện tại,
          đóng trình duyệt xong sẽ cần đăng nhập lại để bảo mật hơn.
        </p>

        <div className="login-highlight-list">
          {highlights.map((item) => (
            <div key={item} className="login-highlight-item">
              <span>•</span>
              <strong>{item}</strong>
            </div>
          ))}
        </div>
      </div>

      <form className="login-card" onSubmit={handleLogin}>
        <div className="login-card-top">
          <div>
            <div className="login-kicker">Đăng nhập bảo mật</div>
            <h2>Xin chào quản trị viên</h2>
            <p>Nhập email và mật khẩu để vào trang quản trị.</p>
          </div>
          <div className="login-avatar">TM</div>
        </div>

        <div className="form-group">
          <label htmlFor="admin-email">Email quản trị</label>
          <input
            id="admin-email"
            type="email"
            placeholder="admin@email.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="username"
            required
          />
        </div>

        <div className="form-group">
          <label htmlFor="admin-password">Mật khẩu</label>
          <div className="password-field">
            <input
              id="admin-password"
              type={showPassword ? 'text' : 'password'}
              placeholder="Nhập mật khẩu"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
            />
            <button
              type="button"
              className="password-toggle"
              onClick={() => setShowPassword((prev) => !prev)}
              aria-label={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
            >
              {showPassword ? 'Ẩn' : 'Hiện'}
            </button>
          </div>
        </div>

        {error && <div className="error-box">{error}</div>}

        <button className="primary-btn login-submit-btn" type="submit" disabled={loading}>
          {loading ? 'Đang đăng nhập...' : 'Vào trang quản trị'}
        </button>

        <div className="login-footnote">
          Chỉ tài khoản có quyền <strong>ADMIN</strong> hoặc <strong>STAFF</strong> mới được truy cập.
        </div>
      </form>
    </div>
  );
}
