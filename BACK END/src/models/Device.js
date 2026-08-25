const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Device = sequelize.define('Device', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  deviceSerial: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  type: {
    type: DataTypes.STRING, // e.g. ESP32, Camera, Multi-Sensor
    defaultValue: 'ESP32'
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'maintenance'),
    defaultValue: 'active'
  },
  autoMode: {
    type: DataTypes.BOOLEAN,
    defaultValue: true // true = automatic threshold control, false = manual control
  },
  healthStatus: {
    type: DataTypes.ENUM('excellent', 'good', 'warning', 'critical'),
    defaultValue: 'good'
  },
  farmId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  // Automation Thresholds
  foodThreshold: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0
  },
  waterThreshold: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0
  },
  tempMin: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0
  },
  tempMax: {
    type: DataTypes.FLOAT,
    defaultValue: 32.0
  },
  humidityMin: {
    type: DataTypes.FLOAT,
    defaultValue: 50.0
  },
  humidityMax: {
    type: DataTypes.FLOAT,
    defaultValue: 75.0
  }
}, {
  timestamps: true
});

module.exports = Device;
