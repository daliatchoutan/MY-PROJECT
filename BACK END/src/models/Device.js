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
  farmId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  // Automation Thresholds
  foodThreshold: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0 // Low level trigger (%)
  },
  waterThreshold: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0 // Low level trigger (%)
  },
  tempMin: {
    type: DataTypes.FLOAT,
    defaultValue: 20.0 // Min °C
  },
  tempMax: {
    type: DataTypes.FLOAT,
    defaultValue: 32.0 // Max °C
  },
  humidityMin: {
    type: DataTypes.FLOAT,
    defaultValue: 50.0 // Min %
  },
  humidityMax: {
    type: DataTypes.FLOAT,
    defaultValue: 75.0 // Max %
  }
}, {
  timestamps: true
});

module.exports = Device;
