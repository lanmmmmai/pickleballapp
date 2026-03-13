const service = require('./spin.service');
const { successResponse, errorResponse } = require('../utils/response');

const playSpin = async (req, res) => {
  try { return successResponse(res, await service.playSpin(req.user.id), 'Quay thưởng thành công'); }
  catch (error) { return errorResponse(res, error.message, 400); }
};
const getRewards = async (req,res)=>{ try { return successResponse(res, service.getRewards(), 'Lấy phần thưởng vòng quay thành công'); } catch(error){ return errorResponse(res,error.message,400);} };
const createReward = async (req,res)=>{ try { return successResponse(res, await service.createReward(req.body), 'Tạo phần thưởng thành công', 201); } catch(error){ return errorResponse(res,error.message,400);} };
const deleteReward = async (req,res)=>{ try { await service.deleteReward(req.params.id); return successResponse(res,null,'Xóa phần thưởng thành công'); } catch(error){ return errorResponse(res,error.message,400);} };
module.exports = { playSpin, getRewards, createReward, deleteReward };
