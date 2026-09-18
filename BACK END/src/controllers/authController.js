const jwt = require('jsonwebtoken');
const { User } = require('../models');

const register = async (req, res, next) => {
  try {
    const { name, email, password, role, phone, address, avatarUrl, farmName, farmLocation, farmCapacity } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    // STRICT ROLE LOCKDOWN: Administrator cannot be registered through public registration
    if (role && (role.toLowerCase().includes('admin') || role === 'Administrator')) {
      return res.status(403).json({
        message: 'Creating an Administrator account via public registration is prohibited.'
      });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered.' });
    }

    const validPublicRoles = ['Customer', 'Farmer', 'Delivery Person'];
    const assignedRole = validPublicRoles.includes(role) ? role : 'Customer';

    // Role-specific initial status
    // Customer accounts are active immediately
    // Farmer and Delivery Person accounts require Administrator approval
    let initialStatus = 'active';
    if (assignedRole === 'Farmer' || assignedRole === 'Delivery Person') {
      initialStatus = 'pending';
    }

    const user = await User.create({
      name,
      email,
      password,
      role: assignedRole,
      status: initialStatus,
      phone,
      address,
      avatarUrl
    });

    let createdFarm = null;
    // If Farmer, auto-create their farm record with status pending
    if (assignedRole === 'Farmer') {
      const { Farm } = require('../models');
      createdFarm = await Farm.create({
        name: farmName && farmName.trim().length > 0 ? farmName.trim() : `${name}'s Poultry Farm`,
        location: farmLocation && farmLocation.trim().length > 0 ? farmLocation.trim() : (address || 'Local Facility'),
        capacity: farmCapacity ? parseInt(farmCapacity) : 500,
        currentPoultryCount: 0,
        farmerId: user.id,
        status: 'pending'
      });
    }

    // Notify administrators of pending registration
    if (initialStatus === 'pending') {
      try {
        const { Notification } = require('../models');
        const admins = await User.findAll({ where: { role: 'Administrator' } });
        for (const admin of admins) {
          await Notification.create({
            userId: admin.id,
            title: `New ${assignedRole} Registration Pending`,
            message: `${name} (${email}) has registered as a ${assignedRole} and is awaiting your approval.`,
            type: 'system',
            isRead: false
          });
        }
      } catch (notifErr) {
        console.error('Error creating admin notification for pending registration:', notifErr.message);
      }
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      process.env.JWT_SECRET || 'super_secret_smart_poultry_farm_jwt_key_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const message = initialStatus === 'pending'
      ? `Registration submitted successfully. Your ${assignedRole} account is pending administrator approval.`
      : 'User registered successfully on NOVARA';

    return res.status(201).json({
      message,
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        address: user.address,
        farm: createdFarm
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
        rejectionReason: user.rejectionReason,
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
    const { Farm } = require('../models');
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] },
      include: [{ model: Farm, as: 'farms' }]
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
