const attendanceService = require('../services/attendanceService');
const prisma = require('../config/database');
const { sendNotification } = require('../services/notificationService');
const { asyncHandler, apiResponse, ApiError } = require('../utils/helpers');

const checkIn = asyncHandler(async (req, res) => {
  const { sessionId, qrToken, latitude, longitude } = req.body;

  if (!sessionId || !qrToken || latitude == null || longitude == null) {
    throw new ApiError(400, 'sessionId, qrToken, latitude, and longitude are required');
  }

  const attendance = await attendanceService.checkIn(req.user.id, {
    sessionId,
    qrToken,
    latitude,
    longitude,
  });

  // Notify teacher about check-in
  try {
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: {
        class_: {
          include: {
            teacher: { select: { fcmToken: true } },
          },
        },
      },
    });
    if (session?.class_?.teacher?.fcmToken) {
      await sendNotification(
        session.class_.teacher.fcmToken,
        '✅ Student Checked In',
        `${req.user.name} has checked in for ${session.class_.name}`,
        { sessionId, studentId: req.user.id }
      );
    }
  } catch (err) {
    console.error('Notification error:', err.message);
  }

  apiResponse(res, 201, attendance, 'Check-in successful');
});

const getSessionAttendance = asyncHandler(async (req, res) => {
  const result = await attendanceService.getSessionAttendance(req.params.sessionId);
  apiResponse(res, 200, result);
});

const getClassReport = asyncHandler(async (req, res) => {
  const report = await attendanceService.getClassReport(req.params.classId);
  apiResponse(res, 200, report);
});

const getStudentAttendance = asyncHandler(async (req, res) => {
  const result = await attendanceService.getStudentAttendance(req.user.id, req.params.classId);
  apiResponse(res, 200, result);
});

module.exports = { checkIn, getSessionAttendance, getClassReport, getStudentAttendance };
