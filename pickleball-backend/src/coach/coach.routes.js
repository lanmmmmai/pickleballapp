const express = require('express');
const controller = require('./coach.controller');

const router = express.Router();
router.get('/', controller.getCoaches);

module.exports = router;