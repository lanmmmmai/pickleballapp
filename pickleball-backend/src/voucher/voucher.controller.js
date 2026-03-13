const voucherService = require("./voucher.service");
const { successResponse, errorResponse } = require("../utils/response");

const getVouchers = async (req, res) => { try { return successResponse(res, await voucherService.getVouchers(), "Lấy danh sách voucher thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
const createVoucher = async (req, res) => {
  try {
    const { code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive } = req.body;
    if (!code || !title || !discountType || !discountValue || coinCost === undefined || !startDate || !endDate) return errorResponse(res, "Thiếu thông tin voucher", 400);
    const data = await voucherService.createVoucher({ code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive });
    return successResponse(res, data, "Tạo voucher thành công", 201);
  } catch (error) { return errorResponse(res, error.message, 500); }
};
const redeemVoucher = async (req, res) => { try { return successResponse(res, await voucherService.redeemVoucher({ userId: req.user.id, voucherId: req.params.id }), 'Đổi voucher thành công'); } catch (error) { return errorResponse(res, error.message, 400); } };
const updateVoucher = async (req, res) => { try {
  const { code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive } = req.body;
  const data = await voucherService.updateVoucher(req.params.id, { code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive });
  return successResponse(res, data, "Cập nhật voucher thành công");
} catch (error) { return errorResponse(res, error.message, 500); } };
const deleteVoucher = async (req, res) => { try { await voucherService.deleteVoucher(req.params.id); return successResponse(res, null, "Xóa voucher thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
module.exports = { getVouchers, createVoucher, redeemVoucher, updateVoucher, deleteVoucher };
