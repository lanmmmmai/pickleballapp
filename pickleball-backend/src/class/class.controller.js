const service = require('./class.service');
const { successResponse, errorResponse } = require('../utils/response');

const getClasses = async (req,res)=>{ try { return successResponse(res, await service.getClasses(), 'Lấy danh sách lớp thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const getMyClasses = async (req,res)=>{ try { return successResponse(res, await service.getMyClasses(req.user.id, req.user.role), 'Lấy lớp học của tôi thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const createClass = async (req,res)=>{ try { return successResponse(res, await service.createClass(req.body, req.user), 'Tạo lớp học thành công', 201); } catch(e){ return errorResponse(res,e.message,500);} };
const updateClass = async (req,res)=>{ try { return successResponse(res, await service.updateClass(req.params.id, req.body, req.user), 'Cập nhật lớp học thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const deleteClass = async (req,res)=>{ try { await service.deleteClass(req.params.id); return successResponse(res, null, 'Xóa lớp học thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
const enrollClass = async (req,res)=>{ try { const userId = req.body.userId || req.user.id; return successResponse(res, await service.enrollClass(req.params.id, userId), 'Thêm vào lớp học thành công', 201); } catch(e){ return errorResponse(res,e.message,500);} };
const removeEnrollment = async (req,res)=>{ try { await service.removeEnrollment(req.params.enrollmentId); return successResponse(res,null,'Xóa học viên khỏi lớp thành công'); } catch(e){ return errorResponse(res,e.message,500);} };
module.exports = { getClasses, getMyClasses, createClass, updateClass, deleteClass, enrollClass, removeEnrollment };
