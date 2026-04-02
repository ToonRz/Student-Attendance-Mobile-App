const { Router } = require('express');
const {
  createClass,
  getTeacherClasses,
  getClassDetail,
  getClassStudents,
  joinClass,
  getStudentClasses,
} = require('../controllers/classController');
const { authenticate } = require('../middlewares/auth');
const { roleGuard } = require('../middlewares/roleGuard');

const router = Router();

// Teacher routes
router.post('/', authenticate, roleGuard('TEACHER'), createClass);
router.get('/', authenticate, roleGuard('TEACHER'), getTeacherClasses);
router.get('/my', authenticate, roleGuard('STUDENT'), getStudentClasses);
router.get('/:id', authenticate, getClassDetail);
router.get('/:id/students', authenticate, getClassStudents);

// Student routes
router.post('/join', authenticate, roleGuard('STUDENT'), joinClass);

module.exports = router;
