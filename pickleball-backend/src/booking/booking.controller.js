const bookingService = require("./booking.service");
const paymentOtpService = require('./paymentOtp.service');
const { successResponse, errorResponse } = require("../utils/response");

const allowedStatuses = ["PENDING", "CONFIRMED", "CANCELLED", "COMPLETED", "CHECKED_IN", "NO_SHOW"];

const getBookings = async (req, res) => {
  try { return successResponse(res, await bookingService.getBookings(), "Lấy danh sách booking thành công"); }
  catch (error) { return errorResponse(res, error.message, 500); }
};
const getMyBookings = async (req, res) => {
  try { return successResponse(res, await bookingService.getMyBookings(req.user.id), "Lấy lịch sử đặt sân thành công"); }
  catch (error) { return errorResponse(res, error.message, 500); }
};
const getBookingById = async (req, res) => {
  try {
    const booking = await bookingService.getBookingById(req.params.id);
    if (!booking) return errorResponse(res, "Không tìm thấy booking", 404);
    const userRole = String(req.user?.role || '').toUpperCase();
    const isPrivileged = ['ADMIN', 'STAFF'].includes(userRole);
    if (!isPrivileged && Number(booking.userId) !== Number(req.user?.id)) {
      return errorResponse(res, 'Bạn không có quyền xem booking này', 403);
    }
    return successResponse(res, booking, "Lấy chi tiết booking thành công");
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const createBooking = async (req, res) => {
  try {
    const { courtId, bookingDate, startTime, endTime, totalPrice, paymentMethod, voucherCode, extras } = req.body;
    if (!courtId || !bookingDate || !startTime || !endTime) return errorResponse(res, 'Thiếu thông tin booking', 400);
    const booking = await bookingService.createBooking({ userId: req.user.id, courtId, bookingDate, startTime, endTime, totalPrice, paymentMethod, voucherCode, extras: Array.isArray(extras) ? extras : [] });
    return successResponse(res, booking, 'Đặt sân thành công', 201);
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const requestPaymentOtp = async (req, res) => {
  try {
    const { method } = req.body;
    if (!method) return errorResponse(res, 'Thiếu phương thức thanh toán', 400);
    return successResponse(res, await paymentOtpService.requestPaymentOtp({ userId: req.user.id, method }), 'Đã gửi OTP thanh toán');
  } catch (error) { return errorResponse(res, error.message, 400); }
};
const verifyPaymentOtp = async (req, res) => {
  try {
    const { requestId, otp } = req.body;
    if (!requestId || !otp) return errorResponse(res, 'Thiếu requestId hoặc otp', 400);
    return successResponse(res, await paymentOtpService.verifyPaymentOtp({ userId: req.user.id, requestId, otp }), 'Xác nhận OTP thành công');
  } catch (error) { return errorResponse(res, error.message, 400); }
};

const updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!status) return errorResponse(res, "Thiếu trạng thái booking", 400);
    if (!allowedStatuses.includes(status)) return errorResponse(res, "Trạng thái booking không hợp lệ", 400);
    return successResponse(res, await bookingService.updateBookingStatus(req.params.id, status), "Cập nhật trạng thái booking thành công");
  } catch (error) { return errorResponse(res, error.message, 500); }
};
const checkInBooking = async (req,res)=>{ try { return successResponse(res, await bookingService.updateBookingStatus(req.params.id, 'CHECKED_IN'), 'Check-in thành công'); } catch(error){ return errorResponse(res,error.message,500); } };
const noShowBooking = async (req,res)=>{ try { return successResponse(res, await bookingService.updateBookingStatus(req.params.id, 'NO_SHOW'), 'Đánh dấu no-show thành công'); } catch(error){ return errorResponse(res,error.message,500); } };
const deleteBooking = async (req, res) => { try { await bookingService.deleteBooking(req.params.id); return successResponse(res, null, "Xóa booking thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };

module.exports = { getBookings, getMyBookings, getBookingById, createBooking, requestPaymentOtp, verifyPaymentOtp, updateBookingStatus, checkInBooking, noShowBooking, deleteBooking };
