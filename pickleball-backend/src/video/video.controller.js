const videoService = require('./video.service');
const { successResponse, errorResponse } = require('../utils/response');
const { createAutoNotification } = require('../notification/notification.service');
const allowedCategories = ['GUIDE', 'TECHNIQUE', 'HIGHLIGHT', 'COACH'];

const getVideos = async (req,res)=>{ try { return successResponse(res, await videoService.getVideos(), 'Lấy danh sách video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const getVideoFeed = async (req,res)=>{ try { return successResponse(res, await videoService.getVideoFeed(null, req.query.q || ''), 'Lấy feed video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const getVideoById = async (req,res)=>{ try { const video=await videoService.getVideoById(req.params.id, req.user?.id || null); if(!video) return errorResponse(res,'Không tìm thấy video',404); return successResponse(res,video,'Lấy chi tiết video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };

const createVideo = async (req,res)=>{
  try {
    const { title, description, videoUrl, category, isActive, sourceType='YOUTUBE' } = req.body;
    if (!title) return errorResponse(res, 'Thiếu tiêu đề video', 400);
    if (sourceType === 'YOUTUBE' && !videoUrl) return errorResponse(res, 'Thiếu đường dẫn video', 400);
    if (sourceType === 'FILE' && !req.files?.video?.[0]) return errorResponse(res, 'Thiếu tệp video', 400);
    if (category && !allowedCategories.includes(category)) return errorResponse(res, 'Danh mục video không hợp lệ', 400);
    const thumbnailUrl = req.files?.thumbnail?.[0] ? `/uploads/${req.files.thumbnail[0].filename}` : null;
    const uploadedVideoPath = req.files?.video?.[0] ? `/uploads/${req.files.video[0].filename}` : null;
    const video = await videoService.createVideo({
      title,
      description: description || '',
      videoUrl: sourceType === 'YOUTUBE' ? videoUrl : null,
      fileUrl: sourceType === 'FILE' ? uploadedVideoPath : null,
      thumbnailUrl,
      category: category || 'GUIDE',
      isActive: String(isActive) === 'false' ? false : true,
      sourceType,
      status: 'APPROVED',
      createdBy: req.user?.id,
    });
    await createAutoNotification({ title: 'Video mới được gửi lên', content: `Bạn vừa gửi video ${title}.`, type: 'VIDEO', userId: req.user?.id || null });
    return successResponse(res, video, 'Tạo video thành công', 201);
  } catch(e){ return errorResponse(res,e.message,500);} };

const updateVideo = async (req,res)=>{ try {
  const payload = { ...req.body };
  if (req.files?.thumbnail?.[0]) payload.thumbnailUrl = `/uploads/${req.files.thumbnail[0].filename}`;
  if (req.files?.video?.[0]) { payload.fileUrl = `/uploads/${req.files.video[0].filename}`; payload.sourceType = 'FILE'; payload.videoUrl = null; }
  return successResponse(res, await videoService.updateVideo(req.params.id, payload), 'Cập nhật video thành công');
} catch(e){ return errorResponse(res,e.message,500);} };
const approveVideo = async (req,res)=>{ try { return successResponse(res, await videoService.updateVideo(req.params.id,{status:'APPROVED', isActive:true}), 'Duyệt video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const rejectVideo = async (req,res)=>{ try { return successResponse(res, await videoService.updateVideo(req.params.id,{status:'REJECTED', isActive:false}), 'Từ chối video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const deleteVideo = async (req,res)=>{ try { await videoService.deleteVideo(req.params.id); return successResponse(res,null,'Xóa video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const toggleLike = async (req,res)=>{ try { return successResponse(res, await videoService.toggleLike(req.params.id, req.user.id), 'Cập nhật thích thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const toggleSave = async (req,res)=>{ try { return successResponse(res, await videoService.toggleSave(req.params.id, req.user.id), 'Cập nhật lưu thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const addComment = async (req,res)=>{ try { if (!req.body.content?.trim()) return errorResponse(res,'Thiếu nội dung bình luận',400); return successResponse(res, await videoService.addComment(req.params.id, req.user.id, req.body.content.trim()), 'Bình luận thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const addView = async (req,res)=>{ try { return successResponse(res, await videoService.addView(req.params.id, req.user?.id || null), 'Ghi nhận lượt xem'); } catch(e){ return errorResponse(res,e.message,500);} };
const getStats = async (req,res)=>{ try { return successResponse(res, await videoService.getStats(), 'Lấy thống kê video thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
module.exports = { getVideos, getVideoFeed, getVideoById, createVideo, updateVideo, approveVideo, rejectVideo, deleteVideo, toggleLike, toggleSave, addComment, addView, getStats };
