const prisma = require('../config/prisma');

const getClasses = async () => prisma.class.findMany({
  include: {
    coach: { select: { id:true, name:true, email:true } },
    enrollments: { include: { user: { select: { id:true,name:true,email:true } } } },
  },
  orderBy: { id: 'desc' },
});

const getMyClasses = async (userId, role) => {
  if (role === 'COACH') {
    return prisma.class.findMany({ where: { coachId: Number(userId) }, include: { enrollments: { include: { user: true } }, coach: true }, orderBy:{id:'desc'} });
  }
  return prisma.classEnrollment.findMany({ where: { userId: Number(userId) }, include: { class: { include: { coach: true, enrollments: true } } }, orderBy: { id: 'desc' } });
};

const normalizeSchedule = (data) => {
  const weekdays = Array.isArray(data.weekdays) ? data.weekdays : typeof data.weekdays === 'string' && data.weekdays ? data.weekdays.split(',').map(s=>s.trim()).filter(Boolean) : [];
  const payload = {
    startDate: data.startDate || '',
    endDate: data.endDate || '',
    weekdays,
    sessionText: data.sessionText || data.sessions || '',
    note: data.note || '',
  };
  return JSON.stringify(payload);
};

const createClass = async (data, user) => prisma.class.create({
  data: {
    title: data.title,
    description: data.description || '',
    coachId: data.coachId ? Number(data.coachId) : Number(user.id),
    schedule: normalizeSchedule(data),
    maxStudents: Number(data.maxStudents || 20),
    status: data.status || 'OPEN',
  },
});

const updateClass = async (id, data, user) => {
  const existing = await prisma.class.findUnique({ where: { id: Number(id) } });
  if (!existing) throw new Error('Không tìm thấy lớp học');
  return prisma.class.update({
    where: { id: Number(id) },
    data: {
      title: data.title,
      description: data.description || '',
      coachId: data.coachId ? Number(data.coachId) : existing.coachId,
      schedule: normalizeSchedule(data),
      maxStudents: Number(data.maxStudents || 20),
      status: data.status || existing.status,
    },
  });
};

const deleteClass = async (id) => prisma.class.delete({ where: { id: Number(id) } });

const enrollClass = async (classId, userId) => {
  const numericClassId = Number(classId);
  const numericUserId = Number(userId);
  const selectedClass = await prisma.class.findUnique({
    where: { id: numericClassId },
    include: { enrollments: true },
  });

  if (!selectedClass) throw new Error('Không tìm thấy lớp học');
  if (selectedClass.status && selectedClass.status !== 'OPEN') throw new Error('Lớp học hiện không mở đăng ký');

  const alreadyEnrolled = selectedClass.enrollments.some((item) => item.userId === numericUserId);
  if (alreadyEnrolled) throw new Error('Người dùng này đã có trong lớp học');

  if (selectedClass.enrollments.length >= Number(selectedClass.maxStudents || 0)) {
    throw new Error('Lớp học đã đủ số lượng học viên');
  }

  return prisma.classEnrollment.create({ data: { classId: numericClassId, userId: numericUserId } });
};

const removeEnrollment = async (id) => prisma.classEnrollment.delete({ where: { id: Number(id) } });

module.exports = { getClasses, getMyClasses, createClass, updateClass, deleteClass, enrollClass, removeEnrollment };
