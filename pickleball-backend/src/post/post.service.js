
const fs = require("fs");
const path = require("path");
const { getAvatarUrlByUserId } = require("../utils/avatarStore");

const DATA_FILE = path.join(__dirname, "../data/posts.json");

function ensureFile() {
  if (!fs.existsSync(DATA_FILE)) {
    fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
    fs.writeFileSync(DATA_FILE, "[]", "utf8");
  }
}

function readPosts() {
  ensureFile();
  try {
    return JSON.parse(fs.readFileSync(DATA_FILE, "utf8") || "[]");
  } catch (_) {
    return [];
  }
}

function writePosts(posts) {
  ensureFile();
  fs.writeFileSync(DATA_FILE, JSON.stringify(posts, null, 2), "utf8");
}

function decorate(post, currentUserId) {
  const likes = Array.isArray(post.likes) ? post.likes : [];
  const saves = Array.isArray(post.saves) ? post.saves : [];
  const comments = Array.isArray(post.comments) ? post.comments : [];
  return {
    ...post,
    authorAvatarUrl: post.authorAvatarUrl || getAvatarUrlByUserId(post.authorId),
    comments: comments.map((comment) => ({
      ...comment,
      authorAvatarUrl: comment.authorAvatarUrl || getAvatarUrlByUserId(comment.userId),
    })),
    likeCount: likes.length,
    saveCount: saves.length,
    commentCount: comments.length,
    liked: currentUserId ? likes.includes(currentUserId) : false,
    saved: currentUserId ? saves.includes(currentUserId) : false,
  };
}

function listPosts(currentUserId) {
  const posts = readPosts().sort((a,b)=> new Date(b.createdAt) - new Date(a.createdAt));
  return posts.map((p) => decorate(p, currentUserId));
}

function createPost({ user, body, file }) {
  const posts = readPosts();
  const id = posts.length ? Math.max(...posts.map((p) => Number(p.id) || 0)) + 1 : 1;
  const mediaUrl = file ? `/uploads/${file.filename}` : null;
  const mediaType = file ? (String(file.mimetype || '').startsWith('video/') ? 'video' : 'image') : null;
  const hashtags = String(body.hashtags || '')
    .split(/[,\s]+/)
    .map((t) => t.trim())
    .filter(Boolean);
  const post = {
    id,
    authorId: user?.id || null,
    authorName: body.authorName || user?.name || user?.email || 'Thành viên',
    authorRole: body.authorRole || user?.role || 'USER',
    authorAvatarUrl: getAvatarUrlByUserId(user?.id || null),
    content: String(body.content || '').trim(),
    hashtags,
    mediaUrl,
    mediaType,
    createdAt: new Date().toISOString(),
    likes: [],
    saves: [],
    shareCount: 0,
    comments: [],
  };
  posts.push(post);
  writePosts(posts);
  return decorate(post, user?.id);
}

function toggleLike(id, userId) {
  const posts = readPosts();
  const idx = posts.findIndex((p) => Number(p.id) === Number(id));
  if (idx < 0) throw new Error('Không tìm thấy bài đăng');
  posts[idx].likes = Array.isArray(posts[idx].likes) ? posts[idx].likes : [];
  const has = posts[idx].likes.includes(userId);
  posts[idx].likes = has ? posts[idx].likes.filter((x) => x !== userId) : [...posts[idx].likes, userId];
  writePosts(posts);
  return decorate(posts[idx], userId);
}

function toggleSave(id, userId) {
  const posts = readPosts();
  const idx = posts.findIndex((p) => Number(p.id) === Number(id));
  if (idx < 0) throw new Error('Không tìm thấy bài đăng');
  posts[idx].saves = Array.isArray(posts[idx].saves) ? posts[idx].saves : [];
  const has = posts[idx].saves.includes(userId);
  posts[idx].saves = has ? posts[idx].saves.filter((x) => x !== userId) : [...posts[idx].saves, userId];
  writePosts(posts);
  return decorate(posts[idx], userId);
}

function addComment(id, user, content) {
  const posts = readPosts();
  const idx = posts.findIndex((p) => Number(p.id) === Number(id));
  if (idx < 0) throw new Error('Không tìm thấy bài đăng');
  posts[idx].comments = Array.isArray(posts[idx].comments) ? posts[idx].comments : [];
  const comment = {
    id: Date.now(),
    userId: user?.id || null,
    authorName: user?.name || user?.email || 'Thành viên',
    content: String(content || '').trim(),
    authorAvatarUrl: getAvatarUrlByUserId(user?.id || null),
    createdAt: new Date().toISOString(),
  };
  posts[idx].comments.unshift(comment);
  writePosts(posts);
  return decorate(posts[idx], user?.id);
}

function sharePost(id, userId) {
  const posts = readPosts();
  const idx = posts.findIndex((p) => Number(p.id) === Number(id));
  if (idx < 0) throw new Error('Không tìm thấy bài đăng');
  posts[idx].shareCount = Number(posts[idx].shareCount || 0) + 1;
  writePosts(posts);
  return decorate(posts[idx], userId);
}

module.exports = { listPosts, createPost, toggleLike, toggleSave, addComment, sharePost };
