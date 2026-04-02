const crypto = require('crypto');
const prisma = require('../config/database');
const { ApiError } = require('../utils/helpers');
const { generateQrData } = require('./qrService');

/**
 * Open a new attendance session (Teacher only)
 */
async function openSession(teacherId, { classId, durationMin = 10, latitude, longitude }) {
  // Verify teacher owns this class
  const classData = await prisma.class.findUnique({ where: { id: classId } });
  if (!classData) throw new ApiError(404, 'Class not found');
  if (classData.teacherId !== teacherId) {
    throw new ApiError(403, 'You do not own this class');
  }

  // Check for existing active session
  const existingSession = await prisma.session.findFirst({
    where: { classId, isActive: true, expiresAt: { gt: new Date() } },
  });
  if (existingSession) {
    throw new ApiError(409, 'There is already an active session for this class');
  }

  // Generate session secret for QR rotation
  const qrSecret = crypto.randomBytes(32).toString('hex');

  const expiresAt = new Date(Date.now() + durationMin * 60 * 1000);

  const session = await prisma.session.create({
    data: {
      classId,
      qrSecret,
      teacherLat: latitude,
      teacherLng: longitude,
      durationMin,
      expiresAt,
    },
    include: {
      class_: { select: { id: true, name: true, subject: true } },
    },
  });

  return {
    ...session,
    qrSecret: undefined, // Don't expose secret to client
  };
}

/**
 * Get current QR data for a session (rotates every 30s)
 */
async function getSessionQr(sessionId, teacherId) {
  const session = await prisma.session.findUnique({
    where: { id: sessionId },
    include: { class_: true },
  });

  if (!session) throw new ApiError(404, 'Session not found');
  if (session.class_.teacherId !== teacherId) {
    throw new ApiError(403, 'You do not own this session');
  }

  if (!session.isActive || session.expiresAt < new Date()) {
    // Auto-close expired session
    if (session.isActive) {
      await prisma.session.update({
        where: { id: sessionId },
        data: { isActive: false },
      });
    }
    throw new ApiError(410, 'Session has expired');
  }

  return generateQrData(sessionId, session.qrSecret);
}

/**
 * Get session details
 */
async function getSession(sessionId) {
  const session = await prisma.session.findUnique({
    where: { id: sessionId },
    include: {
      class_: { select: { id: true, name: true, subject: true, teacherId: true } },
      _count: { select: { attendances: true } },
    },
  });

  if (!session) throw new ApiError(404, 'Session not found');

  return {
    ...session,
    qrSecret: undefined,
  };
}

/**
 * Close a session early
 */
async function closeSession(sessionId, teacherId) {
  const session = await prisma.session.findUnique({
    where: { id: sessionId },
    include: { class_: true },
  });

  if (!session) throw new ApiError(404, 'Session not found');
  if (session.class_.teacherId !== teacherId) {
    throw new ApiError(403, 'You do not own this session');
  }

  return prisma.session.update({
    where: { id: sessionId },
    data: { isActive: false },
  });
}

/**
 * Get all sessions for a class
 */
async function getClassSessions(classId) {
  return prisma.session.findMany({
    where: { classId },
    include: {
      _count: { select: { attendances: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
}

module.exports = { openSession, getSessionQr, getSession, closeSession, getClassSessions };
