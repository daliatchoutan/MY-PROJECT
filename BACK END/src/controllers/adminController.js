const { User, Farm, Device, Order, Product, Notification } = require('../models');

const getDashboardStats = async (req, res, next) => {
  try {
    const totalUsers = await User.count();
    const totalFarmers = await User.count({ where: { role: 'Farmer' } });
    const totalFarmManagers = await User.count({ where: { role: 'Farm Manager' } });
    const totalCustomers = await User.count({ where: { role: 'Customer' } });
    const totalDrivers = await User.count({ where: { role: 'Delivery Person' } });
    const totalFarms = await Farm.count();
    const totalDevices = await Device.count();
    const totalOrders = await Order.count();
    const totalProducts = await Product.count();

    const orders = await Order.findAll({ attributes: ['totalAmount', 'status', 'paymentStatus'] });
    const totalRevenue = orders.reduce((sum, order) => sum + parseFloat(order.totalAmount || 0), 0);

    return res.json({
      stats: {
        totalUsers,
        totalFarmers,
        totalFarmManagers,
        totalCustomers,
        totalDrivers,
        totalFarms,
        totalDevices,
        totalOrders,
        totalProducts,
        totalRevenue: parseFloat(totalRevenue.toFixed(0)),
        currency: 'FCFA'
      }
    });
  } catch (error) {
    next(error);
  }
};

const getReports = async (req, res, next) => {
  try {
    const orders = await Order.findAll({
      include: [{ model: User, as: 'customer', attributes: ['name', 'email'] }]
    });

    const totalSales = orders.length;
    const totalRevenue = orders.reduce((sum, o) => sum + parseFloat(o.totalAmount || 0), 0);
    const paidOrdersCount = orders.filter(o => o.paymentStatus === 'paid').length;
    const deliveredOrdersCount = orders.filter(o => o.status === 'delivered').length;

    const farmCount = await Farm.count();
    const activeDeviceCount = await Device.count({ where: { status: 'active' } });

    return res.json({
      reports: {
        totalSales,
        totalRevenue: parseFloat(totalRevenue.toFixed(0)),
        currency: 'FCFA',
        paidOrdersCount,
        deliveredOrdersCount,
        farmCount,
        activeDeviceCount,
        generatedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    next(error);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    });

    return res.json({ users });
  } catch (error) {
    next(error);
  }
};

const getFarmers = async (req, res, next) => {
  try {
    const farmers = await User.findAll({
      where: { role: 'Farmer' },
      attributes: { exclude: ['password'] },
      include: [{ model: Farm, as: 'farms' }]
    });

    return res.json({ farmers });
  } catch (error) {
    next(error);
  }
};

const createFarmer = async (req, res, next) => {
  try {
    const { generateFarmerId, generateFarmId } = require('../utils/idGenerator');
    const { name, email, password, phone, cniNumber, address, farmName, farmLocation } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered.' });
    }

    if (cniNumber) {
      const existingCni = await User.findOne({ where: { cniNumber } });
      if (existingCni) {
        return res.status(400).json({ message: 'CNI Number is already registered to another account.' });
      }
    }

    const farmerId = await generateFarmerId(User);

    const user = await User.create({
      name,
      email,
      password,
      role: 'Farmer',
      phone: phone || null,
      cniNumber: cniNumber || null,
      farmerId,
      address: address || null,
      status: 'active',
      approvedAt: new Date(),
      approvedBy: req.user ? req.user.id : null
    });

    let farm = null;
    if (farmName && farmLocation) {
      const generatedFarmId = await generateFarmId(Farm);
      farm = await Farm.create({
        farmId: generatedFarmId,
        name: farmName,
        location: farmLocation,
        farmerId: user.id,
        status: 'approved',
        approvedAt: new Date(),
        approvedBy: req.user ? req.user.id : null
      });
    }

    return res.status(201).json({
      message: 'Farmer account created successfully.',
      farmer: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        phone: user.phone,
        cniNumber: user.cniNumber,
        farmerId: user.farmerId,
        address: user.address,
        farm: farm ? { id: farm.id, farmId: farm.farmId, name: farm.name, location: farm.location } : null
      }
    });
  } catch (error) {
    next(error);
  }
};

