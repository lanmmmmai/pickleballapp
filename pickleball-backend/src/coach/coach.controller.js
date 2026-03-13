const service = require('./coach.service');
const { successResponse, errorResponse } = require('../utils/response');

const getCoaches = async (req, res) => {
  try {
    return successResponse(res, await service.getCoaches(), 'Coaches fetched');
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
};

module.exports = { getCoaches };