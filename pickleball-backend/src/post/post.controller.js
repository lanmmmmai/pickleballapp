
const postService = require('./post.service');
const { successResponse, errorResponse } = require('../utils/response');

const getPosts = async (req, res) => {
  try {
    const posts = postService.listPosts(req.user?.id);
    return successResponse(res, posts, 'Lấy bài đăng thành công');
  } catch (e) {
    return errorResponse(res, e.message, 500);
  }
};

const createPost = async (req, res) => {
  try {
    if (!req.body.content && !req.file) {
      return errorResponse(res, 'Vui lòng nhập nội dung hoặc chọn media', 400);
    }
    const post = postService.createPost({ user: req.user, body: req.body, file: req.file });
    return successResponse(res, post, 'Đăng bài thành công', 201);
  } catch (e) {
    return errorResponse(res, e.message, 500);
  }
};

const likePost = async (req, res) => {
  try {
    const post = postService.toggleLike(req.params.id, req.user?.id);
    return successResponse(res, post, 'Cập nhật lượt thích thành công');
  } catch (e) { return errorResponse(res, e.message, 500); }
};

const savePost = async (req, res) => {
  try {
    const post = postService.toggleSave(req.params.id, req.user?.id);
    return successResponse(res, post, 'Cập nhật lưu bài thành công');
  } catch (e) { return errorResponse(res, e.message, 500); }
};

const commentPost = async (req, res) => {
  try {
    if (!req.body.content) return errorResponse(res, 'Thiếu nội dung bình luận', 400);
    const post = postService.addComment(req.params.id, req.user, req.body.content);
    return successResponse(res, post, 'Bình luận thành công');
  } catch (e) { return errorResponse(res, e.message, 500); }
};

const sharePost = async (req, res) => {
  try {
    const post = postService.sharePost(req.params.id, req.user?.id);
    return successResponse(res, post, 'Chia sẻ thành công');
  } catch (e) { return errorResponse(res, e.message, 500); }
};

module.exports = { getPosts, createPost, likePost, savePost, commentPost, sharePost };
