const notificationService = require("./notification.service");
const { successResponse, errorResponse } = require("../utils/response");

const allowedTypes = ["SYSTEM", "PROMOTION", "EVENT"];

const getNotifications = async (req, res) => {
  try {
    const includeAll = ['ADMIN', 'STAFF'].includes(String(req.user?.role || '').toUpperCase());
    const notifications = await notificationService.getNotifications(req.user?.id || null, { includeAll });
    return successResponse(res, notifications, "Lấy danh sách thông báo thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getNotificationById = async (req, res) => {
  try {
    const notification = await notificationService.getNotificationById(req.params.id, req.user?.id || null);

    if (!notification) {
      return errorResponse(res, "Không tìm thấy thông báo", 404);
    }

    return successResponse(res, notification, "Lấy chi tiết thông báo thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const createNotification = async (req, res) => {
  try {
    const { title, content, type, isActive, userId } = req.body;

    if (!title || !content) {
      return errorResponse(res, "Thiếu tiêu đề hoặc nội dung", 400);
    }

    if (type && !allowedTypes.includes(type)) {
      return errorResponse(res, "Loại thông báo không hợp lệ", 400);
    }

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const notification = await notificationService.createNotification({
      title,
      content,
      type: type || "SYSTEM",
      isActive: String(isActive) === "false" ? false : true,
      imageUrl,
      userId: Number(userId ?? req.user?.id ?? 0) || null,
    });

    return successResponse(res, notification, "Tạo thông báo thành công", 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateNotification = async (req, res) => {
  try {
    const { title, content, type, isActive, userId } = req.body;

    if (!title || !content) {
      return errorResponse(res, "Thiếu tiêu đề hoặc nội dung", 400);
    }

    if (type && !allowedTypes.includes(type)) {
      return errorResponse(res, "Loại thông báo không hợp lệ", 400);
    }

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : undefined;

    const notification = await notificationService.updateNotification(req.params.id, {
      title,
      content,
      type: type || "SYSTEM",
      isActive: String(isActive) === "false" ? false : true,
      imageUrl,
      userId: Number(userId ?? req.user?.id ?? 0) || null,
    });

    return successResponse(res, notification, "Cập nhật thông báo thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteNotification = async (req, res) => {
  try {
    await notificationService.deleteNotification(req.params.id, req.user?.id || null);
    return successResponse(res, null, "Xóa thông báo thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = {
  getNotifications,
  getNotificationById,
  createNotification,
  updateNotification,
  deleteNotification,
};