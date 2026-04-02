const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const env = require('../config/env');
const { ApiError } = require('../utils/helpers');

/**
 * Register a new user
 */
async function register({ email, password, name, role }) {
  // Validate role
  if (!['TEACHER', 'STUDENT'].includes(role)) {
    throw new ApiError(400, 'Role must be TEACHER or STUDENT');
  }

  // Check existing user
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'Email already registered');
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
    },
    select: { id: true, email: true, name: true, role: true, createdAt: true },
  });

  // Generate token
  const token = generateToken(user.id);

  return { user, token };
}

/**
 * Login user
 */
async function login({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const token = generateToken(user.id);

  return {
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
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
