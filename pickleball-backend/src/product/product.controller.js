const service = require('./product.service');
const { successResponse, errorResponse } = require('../utils/response');

const getProducts = async (req,res)=>{
  try { return successResponse(res, await service.getProducts(req.query.type), 'Lấy danh sách sản phẩm thành công'); }
  catch(e){ return errorResponse(res,e.message,500); }
};
const createProduct = async (req,res)=>{
  try {
    const body = { ...req.body };
    if (req.file) body.imageUrl = `/uploads/${req.file.filename}`;
    if (body.price !== undefined) body.price = Number(body.price);
    if (body.stock !== undefined) body.stock = Number(body.stock);
    if (body.coachUserId) body.coachUserId = Number(body.coachUserId);
    if (typeof body.priceSlots === 'string') {
      try { body.priceSlots = JSON.parse(body.priceSlots); } catch (_) { body.priceSlots = []; }
    }
    return successResponse(res, await service.createProduct(body), 'Tạo sản phẩm thành công', 201);
  } catch(e){ return errorResponse(res,e.message,500); }
};
const updateProduct = async (req,res)=>{
  try {
    const body = { ...req.body };
    if (req.file) body.imageUrl = `/uploads/${req.file.filename}`;
    if (body.price !== undefined) body.price = Number(body.price);
    if (body.stock !== undefined) body.stock = Number(body.stock);
    if (body.coachUserId) body.coachUserId = Number(body.coachUserId);
    if (typeof body.priceSlots === 'string') {
      try { body.priceSlots = JSON.parse(body.priceSlots); } catch (_) { body.priceSlots = []; }
    }
    return successResponse(res, await service.updateProduct(req.params.id, body), 'Cập nhật sản phẩm thành công');
  } catch(e){ return errorResponse(res,e.message,500); }
};
const deleteProduct = async (req,res)=>{
  try { await service.deleteProduct(req.params.id); return successResponse(res,null,'Xóa sản phẩm thành công'); }
  catch(e){ return errorResponse(res,e.message,500); }
};
module.exports = { getProducts, createProduct, updateProduct, deleteProduct };
