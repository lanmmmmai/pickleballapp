const express = require('express');
const controller = require('./voucher.controller');
const authMiddleware = require('../middleware/auth.middleware');
const roleMiddleware = require('../middleware/role.middleware');

const router = express.Router();
router.get('/', controller.getVouchers);
router.post('/', authMiddleware, roleMiddleware('ADMIN'), controller.createVoucher);
router.post('/:id/redeem', authMiddleware, controller.redeemVoucher);
module.exports = router;
