const paymentOtpService = require('./payment_method_otp.service');
const userService = require('./user.service');
const { successResponse, errorResponse } = require('../utils/response');

const allowedRoles = ['USER', 'STAFF', 'COACH', 'ADMIN'];

const getMe = async (req, res) => {
  try {
    const user = await userService.getCurrentUser(req.user.id);
    if (!user) return errorResponse(res, 'Không tìm thấy user', 404);
    return successResponse(res, user, 'Lấy thông tin cá nhân thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateAvatar = async (req, res) => {
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    if (!imageUrl) return errorResponse(res, 'Thiếu ảnh đại diện', 400);
    const updatedUser = await userService.updateCurrentUserAvatar(req.user.id, imageUrl);
    return successResponse(res, updatedUser, 'Cập nhật ảnh đại diện thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateCover = async (req, res) => {
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    if (!imageUrl) return errorResponse(res, 'Thiếu ảnh bìa', 400);
    const updatedUser = await userService.updateCurrentUserCover(req.user.id, imageUrl);
    return successResponse(res, updatedUser, 'Cập nhật ảnh bìa thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateMe = async (req, res) => {
  try {
    const { name, phone, paymentMethods } = req.body;
    const updatedUser = await userService.updateCurrentUser(req.user.id, {
      name,
      phone: phone || null,
      paymentMethods: Array.isArray(paymentMethods) ? paymentMethods : [],
    });
    return successResponse(res, updatedUser, 'Cập nhật thông tin cá nhân thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getUsers = async (req, res) => {
  try {
    const users = await userService.getUsers();
    return successResponse(res, users, 'Lấy danh sách user thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await userService.getUserById(req.params.id);
    if (!user) return errorResponse(res, 'Không tìm thấy user', 404);
    return successResponse(res, user, 'Lấy thông tin user thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const createUser = async (req, res) => {
  try {
    const { name, email, phone, password, role, emailVerified } = req.body;
    if (!name || !email || !password) return errorResponse(res, 'Thiếu tên, email hoặc mật khẩu', 400);
    if (role && !allowedRoles.includes(role)) return errorResponse(res, 'Role không hợp lệ', 400);
    const user = await userService.createUserByAdmin({
      name,
      email,
      phone: phone || null,
      password,
      role: role || 'USER',
      emailVerified: emailVerified ?? true,
    });
    return successResponse(res, user, 'Tạo tài khoản thành công', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateUser = async (req, res) => {
  try {
    const { name, email, phone, password, role, emailVerified } = req.body;
    if (!name || !email) return errorResponse(res, 'Thiếu tên hoặc email', 400);
    if (role && !allowedRoles.includes(role)) return errorResponse(res, 'Role không hợp lệ', 400);
    const updatedUser = await userService.updateUserInfo(req.params.id, {
      name,
      email,
      phone: phone || null,
      password: password || '',
      role: role || 'USER',
      emailVerified,
    });
    return successResponse(res, updatedUser, 'Cập nhật tài khoản thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    if (!role) return errorResponse(res, 'Thiếu role', 400);
    if (!allowedRoles.includes(role)) return errorResponse(res, 'Role không hợp lệ', 400);
    const updatedUser = await userService.updateUserRole(req.params.id, role);
    return successResponse(res, updatedUser, 'Cập nhật role thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateUserAvatarByAdmin = async (req, res) => {
  try {
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;
    if (!imageUrl) return errorResponse(res, 'Thiếu ảnh đại diện', 400);
    const updatedUser = await userService.updateUserAvatarByAdmin(req.params.id, imageUrl);
    return successResponse(res, updatedUser, 'Cập nhật avatar user thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteUserAvatarByAdmin = async (req, res) => {
  try {
    const updatedUser = await userService.removeUserAvatarByAdmin(req.params.id);
    return successResponse(res, updatedUser, 'Đã xóa avatar user');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteUser = async (req, res) => {
  try {
    await userService.deleteUser(req.params.id);
    return successResponse(res, null, 'Xóa user thành công');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const requestPaymentMethodOtp = async (req, res) => {
  try {
    const { method, account } = req.body;
    if (!method || !account) return errorResponse(res, 'Thiếu phương thức hoặc số tài khoản', 400);
    return successResponse(res, await paymentOtpService.requestPaymentMethodOtp({ userId: req.user.id, method, account }), 'Đã gửi OTP');
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
};

const verifyPaymentMethodOtp = async (req, res) => {
  try {
    const { requestId, otp } = req.body;
    if (!requestId || !otp) return errorResponse(res, 'Thiếu requestId hoặc otp', 400);
    return successResponse(res, await paymentOtpService.verifyPaymentMethodOtp({ userId: req.user.id, requestId, otp }), 'Xác thực phương thức thành công');
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
};

module.exports = {
  getMe,
  updateMe,
  updateAvatar,
  updateCover,
  getUsers,
  getUserById,
  createUser,
  updateUser,
  updateUserRole,
  updateUserAvatarByAdmin,
  deleteUserAvatarByAdmin,
  deleteUser,
  requestPaymentMethodOtp,
  verifyPaymentMethodOtp,
};
