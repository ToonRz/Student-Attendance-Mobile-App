const { Router } = require('express');
const {
  openSession,
  getSessionQr,
  getSession,
  closeSession,
  getClassSessions,
} = require('../controllers/sessionController');
const { authenticate } = require('../middlewares/auth');
const { roleGuard } = require('../middlewares/roleGuard');

const router = Router();

router.post('/', authenticate, roleGuard('TEACHER'), openSession);
router.get('/:id', authenticate, getSession);
router.get('/:id/qr', authenticate, roleGuard('TEACHER'), getSessionQr);
router.put('/:id/close', authenticate, roleGuard('TEACHER'), closeSession);
router.get('/class/:classId', authenticate, getClassSessions);

module.exports = router;
