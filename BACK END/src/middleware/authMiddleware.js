const jwt = require('jsonwebtoken');
const { User } = require('../models');

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_smart_poultry_farm_jwt_key_2026');
    
    // Check if user status is active
    const user = await User.findByPk(decoded.id);
    if (!user) {
      return res.status(401).json({ message: 'User account no longer exists.' });
    }

    if (user.status === 'suspended') {
      return res.status(403).json({ message: 'Account Suspended. Please contact NOVARA support.' });
    }

    if (user.status === 'blocked') {
      return res.status(403).json({ message: 'Account Blocked by Administrator.' });
    }

    req.user = decoded;
    req.userModel = user;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token.' });
  }
};

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: `Forbidden. Role '${req.user?.role}' is not authorized to perform this action.` 
      });
    }
    next();
  };
};

module.exports = {
  verifyToken,
  authorizeRoles
};
