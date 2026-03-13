const { errorResponse } = require('../utils/response');

const roleMiddleware = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return errorResponse(res, 'Forbidden', 403);
    }
    next();
  };
};

module.exports = roleMiddleware;