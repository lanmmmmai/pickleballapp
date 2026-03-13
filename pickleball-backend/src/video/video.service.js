const prisma = require('../config/prisma');

const includeVideo = {
  creator: { select: { id: true, name: true, email: true } },
  _count: { select: { likes: true, saves: true, comments: true, views: true } },
};

const baseUrl = (process.env.PUBLIC_BASE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const absolute = (value) => {
  const v = String(value || '').trim();
  if (!v) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  return v.startsWith('/') ? `${baseUrl}${v}` : `${baseUrl}/${v}`;
};
const toBool = (value) => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') return value === 'true' || value === '1';
  return !!value;
};

function normalize(video, userId = null) {
  return {
    ...video,
    fileUrl: absolute(video.fileUrl),
    thumbnailUrl: absolute(video.thumbnailUrl),
    likesCount: video._count?.likes || 0,
    savesCount: video._count?.saves || 0,
    commentsCount: video._count?.comments || 0,
    viewsCount: video._count?.views || 0,
    liked: userId ? !!video.likes?.some((v) => v.userId === userId) : false,
    saved: userId ? !!video.saves?.some((v) => v.userId === userId) : false,
  };
}

async function getVideos() {
  const videos = await prisma.video.findMany({ include: includeVideo, orderBy: { createdAt: 'desc' } });
  return videos.map((v) => normalize(v));
}

async function getVideoFeed(userId = null, q = '') {
  const where = { isActive: true };
  if (q) {
    where.OR = [
      { title: { contains: q, mode: 'insensitive' } },
      { description: { contains: q, mode: 'insensitive' } },
    ];
  }
  const videos = await prisma.video.findMany({
    where,
    include: {
      ...includeVideo,
      likes: userId ? { where: { userId }, select: { userId: true } } : false,
      saves: userId ? { where: { userId }, select: { userId: true } } : false,
    },
    orderBy: { createdAt: 'desc' },
  });
  return videos.map((v) => normalize(v, userId));
}

async function getVideoById(id, userId = null) {
  const video = await prisma.video.findUnique({
    where: { id: Number(id) },
    include: {
      ...includeVideo,
      comments: { include: { user: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: 50 },
      likes: userId ? { where: { userId }, select: { userId: true } } : false,
      saves: userId ? { where: { userId }, select: { userId: true } } : false,
    },
  });
  if (!video) return null;
  return normalize(video, userId);
}

async function createVideo(data) {
  return prisma.video.create({ data: { ...data, isActive: toBool(data.isActive) } });
}

async function updateVideo(id, payload) {
  const data = { ...payload };
  if ('isActive' in data) data.isActive = toBool(data.isActive);
  return prisma.video.update({ where: { id: Number(id) }, data });
}

async function deleteVideo(id) {
  return prisma.video.delete({ where: { id: Number(id) } });
}

async function toggleLike(videoId, userId) {
  const existing = await prisma.videoLike.findUnique({ where: { videoId_userId: { videoId: Number(videoId), userId } } });
  if (existing) await prisma.videoLike.delete({ where: { videoId_userId: { videoId: Number(videoId), userId } } });
  else await prisma.videoLike.create({ data: { videoId: Number(videoId), userId } });
  return getVideoById(videoId, userId);
}

async function toggleSave(videoId, userId) {
  const existing = await prisma.videoSave.findUnique({ where: { videoId_userId: { videoId: Number(videoId), userId } } });
  if (existing) await prisma.videoSave.delete({ where: { videoId_userId: { videoId: Number(videoId), userId } } });
  else await prisma.videoSave.create({ data: { videoId: Number(videoId), userId } });
  return getVideoById(videoId, userId);
}

async function addComment(videoId, userId, content) {
  await prisma.videoComment.create({ data: { videoId: Number(videoId), userId, content } });
  return getVideoById(videoId, userId);
}

async function addView(videoId, userId = null) {
  await prisma.videoView.create({ data: { videoId: Number(videoId), userId } });
  return getVideoById(videoId, userId);
}

async function getStats() {
  const videos = await prisma.video.findMany({ include: includeVideo, orderBy: { createdAt: 'desc' } });
  return videos.map((v) => ({ id: v.id, title: v.title, category: v.category, status: v.status, isActive: v.isActive, createdAt: v.createdAt, creator: v.creator, likesCount: v._count.likes, commentsCount: v._count.comments, savesCount: v._count.saves, viewsCount: v._count.views }));
}

module.exports = { getVideos, getVideoFeed, getVideoById, createVideo, updateVideo, deleteVideo, toggleLike, toggleSave, addComment, addView, getStats };
