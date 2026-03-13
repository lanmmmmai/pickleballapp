const courtService = require("./court.service");
const { successResponse, errorResponse } = require("../utils/response");

const getCourts = async (req, res) => {
  try {
    const courts = await courtService.getCourts();
    return successResponse(res, courts, "Lấy danh sách sân thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const createCourt = async (req, res) => {
  try {
    const {
      name,
      description,
      openTime,
      closeTime,
      status,
      priceSlots,
    } = req.body;

    if (!name) {
      return errorResponse(res, "Thiếu tên sân", 400);
    }

    const parsedPriceSlots = JSON.parse(priceSlots || "[]");

    if (!parsedPriceSlots.length) {
      return errorResponse(res, "Thiếu mức giá theo giờ", 400);
    }

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const court = await courtService.createCourt({
      name,
      description,
      imageUrl,
      openTime,
      closeTime,
      status,
      priceSlots: parsedPriceSlots,
    });

    return successResponse(res, court, "Tạo sân thành công", 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateCourt = async (req, res) => {
  try {
    const {
      name,
      description,
      openTime,
      closeTime,
      status,
      priceSlots,
    } = req.body;

    if (!name) {
      return errorResponse(res, "Thiếu tên sân", 400);
    }

    const parsedPriceSlots = JSON.parse(priceSlots || "[]");
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : undefined;

    const court = await courtService.updateCourt(req.params.id, {
      name,
      description,
      imageUrl,
      openTime,
      closeTime,
      status,
      priceSlots: parsedPriceSlots,
    });

    return successResponse(res, court, "Cập nhật sân thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteCourt = async (req, res) => {
  try {
    await courtService.deleteCourt(req.params.id);
    return successResponse(res, null, "Xóa sân thành công");
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = {
  getCourts,
  createCourt,
  updateCourt,
  deleteCourt,
};