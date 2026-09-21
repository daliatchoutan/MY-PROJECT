const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  role: {
    type: DataTypes.ENUM('Administrator', 'Farmer', 'Customer', 'Delivery Person'),
    allowNull: false,
    defaultValue: 'Customer'
  },
  status: {
    type: DataTypes.ENUM('pending', 'active', 'rejected', 'suspended', 'blocked'),
    allowNull: false,
    defaultValue: 'active'
  },
  rejectionReason: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  approvedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  approvedBy: {
    type: DataTypes.UUID,
    allowNull: true
  },
  avatarUrl: {
    type: DataTypes.STRING,
    allowNull: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  cniNumber: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  },
  farmerId: {
    type: DataTypes.STRING(64),
    allowNull: true,
    unique: true
  },
  professionalLicenseNumber: {
    type: DataTypes.STRING,
    allowNull: true
  },
  deliveryPersonId: {
    type: DataTypes.STRING(64),
    allowNull: true,
    unique: true
  },
  driverLicenseNumber: {
    type: DataTypes.STRING,
    allowNull: true
  },
  vehicleType: {
    type: DataTypes.STRING(64),
    allowNull: true
  },
  vehiclePlateNumber: {
    type: DataTypes.STRING(64),
    allowNull: true
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  lastLoginAt: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  timestamps: true,
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      }
    }
  }
});

User.prototype.validPassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = User;