const getFarmManagers = async (req, res, next) => {
  try {
    const farmManagers = await User.findAll({
      where: { role: 'Farm Manager' },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    });

    return res.json({ farmManagers });
  } catch (error) {
    next(error);
  }
};

const createUser = async (req, res, next) => {
  try {
    const { generateFarmerId, generateDeliveryPersonId } = require('../utils/idGenerator');
    const { name, email, password, role, phone, address, avatarUrl, cniNumber, vehicleType, vehiclePlateNumber } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered.' });
    }

    const validRoles = ['Administrator', 'Farmer', 'Customer', 'Delivery Person'];
    const assignedRole = validRoles.includes(role) ? role : 'Customer';

    let farmerId = null;
    let deliveryPersonId = null;
    if (assignedRole === 'Farmer') {
      farmerId = await generateFarmerId(User);
    } else if (assignedRole === 'Delivery Person') {
      deliveryPersonId = await generateDeliveryPersonId(User);
    }

    const user = await User.create({
      name,
      email,
      password,
      role: assignedRole,
      phone,
      cniNumber: cniNumber || null,
      farmerId,
      deliveryPersonId,
      vehicleType: vehicleType || null,
      vehiclePlateNumber: vehiclePlateNumber || null,
      address,
      avatarUrl,
      status: 'active'
    });

    return res.status(201).json({
      message: 'User created successfully by Admin',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        phone: user.phone,
        cniNumber: user.cniNumber,
        farmerId: user.farmerId,
        deliveryPersonId: user.deliveryPersonId,
        address: user.address
      }
    });
  } catch (error) {
    next(error);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const { name, email, role, phone, address, avatarUrl } = req.body;
    if (name) user.name = name;
    if (email) user.email = email;
    if (role) user.role = role;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;
    if (avatarUrl !== undefined) user.avatarUrl = avatarUrl;

    await user.save();

    return res.json({ message: 'User updated successfully', user });
  } catch (error) {
    next(error);
  }
};

const setUserStatus = async (req, res, next) => {
  try {
    const { status, reason } = req.body;
    if (!['active', 'pending', 'rejected', 'suspended', 'blocked'].includes(status)) {
      return res.status(400).json({ message: "Status must be 'active', 'pending', 'rejected', 'suspended', or 'blocked'." });
    }

    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.status = status;
    if (status === 'rejected' && reason) {
      user.rejectionReason = reason;
    }
    if (status === 'active') {
      user.approvedAt = new Date();
      user.approvedBy = req.user.id;
      user.rejectionReason = null;
    }
    await user.save();

    await Notification.create({
      userId: user.id,
      title: `Account Status Update: ${status.toUpperCase()}`,
      message: `Your NOVARA account status has been updated to '${status}' by an administrator.${reason ? ` Reason: ${reason}` : ''}`,
      type: 'system'
    });

    return res.json({ message: `User account is now '${status}'`, user: { id: user.id, name: user.name, status: user.status } });
  } catch (error) {
    next(error);
  }
};

const getPendingApprovals = async (req, res, next) => {
  try {
    const pendingFarmers = (await User.findAll({
      where: { role: 'Farmer', status: 'pending' },
      attributes: { exclude: ['password'] },
      include: [{ model: Farm, as: 'farms' }],
      order: [['createdAt', 'DESC']]
    })) || [];

    const pendingDrivers = (await User.findAll({
      where: { role: 'Delivery Person', status: 'pending' },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    })) || [];

    const pendingFarms = (await Farm.findAll({
      where: { status: 'pending' },
      include: [{ model: User, as: 'farmer', attributes: ['id', 'name', 'email', 'phone'] }],
      order: [['createdAt', 'DESC']]
    })) || [];

    const pendingFarmManagers = (await User.findAll({
      where: { role: 'Farm Manager', status: 'pending' },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    })) || [];

    return res.json({
      pendingFarmers,
      pendingDrivers,
      pendingFarms,
      pendingFarmManagers,
      totalPending: pendingFarmers.length + pendingDrivers.length + pendingFarms.length + pendingFarmManagers.length
    });
  } catch (error) {
    next(error);
  }
};

