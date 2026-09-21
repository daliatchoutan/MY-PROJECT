const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { generateFarmerId, generateDeliveryPersonId } = require('../utils/idGenerator');

const register = async (req, res, next) => {
  try {
    const {
      name,
      email,
      password,
      confirmPassword,
      role,
      phone,
      cniNumber,
      professionalLicenseNumber,
      driverLicenseNumber,
      vehicleType,
      vehiclePlateNumber,
      address,
      avatarUrl
    } = req.body;

    // Basic required fields
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    // Password confirmation validation if provided
    if (confirmPassword !== undefined && password !== confirmPassword) {
      return res.status(400).json({ message: 'Passwords do not match.' });
    }

    // STRICT ROLE LOCKDOWN: Administrator cannot be registered through public registration
    if (role && (role.toLowerCase().includes('admin') || role.trim().toLowerCase() === 'administrator')) {
      return res.status(403).json({
        message: 'Creating an Administrator account via public registration is prohibited.'
      });
    }

    const validPublicRoles = ['Customer', 'Farmer', 'Delivery Person'];
    const assignedRole = validPublicRoles.includes(role) ? role : 'Customer';

    // Farmer and Delivery Person require CNI & phone
    if ((assignedRole === 'Farmer' || assignedRole === 'Delivery Person') && (!cniNumber || !cniNumber.trim())) {
      return res.status(400).json({ message: 'CNI / National ID Card Number is required.' });
    }

    if ((assignedRole === 'Farmer' || assignedRole === 'Delivery Person') && (!phone || !phone.trim())) {
      return res.status(400).json({ message: 'Phone number is required.' });
    }

    // Check unique email
    const existingUser = await User.findOne({ where: { email: email.trim().toLowerCase() } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered.' });
    }

    // Check unique CNI if provided
    const cleanCni = cniNumber ? cniNumber.trim() : null;
    if (cleanCni) {
      const existingCni = await User.findOne({ where: { cniNumber: cleanCni } });
      if (existingCni) {
        return res.status(400).json({ message: 'CNI / National ID Card Number is already registered.' });
      }
    }

    // Generate unique system IDs for Farmer and Delivery Person
    let generatedFarmerId = null;
    let generatedDeliveryPersonId = null;

    if (assignedRole === 'Farmer') {
      generatedFarmerId = await generateFarmerId(User);
    } else if (assignedRole === 'Delivery Person') {
      generatedDeliveryPersonId = await generateDeliveryPersonId(User);
    }

    // Status is active immediately for all normal roles (Farmer, Delivery Person, Customer)
    const initialStatus = 'active';

    const user = await User.create({
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password,
      role: assignedRole,
      status: initialStatus,
      phone: phone ? phone.trim() : null,
      cniNumber: cleanCni,
      farmerId: generatedFarmerId,
      professionalLicenseNumber: professionalLicenseNumber ? professionalLicenseNumber.trim() : null,
      deliveryPersonId: generatedDeliveryPersonId,
      driverLicenseNumber: driverLicenseNumber ? driverLicenseNumber.trim() : null,
      vehicleType: vehicleType ? vehicleType.trim() : null,
      vehiclePlateNumber: vehiclePlateNumber ? vehiclePlateNumber.trim() : null,
      address: address ? address.trim() : null,
      avatarUrl: avatarUrl && avatarUrl.trim().length > 0 ? avatarUrl.trim() : null
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
        phone: user.phone,
        cniNumber: user.cniNumber,
        farmerId: user.farmerId,
        professionalLicenseNumber: user.professionalLicenseNumber,
        deliveryPersonId: user.deliveryPersonId,
        driverLicenseNumber: user.driverLicenseNumber,
        vehicleType: user.vehicleType,
        vehiclePlateNumber: user.vehiclePlateNumber,
        avatarUrl: user.avatarUrl,
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
        rejectionReason: user.rejectionReason,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        cniNumber: user.cniNumber,
        farmerId: user.farmerId,
        professionalLicenseNumber: user.professionalLicenseNumber,
        deliveryPersonId: user.deliveryPersonId,
        driverLicenseNumber: user.driverLicenseNumber,
        vehicleType: user.vehicleType,
        vehiclePlateNumber: user.vehiclePlateNumber,
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

    const { name, phone, address, avatarUrl, vehicleType, vehiclePlateNumber } = req.body;
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;
    if (avatarUrl !== undefined) user.avatarUrl = avatarUrl;
    if (vehicleType !== undefined) user.vehicleType = vehicleType;
    if (vehiclePlateNumber !== undefined) user.vehiclePlateNumber = vehiclePlateNumber;

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
        cniNumber: user.cniNumber,
        farmerId: user.farmerId,
        professionalLicenseNumber: user.professionalLicenseNumber,
        deliveryPersonId: user.deliveryPersonId,
        driverLicenseNumber: user.driverLicenseNumber,
        vehicleType: user.vehicleType,
        vehiclePlateNumber: user.vehiclePlateNumber,
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
