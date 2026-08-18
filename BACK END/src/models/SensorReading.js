const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SensorReading = sequelize.define('SensorReading', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  deviceId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  foodLevel: {
    type: DataTypes.FLOAT, // %
    allowNull: true
  },
  waterLevel: {
    type: DataTypes.FLOAT, // %
    allowNull: true
  },
  temperature: {
    type: DataTypes.FLOAT, // °C
    allowNull: true
  },
  humidity: {
    type: DataTypes.FLOAT, // %
    allowNull: true
  }
}, {
  timestamps: true,
  indexes: [
    { fields: ['deviceId'] },
    { fields: ['createdAt'] }
  ]
});

module.exports = SensorReading;
