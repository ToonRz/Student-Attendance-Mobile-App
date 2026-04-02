const { Router } = require('express');
const {
  checkIn,
  getSessionAttendance,
  getClassReport,
  getStudentAttendance,
} = require('../controllers/attendanceController');
const { authenticate } = require('../middlewares/auth');
const { roleGuard } = require('../middlewares/roleGuard');

const router = Router();

router.post('/checkin', authenticate, roleGuard('STUDENT'), checkIn);
router.get('/session/:sessionId', authenticate, getSessionAttendance);
router.get('/report/:classId', authenticate, roleGuard('TEACHER'), getClassReport);
router.get('/student/:classId', authenticate, roleGuard('STUDENT'), getStudentAttendance);

module.exports = router;
