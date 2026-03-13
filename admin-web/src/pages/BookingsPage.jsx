import { useEffect, useMemo, useState } from "react";
import { io } from 'socket.io-client';
import api from "../services/api";

const socket = io('http://127.0.0.1:3000', { autoConnect: true });

export default function BookingsPage() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [search, setSearch] = useState("");

  const fetchBookings = async () => {
    try {
      setLoading(true);
      setError("");
      const res = await api.get("/bookings");
      setBookings(res.data?.data || []);
    } catch (err) {
      console.error(err);
      setError("Không tải được danh sách booking");
      setBookings([]);
    } finally { setLoading(false); }
  };

  useEffect(() => {
    fetchBookings();
    socket.emit('join:staff');
    const listener = () => fetchBookings();
    socket.on('booking:update', listener);
    return () => socket.off('booking:update', listener);
  }, []);

  const filteredBookings = useMemo(() => bookings.filter((booking) => {
    const matchesStatus = statusFilter === 'ALL' ? true : booking.status === statusFilter;
    const keyword = search.trim().toLowerCase();
    const matchesSearch = !keyword ? true : [booking.user?.name, booking.user?.email, booking.court?.name, booking.status].filter(Boolean).some((v) => String(v).toLowerCase().includes(keyword));
    return matchesStatus && matchesSearch;
  }), [bookings, statusFilter, search]);

  const handleChangeStatus = async (bookingId, status) => { try { await api.patch(`/bookings/${bookingId}/status`, { status }); } catch (err) { alert(err.response?.data?.message || 'Cập nhật trạng thái thất bại'); } };
  const handleCheckin = async (bookingId) => { try { await api.post(`/bookings/${bookingId}/checkin`); } catch (err) { alert(err.response?.data?.message || 'Check-in thất bại'); } };
  const handleNoShow = async (bookingId) => { try { await api.post(`/bookings/${bookingId}/no-show`); } catch (err) { alert(err.response?.data?.message || 'No-show thất bại'); } };
  const handleDeleteBooking = async (bookingId) => { if(!window.confirm('Bạn có chắc muốn xóa booking này?')) return; try { await api.delete(`/bookings/${bookingId}`); } catch (err) { alert(err.response?.data?.message || 'Xóa booking thất bại'); } };

  return <div className='page-wrap'>
    <div className='section-header'><h2>Quản lý booking realtime</h2></div>
    <div className='table-card'>
      <div className='form-row-2' style={{ marginBottom: 16 }}>
        <div className='form-group'><label>Tìm kiếm</label><input placeholder='Tìm theo user, email, sân...' value={search} onChange={(e)=>setSearch(e.target.value)} /></div>
        <div className='form-group'><label>Lọc trạng thái</label><select value={statusFilter} onChange={(e)=>setStatusFilter(e.target.value)}><option value='ALL'>Tất cả</option><option value='PENDING'>PENDING</option><option value='CONFIRMED'>CONFIRMED</option><option value='CHECKED_IN'>CHECKED_IN</option><option value='NO_SHOW'>NO_SHOW</option><option value='CANCELLED'>CANCELLED</option><option value='COMPLETED'>COMPLETED</option></select></div>
      </div>
      {error && <div className='error-box'>{error}</div>}
      {loading ? <p>Đang tải danh sách booking...</p> : filteredBookings.length === 0 ? <p>Chưa có booking nào</p> : <table><thead><tr><th>ID</th><th>Người đặt</th><th>Sân</th><th>Ngày đặt</th><th>Khung giờ</th><th>Tổng tiền</th><th>Trạng thái</th><th>Realtime</th><th>Thao tác</th></tr></thead><tbody>{filteredBookings.map((booking)=><tr key={booking.id}><td>{booking.id}</td><td>{booking.user?.name || '-'}</td><td>{booking.court?.name || '-'}</td><td>{booking.bookingDate ? new Date(booking.bookingDate).toLocaleDateString('vi-VN') : '-'}</td><td>{booking.startTime} - {booking.endTime}</td><td>{booking.totalPrice?.toLocaleString('vi-VN') || 0} VNĐ</td><td><select value={booking.status} onChange={(e)=>handleChangeStatus(booking.id,e.target.value)}><option value='PENDING'>PENDING</option><option value='CONFIRMED'>CONFIRMED</option><option value='CHECKED_IN'>CHECKED_IN</option><option value='NO_SHOW'>NO_SHOW</option><option value='CANCELLED'>CANCELLED</option><option value='COMPLETED'>COMPLETED</option></select></td><td style={{display:'flex',gap:8,flexWrap:'wrap'}}><button className='primary-btn' onClick={()=>handleCheckin(booking.id)}>Check-in</button><button className='danger-btn' onClick={()=>handleNoShow(booking.id)}>No-show</button></td><td><button className='danger-btn' onClick={()=>handleDeleteBooking(booking.id)}>Xóa</button></td></tr>)}</tbody></table>}
    </div>
  </div>;
}
