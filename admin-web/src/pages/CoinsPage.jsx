import { useEffect, useMemo, useState } from "react";
import api from "../services/api";

const taskDefault = { title:'', rewardType:'COIN', amount:'5', voucherId:'' };
const rewardDefault = { label:'', rewardType:'COIN', amount:'10', voucherId:'', weight:'1' };

export default function CoinsPage() {
  const [users, setUsers] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [rewards, setRewards] = useState([]);
  const [vouchers, setVouchers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [taskForm, setTaskForm] = useState(taskDefault);
  const [rewardForm, setRewardForm] = useState(rewardDefault);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError("");
      const results = await Promise.allSettled([
        api.get('/coins/users'),
        api.get('/coins/transactions'),
        api.get('/coins/tasks'),
        api.get('/spin/rewards'),
        api.get('/vouchers').catch(()=>({data:{data:[]}})),
      ]);
      const [usersRes, txRes, tasksRes, rewardsRes, vouchersRes] = results;
      setUsers(usersRes.status === 'fulfilled' ? usersRes.value.data?.data || [] : []);
      setTransactions(txRes.status === 'fulfilled' ? txRes.value.data?.data || [] : []);
      setTasks(tasksRes.status === 'fulfilled' ? tasksRes.value.data?.data || [] : []);
      setRewards(rewardsRes.status === 'fulfilled' ? rewardsRes.value.data?.data || [] : []);
      setVouchers(vouchersRes.status === 'fulfilled' ? vouchersRes.value.data?.data || [] : []);
      if (results.some((item) => item.status === 'rejected')) setError('Một phần dữ liệu không tải được');
    } catch (err) {
      console.error(err);
      setError('Không tải được dữ liệu coin');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);
  const totalCoin = useMemo(()=>users.reduce((sum,item)=> sum + Number(item.coin || 0),0), [users]);

  const submitTask = async (e) => {
    e.preventDefault();
    try {
      await api.post('/coins/tasks', taskForm);
      setTaskForm(taskDefault);
      fetchData();
    } catch (err) { setError(err.response?.data?.message || 'Tạo nhiệm vụ thất bại'); }
  };

  const submitReward = async (e) => {
    e.preventDefault();
    try {
      await api.post('/spin/rewards', rewardForm);
      setRewardForm(rewardDefault);
      fetchData();
    } catch (err) { setError(err.response?.data?.message || 'Tạo phần thưởng quay thất bại'); }
  };

  return <div className="page-wrap">
    <div className="section-header"><div><h2>Quản lý coin</h2><p>Tổng xu toàn hệ thống: <strong>{totalCoin}</strong></p></div></div>
    {error && <div className="error-box">{error}</div>}
    <div className="court-form-card"><h3>Thêm nhiệm vụ coin / voucher</h3><form className='court-form' onSubmit={submitTask}><div className='form-grid'><div className='form-group'><label>Tên nhiệm vụ</label><input value={taskForm.title} onChange={(e)=>setTaskForm({...taskForm,title:e.target.value})} placeholder='VD: Đăng nhập hằng ngày'/></div><div className='form-group'><label>Loại thưởng</label><select value={taskForm.rewardType} onChange={(e)=>setTaskForm({...taskForm,rewardType:e.target.value})}><option value='COIN'>Xu</option><option value='VOUCHER'>Voucher</option></select></div></div>{taskForm.rewardType === 'COIN' ? <div className='form-group'><label>Số xu</label><input type='number' value={taskForm.amount} onChange={(e)=>setTaskForm({...taskForm,amount:e.target.value})}/></div> : <div className='form-group'><label>Voucher</label><select value={taskForm.voucherId} onChange={(e)=>setTaskForm({...taskForm,voucherId:e.target.value})}><option value=''>-- Chọn voucher --</option>{vouchers.map(item => <option key={item.id} value={item.id}>{item.title} ({item.code})</option>)}</select></div>}<div className='form-actions'><button className='primary-btn'>Thêm nhiệm vụ</button></div></form></div>
    <div className="court-form-card"><h3>Spin mỗi ngày 1 lần</h3><form className='court-form' onSubmit={submitReward}><div className='form-grid'><div className='form-group'><label>Nhãn phần thưởng</label><input value={rewardForm.label} onChange={(e)=>setRewardForm({...rewardForm,label:e.target.value})} placeholder='VD: 10 xu'/></div><div className='form-group'><label>Loại thưởng</label><select value={rewardForm.rewardType} onChange={(e)=>setRewardForm({...rewardForm,rewardType:e.target.value})}><option value='COIN'>Xu</option><option value='VOUCHER'>Voucher</option><option value='NONE'>Không trúng</option></select></div></div><div className='form-grid'>{rewardForm.rewardType === 'COIN' ? <div className='form-group'><label>Số xu</label><input type='number' value={rewardForm.amount} onChange={(e)=>setRewardForm({...rewardForm,amount:e.target.value})}/></div> : rewardForm.rewardType === 'VOUCHER' ? <div className='form-group'><label>Voucher</label><select value={rewardForm.voucherId} onChange={(e)=>setRewardForm({...rewardForm,voucherId:e.target.value})}><option value=''>-- Chọn voucher --</option>{vouchers.map(item => <option key={item.id} value={item.id}>{item.title} ({item.code})</option>)}</select></div> : <div className='form-group'><label>Giá trị</label><input value='0' disabled /></div>}<div className='form-group'><label>Tỷ lệ lặp (weight)</label><input type='number' value={rewardForm.weight} onChange={(e)=>setRewardForm({...rewardForm,weight:e.target.value})}/></div></div><div className='form-actions'><button className='primary-btn'>Thêm phần thưởng spin</button></div></form></div>
    <div className="court-list-card"><h3>Nhiệm vụ coin</h3>{loading ? <p>Đang tải...</p> : tasks.length ? <div className="user-table-wrap"><table><thead><tr><th>Tên nhiệm vụ</th><th>Loại</th><th>Thưởng</th><th>Trạng thái</th><th></th></tr></thead><tbody>{tasks.map((item) => <tr key={item.id}><td>{item.title}</td><td>{item.rewardType}</td><td>{item.rewardType === 'VOUCHER' ? `Voucher #${item.voucherId}` : item.amount}</td><td>{item.claimed ? 'Đã nhận hôm nay' : 'Chưa nhận'}</td><td><button className='danger-btn' onClick={()=>api.delete(`/coins/tasks/${item.id}`).then(fetchData)}>Xóa</button></td></tr>)}</tbody></table></div> : <p>Chưa có nhiệm vụ</p>}</div>
    <div className="court-list-card"><h3>Phần thưởng spin</h3>{loading ? <p>Đang tải...</p> : rewards.length ? <div className="user-table-wrap"><table><thead><tr><th>Nhãn</th><th>Loại</th><th>Giá trị</th><th>Weight</th><th></th></tr></thead><tbody>{rewards.map((item) => <tr key={item.id}><td>{item.label}</td><td>{item.rewardType}</td><td>{item.rewardType === 'VOUCHER' ? `Voucher #${item.voucherId}` : item.amount}</td><td>{item.weight}</td><td><button className='danger-btn' onClick={()=>api.delete(`/spin/rewards/${item.id}`).then(fetchData)}>Xóa</button></td></tr>)}</tbody></table></div> : <p>Chưa có phần thưởng spin</p>}</div>
    <div className="court-list-card"><h3>Danh sách user và số xu</h3>{loading ? <p>Đang tải...</p> : <div className="user-table-wrap"><table><thead><tr><th>ID</th><th>Tên</th><th>Email</th><th>Role</th><th>Coin</th></tr></thead><tbody>{users.map((item) => <tr key={item.id}><td>{item.id}</td><td>{item.name}</td><td>{item.email}</td><td>{item.role}</td><td>{item.coin}</td></tr>)}</tbody></table></div>}</div>
    <div className="court-list-card"><h3>Lịch sử coin</h3>{loading ? <p>Đang tải...</p> : <div className="user-table-wrap"><table><thead><tr><th>User</th><th>Email</th><th>Amount</th><th>Loại</th><th>Ghi chú</th><th>Thời gian</th></tr></thead><tbody>{transactions.map((item) => <tr key={item.id}><td>{item.user?.name}</td><td>{item.user?.email}</td><td>{item.amount}</td><td>{item.type}</td><td>{item.note || '-'}</td><td>{new Date(item.createdAt).toLocaleString('vi-VN')}</td></tr>)}</tbody></table></div>}</div>
  </div>;
}
