const prisma = require('../config/database');
const { ApiError, generateClassCode } = require('../utils/helpers');

/**
 * Create a new class (Teacher only)
 */
async function createClass(teacherId, { name, subject }) {
  // Generate unique class code
  let code;
  let isUnique = false;
  while (!isUnique) {
    code = generateClassCode();
    const existing = await prisma.class.findUnique({ where: { code } });
    if (!existing) isUnique = true;
  }

  const newClass = await prisma.class.create({
    data: {
      name,
      subject,
      code,
      teacherId,
    },
    include: {
      teacher: { select: { id: true, name: true, email: true } },
      _count: { select: { members: true } },
    },
  });

  return newClass;
}

/**
 * Get all classes for a teacher
 */
async function getTeacherClasses(teacherId) {
  return prisma.class.findMany({
    where: { teacherId },
    include: {
      _count: { select: { members: true, sessions: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
}

/**
 * Get class details with students
 */
async function getClassDetail(classId, userId) {
  const classData = await prisma.class.findUnique({
    where: { id: classId },
    include: {
      teacher: { select: { id: true, name: true, email: true } },
      members: {
        include: {
          student: { select: { id: true, name: true, email: true } },
        },
        orderBy: { joinedAt: 'asc' },
      },
      _count: { select: { sessions: true } },
    },
  });

  if (!classData) {
    throw new ApiError(404, 'Class not found');
  }

  return classData;
}

/**
 * Join a class by code (Student only)
 */
async function joinClass(studentId, classCode) {
  const classData = await prisma.class.findUnique({ where: { code: classCode } });
  if (!classData) {
    throw new ApiError(404, 'Class not found. Check the class code.');
  }

  // Check if already enrolled
  const existing = await prisma.classMember.findUnique({
    where: {
      classId_studentId: {
        classId: classData.id,
        studentId,
      },
    },
  });

  if (existing) {
    throw new ApiError(409, 'Already enrolled in this class');
  }

  await prisma.classMember.create({
    data: {
      classId: classData.id,
      studentId,
    },
  });

  return prisma.class.findUnique({
    where: { id: classData.id },
    include: {
      teacher: { select: { id: true, name: true } },
      _count: { select: { members: true } },
    },
  });
}

/**
 * Get all classes a student is enrolled in
 */
async function getStudentClasses(studentId) {
  const memberships = await prisma.classMember.findMany({
    where: { studentId },
    include: {
      class_: {
        include: {
          teacher: { select: { id: true, name: true } },
          _count: { select: { members: true, sessions: true } },
        },
      },
    },
    orderBy: { joinedAt: 'desc' },
  });

  return memberships.map((m) => m.class_);
}

/**
 * Get students in a class
 */
async function getClassStudents(classId) {
  const members = await prisma.classMember.findMany({
    where: { classId },
    include: {
      student: { select: { id: true, name: true, email: true } },
    },
    orderBy: { joinedAt: 'asc' },
  });

  return members.map((m) => ({
    ...m.student,
    joinedAt: m.joinedAt,
  }));
}

module.exports = {
  createClass,
  getTeacherClasses,
  getClassDetail,
  joinClass,
  getStudentClasses,
  getClassStudents,
};
