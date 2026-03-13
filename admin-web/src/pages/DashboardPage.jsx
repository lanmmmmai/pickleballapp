import { useEffect, useMemo, useState } from "react";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, LineChart, Line, Legend } from "recharts";
import api from "../services/api";

const formatDateTime = (value) => (!value ? "-" : new Date(value).toLocaleString("vi-VN"));
const formatMoney = (value) => Number(value || 0).toLocaleString("vi-VN");
const getLast7Days = () => {
  const days = [];
  const now = new Date();
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    days.push({ key: d.toISOString().slice(0, 10), label: d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" }), bookings: 0, revenue: 0 });
  }
  return days;
};

export default function DashboardPage() {
  const [stats, setStats] = useState({ totalUsers: 0, totalCourts: 0, totalBookings: 0, totalNotifications: 0, totalVideos: 0, totalVouchers: 0, latestUsers: [], latestBookings: [] });
  const [bookings, setBookings] = useState([]);
  const [courts, setCourts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      setError("");
      const results = await Promise.allSettled([
        api.get('/dashboard/stats'),
        api.get('/bookings'),
        api.get('/courts'),
      ]);
      const [statsRes, bookingsRes, courtsRes] = results;
      const statsData = statsRes.status === 'fulfilled' ? statsRes.value.data?.data || {} : {};
      const bookingData = bookingsRes.status === 'fulfilled' ? bookingsRes.value.data?.data || [] : [];
      const courtsData = courtsRes.status === 'fulfilled' ? courtsRes.value.data?.data || [] : [];
      setStats({ totalUsers: statsData.totalUsers || 0, totalCourts: statsData.totalCourts || courtsData.length, totalBookings: statsData.totalBookings || bookingData.length, totalNotifications: statsData.totalNotifications || 0, totalVideos: statsData.totalVideos || 0, totalVouchers: statsData.totalVouchers || 0, latestUsers: statsData.latestUsers || [], latestBookings: statsData.latestBookings || [] });
      setBookings(bookingData);
      setCourts(courtsData);
      if (results.some((item) => item.status === 'rejected')) setError('Một phần dữ liệu dashboard không tải được');
    } catch (err) {
      console.error(err);
      setError('Không tải được dữ liệu dashboard');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDashboardData(); }, []);

  const chartData = useMemo(() => {
    const base = getLast7Days();
    bookings.forEach((booking) => {
      const rawDate = booking.bookingDate || booking.createdAt || booking.date || null;
      if (!rawDate) return;
      const found = base.find((item) => item.key === new Date(rawDate).toISOString().slice(0, 10));
      if (!found) return;
      found.bookings += 1;
      found.revenue += Number(booking.totalPrice || booking.price || 0);
    });
    return base;
  }, [bookings]);

  const bookingStatusData = useMemo(() => {
    const result = { PENDING: 0, CONFIRMED: 0, CANCELLED: 0, COMPLETED: 0 };
    bookings.forEach((booking) => { const status = booking.status || 'PENDING'; if (result[status] !== undefined) result[status] += 1; });
    return [{ name: 'Pending', value: result.PENDING }, { name: 'Confirmed', value: result.CONFIRMED }, { name: 'Cancelled', value: result.CANCELLED }, { name: 'Completed', value: result.COMPLETED }];
  }, [bookings]);

  const topCourts = useMemo(() => {
    const map = {};
    bookings.forEach((booking) => { const courtName = booking.court?.name || 'Không rõ sân'; map[courtName] = (map[courtName] || 0) + 1; });
    return Object.entries(map).map(([name, total]) => ({ name, total })).sort((a, b) => b.total - a.total).slice(0, 5);
  }, [bookings]);

  const availableCourts = useMemo(() => courts.filter((court) => court.status === 'AVAILABLE').length, [courts]);
  const maintenanceCourts = useMemo(() => courts.filter((court) => court.status === 'MAINTENANCE').length, [courts]);
  const totalRevenue = useMemo(() => bookings.reduce((sum, booking) => sum + Number(booking.totalPrice || booking.price || 0), 0), [bookings]);

  if (loading) return <div className="page-wrap"><div className="section-header"><h2>Dashboard</h2></div><div className="table-card"><p>Đang tải dữ liệu dashboard...</p></div></div>;

  return <div className="page-wrap">
    <div className="section-header"><div><h2>Dashboard</h2><p className="dashboard-subtitle">Tổng quan hệ thống quản lý Tây Mỗ Pickleball Club</p></div><button className="secondary-btn" onClick={fetchDashboardData}>Tải lại</button></div>
    {error && <div className="error-box">{error}</div>}
    <div className="dashboard-stats-grid">
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Tổng người dùng</span><h3>{stats.totalUsers || 0}</h3></div>
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Tổng sân</span><h3>{stats.totalCourts || 0}</h3></div>
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Tổng booking</span><h3>{stats.totalBookings || 0}</h3></div>
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Thông báo</span><h3>{stats.totalNotifications || 0}</h3></div>
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Video</span><h3>{stats.totalVideos || 0}</h3></div>
      <div className="dashboard-stat-card"><span className="dashboard-stat-label">Doanh thu</span><h3>{formatMoney(totalRevenue)}đ</h3></div>
    </div>
    <div className="dashboard-mini-grid">
      <div className="dashboard-mini-card"><span>Sân đang hoạt động</span><strong>{availableCourts}</strong></div>
      <div className="dashboard-mini-card"><span>Sân bảo trì</span><strong>{maintenanceCourts}</strong></div>
      <div className="dashboard-mini-card"><span>Voucher</span><strong>{stats.totalVouchers || 0}</strong></div>
      <div className="dashboard-mini-card"><span>Booking hoàn tất</span><strong>{bookingStatusData.find((item) => item.name === 'Completed')?.value || 0}</strong></div>
    </div>
    <div className="dashboard-chart-grid">
      <div className="table-card chart-card"><div className="card-head"><h3>Booking 7 ngày gần nhất</h3></div><div className="chart-box"><ResponsiveContainer width="100%" height={300}><BarChart data={chartData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="label" /><YAxis allowDecimals={false} /><Tooltip /><Legend /><Bar dataKey="bookings" name="Booking" radius={[8,8,0,0]} /></BarChart></ResponsiveContainer></div></div>
      <div className="table-card chart-card"><div className="card-head"><h3>Doanh thu 7 ngày gần nhất</h3></div><div className="chart-box"><ResponsiveContainer width="100%" height={300}><LineChart data={chartData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="label" /><YAxis /><Tooltip formatter={(value) => `${formatMoney(value)}đ`} /><Legend /><Line type="monotone" dataKey="revenue" name="Doanh thu" strokeWidth={3} /></LineChart></ResponsiveContainer></div></div>
    </div>
    <div className="dashboard-bottom-grid">
      <div className="table-card"><div className="card-head"><h3>Booking mới nhất</h3></div>{stats.latestBookings?.length ? <div className="dashboard-list">{stats.latestBookings.map((booking) => <div key={booking.id} className="dashboard-list-item"><div><strong>#{booking.id}</strong><p>{booking.user?.name || '-'} • {booking.court?.name || '-'}</p></div><div className="dashboard-list-meta"><span>{booking.status || '-'}</span><small>{formatDateTime(booking.createdAt)}</small></div></div>)}</div> : <p>Chưa có booking nào</p>}</div>
      <div className="table-card"><div className="card-head"><h3>User mới đăng ký</h3></div>{stats.latestUsers?.length ? <div className="dashboard-list">{stats.latestUsers.map((user) => <div key={user.id} className="dashboard-list-item"><div><strong>{user.name || 'Chưa có tên'}</strong><p>{user.email}</p></div><div className="dashboard-list-meta"><small>{formatDateTime(user.createdAt)}</small></div></div>)}</div> : <p>Chưa có user mới</p>}</div>
    </div>
    <div className="table-card" style={{ marginTop: 24 }}><div className="card-head"><h3>Top sân được đặt nhiều</h3></div>{topCourts.length ? <table><thead><tr><th>Tên sân</th><th>Số lượt đặt</th></tr></thead><tbody>{topCourts.map((court, index) => <tr key={`${court.name}-${index}`}><td>{court.name}</td><td>{court.total}</td></tr>)}</tbody></table> : <p>Chưa có dữ liệu thống kê sân</p>}</div>
    <div className="table-card" style={{ marginTop: 24 }}><div className="card-head"><h3>Thống kê trạng thái booking</h3></div><table><thead><tr><th>Trạng thái</th><th>Số lượng</th></tr></thead><tbody>{bookingStatusData.map((item) => <tr key={item.name}><td>{item.name}</td><td>{item.value}</td></tr>)}</tbody></table></div>
  </div>;
}
