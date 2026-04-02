const { ApiError } = require('../utils/helpers');

/**
 * Role-based access control middleware
 * @param  {...string} roles - Allowed roles (e.g., 'TEACHER', 'STUDENT')
 */
function roleGuard(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }
    if (!roles.includes(req.user.role)) {
      return next(new ApiError(403, `Access denied. Required role: ${roles.join(' or ')}`));
    }
    next();
  };
}

module.exports = { roleGuard };
