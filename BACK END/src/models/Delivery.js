const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Delivery = sequelize.define('Delivery', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  orderId: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true
  },
  deliveryPersonId: {
    type: DataTypes.UUID,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('unassigned', 'assigned', 'accepted', 'picked_up', 'delivered', 'failed', 'delayed'),
    defaultValue: 'unassigned'
  },
  isDelayed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  delayReason: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  pickupAddress: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  dropoffAddress: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  assignedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  deliveredAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  confirmedAt: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  timestamps: true
});

module.exports = Delivery;
