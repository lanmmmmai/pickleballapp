import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import api from '../services/api';

const TYPES = ['COURT', 'BALL', 'RACKET', 'COACH'];
const TYPE_LABELS = { COURT: 'Sân', BALL: 'Bóng', RACKET: 'Vợt', COACH: 'Huấn luyện viên' };
const defaultForm = { name:'', description:'', type:'COURT', price:'', stock:'', status:'ACTIVE', coachUserId:'', openTime:'06:00', closeTime:'22:00', priceSlots:[{ startTime:'06:00', endTime:'15:00', price:'' }] };

export default function ProductsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const activeType = searchParams.get('type') || 'COURT';
  const [items, setItems] = useState([]);
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ ...defaultForm, type: activeType });
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [expandedId, setExpandedId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchData = useCallback(async ()=>{
    try {
      setLoading(true); setError('');
      const [productsRes, usersRes] = await Promise.all([
        api.get(`/products?type=${activeType}`),
        api.get('/users').catch(()=>({data:{data:[]}})),
      ]);
      setItems(productsRes.data?.data || []);
      setUsers((usersRes.data?.data || []).filter(u => ['COACH','ADMIN'].includes(u.role)));
    } catch (e) { setError(e.response?.data?.message || 'Không tải được sản phẩm'); }
    finally { setLoading(false); }
  }, [activeType]);
  useEffect(()=>{ fetchData(); },[fetchData]);
  useEffect(()=>{ setForm((prev)=>({ ...prev, type: activeType })); },[activeType]);

  const reset = ()=>{ setForm({ ...defaultForm, type: activeType }); setEditingId(null); setShowForm(false); setError(''); };
  const onSlotChange = (index, field, value) => setForm(prev => ({ ...prev, priceSlots: prev.priceSlots.map((slot, i) => i === index ? { ...slot, [field]: value } : slot) }));
  const addSlot = () => setForm(prev => ({ ...prev, priceSlots: [...prev.priceSlots, { startTime:'', endTime:'', price:'' }] }));
  const removeSlot = (index) => setForm(prev => ({ ...prev, priceSlots: prev.priceSlots.filter((_, i) => i !== index) }));

  const submit = async (e)=>{
    e.preventDefault();
    try {
      const payload = { ...form, type: form.type || activeType, priceSlots: form.type === 'COURT' ? form.priceSlots : [] };
      if (editingId) await api.put(`/products/${editingId}`, payload); else await api.post('/products', payload);
      reset(); fetchData();
    } catch (e) { setError(e.response?.data?.message || 'Lưu sản phẩm thất bại'); }
  };
  const edit = (item)=>{ setEditingId(item.id); setShowForm(true); setForm({ name:item.name||'', description:item.description||'', type:item.type||activeType, price:item.price||'', stock:item.stock||'', status:item.status||'ACTIVE', coachUserId:item.coachUserId||'', openTime:item.openTime||'06:00', closeTime:item.closeTime||'22:00', priceSlots:item.priceSlots?.length?item.priceSlots.map(slot=>({ startTime:slot.startTime||'', endTime:slot.endTime||'', price:slot.price||'' })):[{ startTime:'06:00', endTime:'15:00', price:item.price||'' }] }); };
  const remove = async(id)=>{ if(!window.confirm('Xóa mục này?')) return; try { await api.delete(`/products/${id}`); fetchData(); } catch (e) { alert(e.response?.data?.message || 'Xóa thất bại'); } };

  const titleLabel = useMemo(()=>TYPE_LABELS[activeType] || 'Sản phẩm', [activeType]);

  return <div className='page-wrap'>
    <div className='section-header'><h2>Danh sách {titleLabel.toLowerCase()}</h2><button className='primary-btn' onClick={()=> showForm?reset():setShowForm(true)}>{showForm?'Đóng form':`Thêm ${titleLabel.toLowerCase()}`}</button></div>
    <div className='tab-filter-row'>{TYPES.map(type => <button key={type} className={type===activeType?'filter-chip active':'filter-chip'} onClick={()=>setSearchParams({ type })}>{TYPE_LABELS[type]}</button>)}</div>
    {showForm && <div className='court-form-card'><h3>{editingId?'Sửa':'Thêm'} {titleLabel.toLowerCase()}</h3><form onSubmit={submit} className='court-form'>
      <div className='form-grid'>
        <div className='form-group'><label>Tên</label><input value={form.name} onChange={e=>setForm({...form,name:e.target.value})}/></div>
        <div className='form-group'><label>Loại</label><select value={form.type} onChange={e=>setForm({...form,type:e.target.value})}>{TYPES.map(type=><option key={type} value={type}>{TYPE_LABELS[type]}</option>)}</select></div>
      </div>
      <div className='form-group'><label>Mô tả</label><textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})}/></div>
      {form.type === 'COURT' ? <>
        <div className='form-grid'>
          <div className='form-group'><label>Giờ mở cửa</label><input type='time' value={form.openTime} onChange={e=>setForm({...form,openTime:e.target.value})}/></div>
          <div className='form-group'><label>Giờ đóng cửa</label><input type='time' value={form.closeTime} onChange={e=>setForm({...form,closeTime:e.target.value})}/></div>
        </div>
        <div className='form-group'><label>Khung giá theo giờ</label>
          {form.priceSlots.map((slot, index) => <div key={index} className='form-grid' style={{ marginBottom: 10 }}>
            <input type='time' value={slot.startTime} onChange={e=>onSlotChange(index,'startTime',e.target.value)} />
            <input type='time' value={slot.endTime} onChange={e=>onSlotChange(index,'endTime',e.target.value)} />
            <input type='number' placeholder='Giá' value={slot.price} onChange={e=>onSlotChange(index,'price',e.target.value)} />
            <button type='button' className='danger-btn' onClick={()=>removeSlot(index)} disabled={form.priceSlots.length===1}>Xóa</button>
          </div>)}
          <button type='button' className='secondary-btn' onClick={addSlot}>+ Thêm khung giá</button>
        </div>
      </> : <>
        <div className='form-grid'>
          <div className='form-group'><label>Giá</label><input type='number' value={form.price} onChange={e=>setForm({...form,price:e.target.value})}/></div>
          <div className='form-group'><label>Tồn kho</label><input type='number' value={form.stock} onChange={e=>setForm({...form,stock:e.target.value})}/></div>
        </div>
      </>}
      {form.type === 'COACH' && <div className='form-group'><label>Người phụ trách / NCC</label><select value={form.coachUserId} onChange={e=>setForm({...form,coachUserId:e.target.value})}><option value=''>-- chọn người phụ trách --</option>{users.map(u=><option key={u.id} value={u.id}>{u.name} - {u.email}</option>)}</select></div>}
      {error && <div className='error-box'>{error}</div>}
      <div className='form-actions'><button className='primary-btn' type='submit'>Lưu</button></div>
    </form></div>}
    <div className='court-list-card'>{loading? <p>Đang tải...</p> : items.length === 0 ? <p>Chưa có dữ liệu</p> : items.map(item => {
      const expanded = expandedId === item.id;
      return <div key={item.id} className='court-item-card compact-card'><div className='card-summary'><div className='card-summary-left'><h3>{item.name}</h3><p className='court-status'>{TYPE_LABELS[item.type] || item.type}</p></div></div>{expanded && <div className='card-detail'><p><strong>Giá:</strong> {item.price || 0}</p><p><strong>Tồn kho:</strong> {item.stock || 0}</p><p><strong>Trạng thái:</strong> {item.status}</p><p><strong>Mô tả:</strong> {item.description || '-'}</p>{item.openTime && <p><strong>Mở cửa:</strong> {item.openTime} - {item.closeTime}</p>}{item.priceSlots?.length ? <p><strong>Khung giá:</strong> {item.priceSlots.map((slot)=>`${slot.startTime}-${slot.endTime}: ${slot.price}`).join(' | ')}</p> : null}{item.coach && <p><strong>Người phụ trách:</strong> {item.coach.name} - {item.coach.email}</p>}</div>}<div className='card-summary-actions'><button className='secondary-btn' onClick={()=>setExpandedId(expanded ? null : item.id)}>{expanded ? 'Thu gọn' : 'Xem thêm'}</button><button className='secondary-btn' onClick={()=>edit(item)}>Sửa</button><button className='danger-btn' onClick={()=>remove(item.id)}>Xóa</button></div></div>
    })}</div>
  </div>;
}
