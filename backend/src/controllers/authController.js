const authService = require('../services/authService');
const { asyncHandler, apiResponse, ApiError } = require('../utils/helpers');

const register = asyncHandler(async (req, res) => {
  const { email, password, name, role } = req.body;

  if (!email || !password || !name || !role) {
    throw new ApiError(400, 'All fields are required: email, password, name, role');
  }

  if (password.length < 6) {
    throw new ApiError(400, 'Password must be at least 6 characters');
  }

  const result = await authService.register({ email, password, name, role });
  apiResponse(res, 201, result, 'Registration successful');
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    throw new ApiError(400, 'Email and password are required');
  }

  const result = await authService.login({ email, password });
  apiResponse(res, 200, result, 'Login successful');
});

const getMe = asyncHandler(async (req, res) => {
  apiResponse(res, 200, req.user);
});

const updateFcmToken = asyncHandler(async (req, res) => {
  const { fcmToken } = req.body;
  if (!fcmToken) throw new ApiError(400, 'fcmToken is required');

  await authService.updateFcmToken(req.user.id, fcmToken);
  apiResponse(res, 200, null, 'FCM token updated');
});

module.exports = { register, login, getMe, updateFcmToken };
