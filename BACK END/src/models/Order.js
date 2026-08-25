const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  customerId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  totalAmount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false
  },
  currency: {
    type: DataTypes.STRING,
    defaultValue: 'FCFA'
  },
  status: {
    type: DataTypes.ENUM('pending', 'accepted', 'rejected', 'in_transit', 'delivered', 'cancelled'),
    defaultValue: 'pending'
  },
  paymentStatus: {
    type: DataTypes.ENUM('pending', 'paid', 'failed'),
    defaultValue: 'pending'
  },
  paymentMethod: {
    type: DataTypes.STRING, // e.g., 'MTN Mobile Money', 'Orange Money', 'Credit Card'
    allowNull: true
  },
  shippingAddress: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  timestamps: true
});

module.exports = Order;
