const sessionService = require('../services/sessionService');
const prisma = require('../config/database');
const { sendMultipleNotifications } = require('../services/notificationService');
const { asyncHandler, apiResponse, ApiError } = require('../utils/helpers');

const openSession = asyncHandler(async (req, res) => {
  const { classId, durationMin, latitude, longitude } = req.body;

  if (!classId || latitude == null || longitude == null) {
    throw new ApiError(400, 'classId, latitude, and longitude are required');
  }

  const session = await sessionService.openSession(req.user.id, {
    classId,
    durationMin: durationMin || 10,
    latitude,
    longitude,
  });

  // Send notification to enrolled students
  try {
    const members = await prisma.classMember.findMany({
      where: { classId },
      include: { student: { select: { fcmToken: true } } },
    });
    const tokens = members.map((m) => m.student.fcmToken).filter(Boolean);
    if (tokens.length > 0) {
      // Non-blocking: We don't await here so the teacher gets the QR code immediately
      sendMultipleNotifications(
        tokens,
        '📚 Attendance Session Started',
        `Check-in is now open for ${session.class_.name}. You have ${durationMin || 10} minutes.`,
        { sessionId: session.id, classId }
      ).catch(err => console.error('Background notification error:', err.message));
    }
  } catch (err) {
    console.error('Notification setup error:', err.message);
  }

  apiResponse(res, 201, session, 'Session opened');
});

const getSessionQr = asyncHandler(async (req, res) => {
  const qrData = await sessionService.getSessionQr(req.params.id, req.user.id);
  apiResponse(res, 200, qrData);
});

const getSession = asyncHandler(async (req, res) => {
  const session = await sessionService.getSession(req.params.id);
  apiResponse(res, 200, session);
});

const closeSession = asyncHandler(async (req, res) => {
  await sessionService.closeSession(req.params.id, req.user.id);
  apiResponse(res, 200, null, 'Session closed');
});

const getClassSessions = asyncHandler(async (req, res) => {
  const sessions = await sessionService.getClassSessions(req.params.classId);
  apiResponse(res, 200, sessions);
});

module.exports = { openSession, getSessionQr, getSession, closeSession, getClassSessions };
