const { User, Farm, Device, Order, Product } = require('../models');

const getDashboardStats = async (req, res, next) => {
  try {
    const totalUsers = await User.count();
    const totalFarms = await Farm.count();
    const totalDevices = await Device.count();
    const totalOrders = await Order.count();
    const totalProducts = await Product.count();

    const orders = await Order.findAll({ attributes: ['totalAmount', 'status'] });
    const totalRevenue = orders.reduce((sum, order) => sum + parseFloat(order.totalAmount || 0), 0);

    return res.json({
      stats: {
        totalUsers,
        totalFarms,
        totalDevices,
        totalOrders,
        totalProducts,
        totalRevenue: parseFloat(totalRevenue.toFixed(2))
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

const updateUserRole = async (req, res, next) => {
  try {
    const { role } = req.body;
    const validRoles = ['Administrator', 'Farmer', 'Customer', 'Delivery Person'];

    if (!validRoles.includes(role)) {
      return res.status(400).json({ message: `Invalid role '${role}'.` });
    }

    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.role = role;
    await user.save();

    return res.json({ message: 'User role updated successfully', user: { id: user.id, name: user.name, role: user.role } });
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
  getAllUsers,
  updateUserRole,
  deleteUser
};
