const prisma = require('../config/database');
const { ApiError } = require('../utils/helpers');
const { validateQrToken } = require('./qrService');
const { verifyLocation } = require('./locationService');

/**
 * Student check-in with QR token and location verification
 */
async function checkIn(studentId, { sessionId, qrToken, latitude, longitude }) {
  // 1. Get session
  const session = await prisma.session.findUnique({
    where: { id: sessionId },
    include: { class_: true },
  });

  if (!session) throw new ApiError(404, 'Session not found');

  // 2. Check session is active
  if (!session.isActive) {
    throw new ApiError(410, 'Session is no longer active');
  }

  // 3. Check session not expired (use server time)
  if (session.expiresAt < new Date()) {
    // Auto-close
    await prisma.session.update({
      where: { id: sessionId },
      data: { isActive: false },
    });
    throw new ApiError(410, 'Session has expired');
  }

  // 4. Check student is enrolled in the class
  const membership = await prisma.classMember.findUnique({
    where: {
      classId_studentId: {
        classId: session.classId,
        studentId,
      },
    },
  });

  if (!membership) {
    throw new ApiError(403, 'You are not enrolled in this class');
  }

  // 5. Check duplicate check-in
  const existingAttendance = await prisma.attendance.findUnique({
    where: {
      sessionId_studentId: {
        sessionId,
        studentId,
      },
    },
  });

  if (existingAttendance) {
    throw new ApiError(409, 'You have already checked in for this session');
  }

  // 6. Validate QR token
  const isValidToken = validateQrToken(session.qrSecret, qrToken);
  if (!isValidToken) {
    throw new ApiError(400, 'Invalid or expired QR code. Please scan the current QR code.');
  }

  // 7. Verify location
  const locationCheck = verifyLocation(
    session.teacherLat,
    session.teacherLng,
    latitude,
    longitude
  );

  if (!locationCheck.isValid) {
    throw new ApiError(400, 
      `You are too far from the classroom (${locationCheck.distance.toFixed(0)}m). Must be within 50m.`
    );
  }

  // 8. Create attendance record
  const attendance = await prisma.attendance.create({
    data: {
      sessionId,
      studentId,
      studentLat: latitude,
      studentLng: longitude,
      distance: locationCheck.distance,
      status: 'PRESENT',
    },
    include: {
      student: { select: { id: true, name: true, email: true } },
      session: { select: { id: true, classId: true } },
    },
  });

  return attendance;
}

/**
 * Get attendance for a specific session (Teacher view)
 */
async function getSessionAttendance(sessionId) {
  const session = await prisma.session.findUnique({
    where: { id: sessionId },
    include: {
      class_: {
        include: {
          members: {
            include: {
              student: { select: { id: true, name: true, email: true } },
            },
          },
        },
      },
      attendances: {
        include: {
          student: { select: { id: true, name: true, email: true } },
        },
        orderBy: { checkedInAt: 'asc' },
      },
    },
  });

  if (!session) throw new ApiError(404, 'Session not found');

  // Build present/absent lists
  const presentIds = new Set(session.attendances.map((a) => a.studentId));
  const allStudents = session.class_.members.map((m) => m.student);
  
  const present = session.attendances.map((a) => ({
    ...a.student,
    checkedInAt: a.checkedInAt,
    distance: a.distance,
  }));

  const absent = allStudents.filter((s) => !presentIds.has(s.id));

  return {
    sessionId: session.id,
    classId: session.classId,
    createdAt: session.createdAt,
    expiresAt: session.expiresAt,
    isActive: session.isActive,
    totalStudents: allStudents.length,
    presentCount: present.length,
    absentCount: absent.length,
    present,
    absent,
  };
}

/**
 * Get attendance report for a class (Teacher view)
 */
async function getClassReport(classId) {
  const classData = await prisma.class.findUnique({
    where: { id: classId },
    include: {
      members: {
        include: {
          student: { select: { id: true, name: true, email: true } },
        },
      },
      sessions: {
        include: {
          attendances: true,
        },
        orderBy: { createdAt: 'desc' },
      },
    },
  });

  if (!classData) throw new ApiError(404, 'Class not found');

  const totalSessions = classData.sessions.length;

  // Calculate per-student stats
  const studentStats = classData.members.map((m) => {
    const studentAttendances = classData.sessions.reduce((count, session) => {
      const attended = session.attendances.some((a) => a.studentId === m.studentId);
      return count + (attended ? 1 : 0);
    }, 0);

    return {
      student: m.student,
      totalSessions,
      attended: studentAttendances,
      absent: totalSessions - studentAttendances,
      attendanceRate: totalSessions > 0
        ? Math.round((studentAttendances / totalSessions) * 100)
        : 0,
    };
  });

  return {
    classId,
    className: classData.name,
    subject: classData.subject,
    totalSessions,
    totalStudents: classData.members.length,
    students: studentStats,
  };
}

/**
 * Get student's own attendance for a class
 */
async function getStudentAttendance(studentId, classId) {
  const sessions = await prisma.session.findMany({
    where: { classId },
    include: {
      attendances: {
        where: { studentId },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  const totalSessions = sessions.length;
  const attended = sessions.filter((s) => s.attendances.length > 0).length;

  return {
    classId,
    totalSessions,
    attended,
    absent: totalSessions - attended,
    attendanceRate: totalSessions > 0 ? Math.round((attended / totalSessions) * 100) : 0,
    sessions: sessions.map((s) => ({
      sessionId: s.id,
      date: s.createdAt,
      status: s.attendances.length > 0 ? 'PRESENT' : 'ABSENT',
      checkedInAt: s.attendances[0]?.checkedInAt || null,
    })),
  };
}

module.exports = { checkIn, getSessionAttendance, getClassReport, getStudentAttendance };
