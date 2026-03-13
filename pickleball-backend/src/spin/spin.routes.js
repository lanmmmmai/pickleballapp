const express = require('express');
const controller = require('./spin.controller');
const authMiddleware = require('../middleware/auth.middleware');
const roleMiddleware = require('../middleware/role.middleware');

const router = express.Router();
router.get('/rewards', authMiddleware, controller.getRewards);
router.post('/play', authMiddleware, controller.playSpin);
router.post('/rewards', authMiddleware, roleMiddleware('ADMIN'), controller.createReward);
router.delete('/rewards/:id', authMiddleware, roleMiddleware('ADMIN'), controller.deleteReward);

module.exports = router;
