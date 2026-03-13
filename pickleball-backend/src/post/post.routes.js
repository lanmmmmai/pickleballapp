
const express = require('express');
const controller = require('./post.controller');
const authMiddleware = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

const router = express.Router();

router.get('/', controller.getPosts);
router.post('/', authMiddleware, upload.single('media'), controller.createPost);
router.post('/:id/like', authMiddleware, controller.likePost);
router.post('/:id/save', authMiddleware, controller.savePost);
router.post('/:id/comment', authMiddleware, controller.commentPost);
router.post('/:id/share', authMiddleware, controller.sharePost);

module.exports = router;