const approveFarmManager = async (req, res, next) => {
  try {
    const { id } = req.params;
    const manager = await User.findOne({ where: { id, role: 'Farm Manager' } });
    if (!manager) {
      return res.status(404).json({ message: 'Farm Manager not found.' });
    }

    manager.status = 'active';
    manager.approvedAt = new Date();
    manager.approvedBy = req.user.id;
    manager.rejectionReason = null;
    await manager.save();

    await Notification.create({
      userId: manager.id,
      title: 'Farm Manager Account Approved! Welcome to NOVARA Operations',
      message: 'Your Farm Manager account has been verified and approved by the Administrator. You now have full operational oversight and approval authority over Farmers and Logistics Couriers.',
      type: 'system'
    });

    return res.json({
      message: 'Farm Manager account approved successfully.',
      farmManager: {
        id: manager.id,
        name: manager.name,
        email: manager.email,
        role: manager.role,
        status: manager.status,
        farmManagerId: manager.farmManagerId,
        approvedAt: manager.approvedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

const rejectFarmManager = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const manager = await User.findOne({ where: { id, role: 'Farm Manager' } });
    if (!manager) {
      return res.status(404).json({ message: 'Farm Manager not found.' });
    }

    const rejectionReason = reason && reason.trim().length > 0
      ? reason.trim()
      : 'Farm Manager registration details could not be validated or did not meet administrator criteria.';

    manager.status = 'rejected';
    manager.rejectionReason = rejectionReason;
    await manager.save();

    await Notification.create({
      userId: manager.id,
      title: 'Farm Manager Application Declined',
      message: `Your Farm Manager application was declined. Reason: ${rejectionReason}`,
      type: 'system'
    });

    return res.json({
      message: 'Farm Manager registration rejected.',
      farmManager: {
        id: manager.id,
        name: manager.name,
        email: manager.email,
        status: manager.status,
        rejectionReason: manager.rejectionReason
      }
    });
  } catch (error) {
    next(error);
  }
};

const approveFarmer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const farmer = await User.findOne({ where: { id, role: 'Farmer' } });
    if (!farmer) {
      return res.status(404).json({ message: 'Farmer not found.' });
    }

    farmer.status = 'active';
    farmer.approvedAt = new Date();
    farmer.approvedBy = req.user.id;
    farmer.rejectionReason = null;
    await farmer.save();

    // Also approve all pending farms created by this farmer during registration
    await Farm.update(
      { status: 'approved', approvedAt: new Date(), approvedBy: req.user.id, rejectionReason: null },
      { where: { farmerId: farmer.id, status: 'pending' } }
    );

    await Notification.create({
      userId: farmer.id,
      title: 'Farmer Account Approved! Welcome to NOVARA',
      message: 'Your farmer account and poultry farm have been officially approved by the administrator. You can now access full farm monitoring, flock management, and product listings.',
      type: 'system'
    });

    return res.json({
      message: 'Farmer account and associated farms have been approved successfully.',
      farmer: {
        id: farmer.id,
        name: farmer.name,
        email: farmer.email,
        role: farmer.role,
        status: farmer.status,
        approvedAt: farmer.approvedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

const rejectFarmer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const farmer = await User.findOne({ where: { id, role: 'Farmer' } });
    if (!farmer) {
      return res.status(404).json({ message: 'Farmer not found.' });
    }

    const rejectionReason = reason && reason.trim().length > 0
      ? reason.trim()
      : 'Farm registration details could not be validated or did not meet platform criteria.';

    farmer.status = 'rejected';
    farmer.rejectionReason = rejectionReason;
    await farmer.save();

    await Farm.update(
      { status: 'rejected', rejectionReason },
      { where: { farmerId: farmer.id, status: 'pending' } }
    );

    await Notification.create({
      userId: farmer.id,
      title: 'Registration Application Declined',
      message: `Your farmer registration application was declined. Reason: ${rejectionReason}`,
      type: 'system'
    });

    return res.json({
      message: 'Farmer registration rejected.',
      farmer: {
        id: farmer.id,
        name: farmer.name,
        email: farmer.email,
        status: farmer.status,
        rejectionReason: farmer.rejectionReason
      }
    });
  } catch (error) {
    next(error);
  }
};

const approveDeliveryPerson = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driver = await User.findOne({ where: { id, role: 'Delivery Person' } });
    if (!driver) {
      return res.status(404).json({ message: 'Delivery Person not found.' });
    }

    driver.status = 'active';
    driver.approvedAt = new Date();
    driver.approvedBy = req.user.id;
    driver.rejectionReason = null;
    await driver.save();

    await Notification.create({
      userId: driver.id,
      title: 'Delivery Account Approved! Welcome to NOVARA Logistics',
      message: 'Your courier account has been validated and approved. You can now accept deliveries and manage live dispatches.',
      type: 'system'
    });

    return res.json({
      message: 'Delivery person account approved successfully.',
      driver: {
        id: driver.id,
        name: driver.name,
        email: driver.email,
        role: driver.role,
        status: driver.status,
        approvedAt: driver.approvedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

const rejectDeliveryPerson = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const driver = await User.findOne({ where: { id, role: 'Delivery Person' } });
    if (!driver) {
      return res.status(404).json({ message: 'Delivery Person not found.' });
    }

    const rejectionReason = reason && reason.trim().length > 0
      ? reason.trim()
      : 'Delivery person background verification could not be completed.';

    driver.status = 'rejected';
    driver.rejectionReason = rejectionReason;
    await driver.save();

    await Notification.create({
      userId: driver.id,
      title: 'Delivery Application Declined',
      message: `Your courier registration was declined. Reason: ${rejectionReason}`,
      type: 'system'
    });

    return res.json({
      message: 'Delivery person registration rejected.',
      driver: {
        id: driver.id,
        name: driver.name,
        email: driver.email,
        status: driver.status,
        rejectionReason: driver.rejectionReason
      }
    });
  } catch (error) {
    next(error);
  }
};

const approveFarm = async (req, res, next) => {
  try {
    const { id } = req.params;
    const farm = await Farm.findByPk(id);
    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    farm.status = 'approved';
    farm.approvedAt = new Date();
    farm.approvedBy = req.user.id;
    farm.rejectionReason = null;
    await farm.save();

    await Notification.create({
      userId: farm.farmerId,
      title: 'Farm Approved',
      message: `Your farm '${farm.name}' has been approved by an administrator.`,
      type: 'system'
    });

    return res.json({ message: 'Farm approved successfully.', farm });
  } catch (error) {
    next(error);
  }
};

const rejectFarm = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const farm = await Farm.findByPk(id);
    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    const rejectionReason = reason && reason.trim().length > 0
      ? reason.trim()
      : 'Farm specifications could not be verified.';

    farm.status = 'rejected';
    farm.rejectionReason = rejectionReason;
    await farm.save();

    await Notification.create({
      userId: farm.farmerId,
      title: 'Farm Registration Declined',
      message: `Your farm '${farm.name}' was not approved. Reason: ${rejectionReason}`,
      type: 'system'
    });

    return res.json({ message: 'Farm registration rejected.', farm });
  } catch (error) {
    next(error);
  }
};

const deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    await user.destroy();
    return res.json({ message: 'User deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getDashboardStats,
  getReports,
  getAllUsers,
  getFarmers,
  getFarmManagers,
  createUser,
  createFarmer,
  updateUser,
  setUserStatus,
  getPendingApprovals,
  approveFarmManager,
  rejectFarmManager,
  approveFarmer,
  rejectFarmer,
  approveDeliveryPerson,
  rejectDeliveryPerson,
  approveFarm,
  rejectFarm,
  deleteUser
};
