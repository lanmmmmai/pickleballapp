import { useEffect, useState } from 'react';
import api from '../services/api';

const defaultForm = { title: '', description: '', videoUrl: '', category: 'GUIDE', isActive: true, sourceType: 'FILE' };

export default function VideosPage() {
  const [videos, setVideos] = useState([]);
  const [stats, setStats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState(defaultForm);
  const [thumbnailFile, setThumbnailFile] = useState(null);
  const [videoFile, setVideoFile] = useState(null);
  const [thumbnailPreview, setThumbnailPreview] = useState('');
  const [videoPreview, setVideoPreview] = useState('');

  const fetchVideos = async () => {
    try {
      setLoading(true); setError('');
      const [res, statsRes] = await Promise.all([api.get('/videos'), api.get('/videos/stats/list').catch(() => ({data:{data:[]}}))]);
      setVideos(res.data?.data || []);
      setStats(statsRes.data?.data || []);
    } catch (err) { console.error(err); setError(err.response?.data?.message || 'Không tải được danh sách video'); setVideos([]); }
    finally { setLoading(false); }
  };
  useEffect(() => { fetchVideos(); }, []);
  useEffect(() => { if (thumbnailFile) { const url = URL.createObjectURL(thumbnailFile); setThumbnailPreview(url); return () => URL.revokeObjectURL(url); } }, [thumbnailFile]);
  useEffect(() => { if (videoFile) { const url = URL.createObjectURL(videoFile); setVideoPreview(url); return () => URL.revokeObjectURL(url); } }, [videoFile]);

  const resetForm = () => { setForm(defaultForm); setThumbnailFile(null); setVideoFile(null); setThumbnailPreview(''); setVideoPreview(''); setEditingId(null); setShowForm(false); setError(''); };
  const handleChange = (e) => { const { name, value } = e.target; setForm((prev) => ({ ...prev, [name]: value })); };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (!form.title.trim()) { setError('Vui lòng nhập tiêu đề video'); return; }
    if (form.sourceType === 'FILE' && !videoFile && !editingId) { setError('Vui lòng chọn tệp video'); return; }
    if (form.sourceType === 'YOUTUBE' && !form.videoUrl.trim()) { setError('Vui lòng nhập link video'); return; }
    try {
      setSubmitting(true);
      const payload = new FormData();
      payload.append('title', form.title.trim());
      payload.append('description', form.description.trim());
      payload.append('category', form.category);
      payload.append('isActive', String(form.isActive));
      payload.append('sourceType', form.sourceType);
      if (form.sourceType === 'YOUTUBE') payload.append('videoUrl', form.videoUrl.trim());
      if (thumbnailFile) payload.append('thumbnail', thumbnailFile);
      if (videoFile) payload.append('video', videoFile);
      if (editingId) await api.put(`/videos/${editingId}`, payload, { headers: { 'Content-Type': 'multipart/form-data' } });
      else await api.post('/videos', payload, { headers: { 'Content-Type': 'multipart/form-data' } });
      resetForm();
      fetchVideos();
    } catch (err) { console.error(err); setError(err.response?.data?.message || 'Lưu video thất bại'); }
    finally { setSubmitting(false); }
  };

  const handleEdit = (video) => {
    setShowForm(true); setEditingId(video.id);
    setForm({ title: video.title || '', description: video.description || '', videoUrl: video.videoUrl || '', category: video.category || 'GUIDE', isActive: !!video.isActive, sourceType: video.sourceType || 'FILE' });
    setThumbnailFile(null); setVideoFile(null);
    setThumbnailPreview(video.thumbnailUrl ? `http://127.0.0.1:3000${video.thumbnailUrl}` : '');
    setVideoPreview(video.fileUrl ? `http://127.0.0.1:3000${video.fileUrl}` : '');
    setError('');
  };

  const handleDelete = async (id) => { if (!window.confirm('Bạn có chắc muốn xóa video này?')) return; try { await api.delete(`/videos/${id}`); fetchVideos(); } catch (err) { console.error(err); alert(err.response?.data?.message || 'Xóa video thất bại'); } };

  return <div className='page-wrap'>
    <div className='section-header'><h2>Quản lý video</h2><button className='primary-btn' onClick={() => showForm ? resetForm() : setShowForm(true)}>{showForm ? 'Đóng form' : 'Thêm video'}</button></div>
    {showForm && <div className='court-form-card'><h3>{editingId ? 'Sửa video' : 'Thêm video mới'}</h3>
      <form onSubmit={handleSubmit} className='court-form'>
        <div className='form-grid'>
          <div className='form-group'><label>Tiêu đề</label><input name='title' value={form.title} onChange={handleChange} /></div>
          <div className='form-group'><label>Danh mục</label><select name='category' value={form.category} onChange={handleChange}><option value='GUIDE'>GUIDE</option><option value='TECHNIQUE'>TECHNIQUE</option><option value='HIGHLIGHT'>HIGHLIGHT</option><option value='COACH'>FOOD</option></select></div>
        </div>
        <div className='form-grid'>
          <div className='form-group'><label>Nguồn video</label><select name='sourceType' value={form.sourceType} onChange={handleChange}><option value='FILE'>Tệp video</option><option value='YOUTUBE'>YouTube</option></select></div>
          <div className='form-group'><label>Trạng thái hiển thị</label><select value={String(form.isActive)} onChange={(e)=>setForm((prev)=>({...prev,isActive:e.target.value==='true'}))}><option value='true'>Hiển thị</option><option value='false'>Ẩn</option></select></div>
        </div>
        {form.sourceType === 'YOUTUBE' ? <div className='form-group'><label>Đường dẫn video</label><input name='videoUrl' value={form.videoUrl} onChange={handleChange} /></div> : <div className='form-group'><label>Tệp video</label><input type='file' accept='video/*' onChange={(e)=>setVideoFile(e.target.files?.[0] || null)} />{videoFile && <p>{videoFile.name}</p>}</div>}
        <div className='form-group'><label>Mô tả</label><textarea rows='5' name='description' value={form.description} onChange={handleChange} /></div>
        <div className='form-group'><label>Ảnh thumbnail</label><input type='file' accept='image/*' onChange={(e)=>setThumbnailFile(e.target.files?.[0] || null)} /></div>
        {thumbnailPreview && <img src={thumbnailPreview} alt='thumb' className='court-preview-image' />}
        {videoPreview && <video src={videoPreview} controls style={{width:'240px', borderRadius:'14px'}} />}
        {error && <div className='error-box'>{error}</div>}
        <div className='form-actions'><button type='submit' className='primary-btn' disabled={submitting}>{submitting ? 'Đang lưu...' : editingId ? 'Cập nhật video' : 'Tạo video'}</button></div>
      </form></div>}
    <div className='court-list-card'>
      {loading ? <p>Đang tải video...</p> : videos.map((video) => <div key={video.id} className='court-item-card'><h3>{video.title}</h3><p><strong>Nguồn:</strong> {video.sourceType}</p><p><strong>Lượt xem:</strong> {stats.find((s)=>s.id===video.id)?.viewsCount || 0}</p><p><strong>Thích:</strong> {stats.find((s)=>s.id===video.id)?.likesCount || 0}</p><p><strong>Bình luận:</strong> {stats.find((s)=>s.id===video.id)?.commentsCount || 0}</p>{video.thumbnailUrl && <img src={`http://127.0.0.1:3000${video.thumbnailUrl}`} alt={video.title} className='court-preview-image' />}{video.fileUrl && <video src={`http://127.0.0.1:3000${video.fileUrl}`} controls style={{width:'280px', borderRadius:'14px'}} />}<div className='court-actions'><button className='secondary-btn' onClick={()=>handleEdit(video)}>Sửa</button><button className='danger-btn' onClick={()=>handleDelete(video.id)}>Xóa</button></div></div>)}
      {error && <div className='error-box'>{error}</div>}
    </div>
  </div>;
}
