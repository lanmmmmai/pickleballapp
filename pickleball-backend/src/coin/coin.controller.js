const coinService = require("./coin.service");
const { successResponse, errorResponse } = require("../utils/response");

const getUsersWithCoin = async (req, res) => { try { return successResponse(res, await coinService.getUsersWithCoin(), "Lấy danh sách xu thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
const getCoinTransactions = async (req, res) => { try { return successResponse(res, await coinService.getCoinTransactions(), "Lấy lịch sử xu thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
const getMyHistory = async (req, res) => { try { return successResponse(res, await coinService.getUserCoinHistory(req.user.id), 'Lấy lịch sử xu của tôi thành công'); } catch (error) { return errorResponse(res, error.message, 500); } };
const getMyVouchers = async (req, res) => { try { return successResponse(res, await coinService.getMyVouchers(req.user.id), 'Lấy voucher của tôi thành công'); } catch (error) { return errorResponse(res, error.message, 500); } };
const getTasks = async (req, res) => { try { return successResponse(res, await coinService.getTasks(req.user.id), "Lấy nhiệm vụ coin thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
const claimTask = async (req, res) => { try { return successResponse(res, await coinService.claimTask(req.user.id, req.params.id), "Nhận thưởng nhiệm vụ thành công"); } catch (error) { return errorResponse(res, error.message, 500); } };
const createTask = async (req, res) => { try { return successResponse(res, await coinService.createTask(req.body), 'Tạo nhiệm vụ thành công', 201); } catch (error) { return errorResponse(res, error.message, 500); } };
const deleteTask = async (req, res) => { try { await coinService.deleteTask(req.params.id); return successResponse(res, null, 'Xóa nhiệm vụ thành công'); } catch (error) { return errorResponse(res, error.message, 500); } };
module.exports = { getUsersWithCoin, getCoinTransactions, getMyHistory, getMyVouchers, getTasks, claimTask, createTask, deleteTask };
