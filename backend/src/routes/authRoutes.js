const { Router } = require('express');
const { register, login, getMe, updateFcmToken } = require('../controllers/authController');
const { authenticate } = require('../middlewares/auth');

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, getMe);
router.put('/fcm-token', authenticate, updateFcmToken);

module.exports = router;
