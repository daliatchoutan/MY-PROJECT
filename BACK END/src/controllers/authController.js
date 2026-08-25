const jwt = require('jsonwebtoken');
const { User } = require('../models');

const register = async (req, res, next) => {
  try {
    const { name, email, password, role, phone, address, avatarUrl } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered.' });
    }

    const validRoles = ['Administrator', 'Farmer', 'Customer', 'Delivery Person'];
    const assignedRole = validRoles.includes(role) ? role : 'Customer';

    const user = await User.create({
      name,
      email,
      password,
      role: assignedRole,
      phone,
      address,
      avatarUrl
    });

    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      process.env.JWT_SECRET || 'super_secret_smart_poultry_farm_jwt_key_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return res.status(201).json({
      message: 'User registered successfully on NOVARA',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        address: user.address
      }
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }

    if (user.status === 'suspended') {
      return res.status(403).json({ message: 'Your NOVARA account is suspended. Please contact support.' });
    }

    if (user.status === 'blocked') {
      return res.status(403).json({ message: 'Your NOVARA account has been blocked.' });
    }

    const isValid = await user.validPassword(password);
    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }

    user.lastLoginAt = new Date();
    await user.save();

    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      process.env.JWT_SECRET || 'super_secret_smart_poultry_farm_jwt_key_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return res.json({
      message: 'Login successful to NOVARA',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        address: user.address
      }
    });
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.json({ user });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const { name, phone, address, avatarUrl } = req.body;
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;
    if (avatarUrl !== undefined) user.avatarUrl = avatarUrl;

    await user.save();

    return res.json({
      message: 'Profile updated successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        address: user.address
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile
};
