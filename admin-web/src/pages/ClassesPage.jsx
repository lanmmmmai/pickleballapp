import { useEffect, useMemo, useState } from 'react';
import api from '../services/api';

const weekdaysList = ['Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','Chủ nhật'];
const defaultForm = { title:'', description:'', coachId:'', startDate:'', endDate:'', weekdays:[], sessionText:'', maxStudents:'20', status:'OPEN' };

const parseSchedule = (schedule) => {
  try {
    const parsed = JSON.parse(schedule || '{}');
    return {
      startDate: parsed.startDate || '',
      endDate: parsed.endDate || '',
      weekdays: Array.isArray(parsed.weekdays) ? parsed.weekdays : [],
      sessionText: parsed.sessionText || parsed.sessions || '',
    };
  } catch {
    return { startDate:'', endDate:'', weekdays:[], sessionText: schedule || '' };
  }
};

export default function ClassesPage() {
  const [classes, setClasses] = useState([]);
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState(defaultForm);
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const fetchData = async()=>{
    try {
      setLoading(true);
      const [cRes, uRes] = await Promise.all([api.get('/classes'), api.get('/users').catch(()=>({data:{data:[]}}))]);
      setClasses(cRes.data?.data||[]);
      setUsers(uRes.data?.data||[]);
      setError('');
    } catch { setError('Không tải được lớp học'); } finally { setLoading(false); }
  };
  useEffect(()=>{fetchData();},[]);

  const coachUsers = useMemo(()=>users.filter(u=>u.role==='COACH'), [users]);
  const studentUsers = useMemo(()=>users.filter(u=>u.role==='USER' || u.role === 'STAFF'), [users]);

  const reset = ()=>{ setForm(defaultForm); setEditingId(null); setShowForm(false); setError(''); };
  const submit = async(e)=>{
    e.preventDefault();
    try {
      const payload = { ...form };
      if (editingId) await api.put(`/classes/${editingId}`, payload); else await api.post('/classes', payload);
      reset(); fetchData();
    } catch(e){ setError(e.response?.data?.message||'Lưu lớp thất bại'); }
  };
  const editClass = (item)=>{
    const schedule = parseSchedule(item.schedule);
    setEditingId(item.id);
    setShowForm(true);
    setForm({
      title:item.title||'', description:item.description||'', coachId:String(item.coachId||item.coach?.id||''), startDate:schedule.startDate, endDate:schedule.endDate, weekdays:schedule.weekdays, sessionText:schedule.sessionText, maxStudents:String(item.maxStudents||20), status:item.status||'OPEN'
    });
  };
  const deleteClass = async(id)=>{ if(!window.confirm('Xóa lớp học này?')) return; await api.delete(`/classes/${id}`); fetchData(); };
  const addStudent = async(classId, userId)=>{ if(!userId) return; try { await api.post(`/classes/${classId}/enroll`, { userId }); fetchData(); } catch(e){ alert(e.response?.data?.message || 'Thêm học viên thất bại'); } };
  const removeEnrollment = async(id)=>{ if(!window.confirm('Xóa học viên này khỏi lớp?')) return; await api.delete(`/classes/enrollments/${id}`); fetchData(); };

  const toggleWeekday = (day)=> setForm((prev)=> ({ ...prev, weekdays: prev.weekdays.includes(day) ? prev.weekdays.filter((item)=>item!==day) : [...prev.weekdays, day] }));

  return <div className='page-wrap'>
    <div className='section-header'><h2>Classes</h2><button className='primary-btn' onClick={()=> showForm?reset():setShowForm(true)}>{showForm?'Đóng form':'Tạo lớp'}</button></div>
    {showForm && <div className='court-form-card'><form className='court-form' onSubmit={submit}><div className='form-grid'><div className='form-group'><label>Tiêu đề</label><input value={form.title} onChange={e=>setForm({...form,title:e.target.value})}/></div><div className='form-group'><label>Coach</label><select value={form.coachId} onChange={e=>setForm({...form,coachId:e.target.value})}><option value=''>-- Chọn coach --</option>{coachUsers.map(u=><option key={u.id} value={u.id}>{u.name}</option>)}</select></div></div><div className='form-group'><label>Mô tả</label><textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})}/></div><div className='form-grid'><div className='form-group'><label>Ngày bắt đầu</label><input type='date' value={form.startDate} onChange={e=>setForm({...form,startDate:e.target.value})}/></div><div className='form-group'><label>Ngày kết thúc</label><input type='date' value={form.endDate} onChange={e=>setForm({...form,endDate:e.target.value})}/></div></div><div className='form-group'><label>Học vào thứ nào trong tuần</label><div className='tab-filter-row'>{weekdaysList.map(day => <button type='button' key={day} className={form.weekdays.includes(day)?'filter-chip active':'filter-chip'} onClick={()=>toggleWeekday(day)}>{day}</button>)}</div></div><div className='form-grid'><div className='form-group'><label>Học mấy buổi / ghi chú lịch</label><input value={form.sessionText} onChange={e=>setForm({...form,sessionText:e.target.value})} placeholder='VD: 2 buổi/tuần 18:00 - 19:30'/></div><div className='form-group'><label>Số lượng tối đa</label><input type='number' value={form.maxStudents} onChange={e=>setForm({...form,maxStudents:e.target.value})}/></div></div>{error && <div className='error-box'>{error}</div>}<div className='form-actions'><button className='primary-btn'>{editingId?'Cập nhật lớp':'Lưu lớp'}</button></div></form></div>}
    <div className='court-list-card'>{loading? <p>Đang tải...</p> : classes.length === 0 ? <p>Chưa có lớp học</p> : classes.map(item => {
      const schedule = parseSchedule(item.schedule);
      return <div key={item.id} className='court-item-card compact-card'><div className='card-summary'><div className='card-summary-left'><h3>{item.title}</h3><p className='court-status'>{item.status}</p></div></div><div className='card-detail'><p><strong>Coach:</strong> {item.coach?.name || '-'}</p><p><strong>Ngày bắt đầu:</strong> {schedule.startDate || '-'}</p><p><strong>Ngày kết thúc:</strong> {schedule.endDate || '-'}</p><p><strong>Học thứ:</strong> {schedule.weekdays?.join(', ') || '-'}</p><p><strong>Lịch học:</strong> {schedule.sessionText || '-'}</p><p><strong>Mô tả:</strong> {item.description || '-'}</p><p><strong>Học viên:</strong> {(item.enrollments||[]).length}/{item.maxStudents}</p><div className='form-grid'><div className='form-group'><label>Thêm học viên</label><select defaultValue='' onChange={(e)=>{ if(e.target.value){ addStudent(item.id, Number(e.target.value)); e.target.value=''; } }}><option value=''>-- Chọn user --</option>{studentUsers.map(u=><option key={u.id} value={u.id}>{u.name} - {u.email}</option>)}</select></div></div>{(item.enrollments||[]).map(en=><div key={en.id} style={{display:'flex',justifyContent:'space-between',gap:12,alignItems:'center',marginBottom:8}}><span>{en.user?.name} - {en.user?.email}</span><button type='button' className='danger-btn' onClick={()=>removeEnrollment(en.id)}>Xóa học viên</button></div>)}</div><div className='card-summary-actions'><button className='secondary-btn' onClick={()=>editClass(item)}>Chỉnh sửa</button><button className='danger-btn' onClick={()=>deleteClass(item.id)}>Xóa</button></div></div>
    })}</div>
  </div>;
}
