const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Farm = sequelize.define('Farm', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false
  },
  capacity: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  currentPoultryCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  farmerId: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  timestamps: true
});

module.exports = Farm;
