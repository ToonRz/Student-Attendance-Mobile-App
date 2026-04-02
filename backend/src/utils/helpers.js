/**
 * Generate a random class code (6 characters, uppercase alphanumeric)
 */
function generateClassCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I,O,0,1 to avoid confusion
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

/**
 * Wrap async route handlers to catch errors
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/**
 * Create API response format
 */
function apiResponse(res, statusCode, data, message = null) {
  const response = { success: statusCode < 400 };
  if (message) response.message = message;
  if (data !== undefined && data !== null) response.data = data;
  return res.status(statusCode).json(response);
}

/**
 * Create API error
 */
class ApiError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'ApiError';
  }
}

module.exports = { generateClassCode, asyncHandler, apiResponse, ApiError };
