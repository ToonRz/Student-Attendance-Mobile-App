const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const env = require('../config/env');
const { ApiError } = require('../utils/helpers');

/**
 * Register a new user
 */
async function register({ email, password, name, role, deviceId }) {
  // Validate role
  if (!['TEACHER', 'STUDENT'].includes(role)) {
    throw new ApiError(400, 'Role must be TEACHER or STUDENT');
  }

  // Check existing user
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'Email already registered');
  }

  // If student and deviceId provided, check if device is already bound to someone else
  if (role === 'STUDENT' && deviceId) {
    const deviceBound = await prisma.user.findUnique({ where: { deviceId } });
    if (deviceBound) {
      throw new ApiError(403, 'This device is already linked to another account');
    }
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12);

  // Create user
  const user = await prisma.user.create({
    data: {
      email,
      password: hashedPassword,
      name,
      role,
      deviceId: role === 'STUDENT' ? deviceId : null,
    },
    select: { id: true, email: true, name: true, role: true, deviceId: true, createdAt: true },
  });

  // Generate token
  const token = generateToken(user.id);

  return { user, token };
}

/**
 * Login user
 */
async function login({ email, password, deviceId }) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new ApiError(401, 'Invalid email or password');
  }

  // Device Binding logic for Students
  if (user.role === 'STUDENT' && deviceId) {
    if (!user.deviceId) {
      // First time login - bind the device
      // But first check if this device is already bound to another student
      const deviceBound = await prisma.user.findUnique({ where: { deviceId } });
      if (deviceBound && deviceBound.id !== user.id) {
        throw new ApiError(403, 'This device is already linked to another account');
      }

      await prisma.user.update({
        where: { id: user.id },
        data: { deviceId },
      });
      user.deviceId = deviceId;
    } else if (user.deviceId !== deviceId) {
      // Trying to login on a different device
      throw new ApiError(403, 'This account is linked to another device. Please use your registered device.');
    }
  }

  const token = generateToken(user.id);

  return {
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      deviceId: user.deviceId,
    },
    token,
  };
}

/**
 * Update FCM token for push notifications
 */
async function updateFcmToken(userId, fcmToken) {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

/**
 * Generate JWT token
 */
function generateToken(userId) {
  return jwt.sign({ userId }, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });
}

module.exports = { register, login, updateFcmToken };
