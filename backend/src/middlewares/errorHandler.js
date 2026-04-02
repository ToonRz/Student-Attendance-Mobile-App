const { ApiError } = require('../utils/helpers');

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, _next) {
  console.error(`[ERROR] ${err.message}`, err.stack ? err.stack.split('\n')[1] : '');

  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }

  // Prisma unique constraint violation
  if (err.code === 'P2002') {
    return res.status(409).json({
      success: false,
      message: `Duplicate value for: ${err.meta?.target?.join(', ') || 'unknown field'}`,
    });
  }

  // Prisma record not found
  if (err.code === 'P2025') {
    return res.status(404).json({
      success: false,
      message: 'Record not found',
    });
  }

  // Default server error
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
  });
}

module.exports = { errorHandler };
