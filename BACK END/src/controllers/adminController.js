const { User, Farm, Device, Order, Product, Notification } = require('../models');

const getDashboardStats = async (req, res, next) => {
  try {
    const totalUsers = await User.count();
    const totalFarmers = await User.count({ where: { role: 'Farmer' } });
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

const createUser = async (req, res, next) => {
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
    const { status } = req.body; // 'active', 'suspended', 'blocked'
    if (!['active', 'suspended', 'blocked'].includes(status)) {
      return res.status(400).json({ message: "Status must be 'active', 'suspended', or 'blocked'." });
    }

    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.status = status;
    await user.save();

    await Notification.create({
      userId: user.id,
      title: `Account Status Update: ${status.toUpperCase()}`,
      message: `Your NOVARA account status has been updated to '${status}' by an administrator.`,
      type: 'system'
    });

    return res.json({ message: `User account is now '${status}'`, user: { id: user.id, name: user.name, status: user.status } });
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
  createUser,
  updateUser,
  setUserStatus,
  deleteUser
};
