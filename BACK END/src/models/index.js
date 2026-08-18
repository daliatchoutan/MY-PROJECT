const sequelize = require('../config/database');
const User = require('./User');
const Farm = require('./Farm');
const Device = require('./Device');
const SensorReading = require('./SensorReading');
const Product = require('./Product');
const Order = require('./Order');
const OrderItem = require('./OrderItem');
const Delivery = require('./Delivery');
const Notification = require('./Notification');

// Farmer -> Farms
User.hasMany(Farm, { foreignKey: 'farmerId', as: 'farms' });
Farm.belongsTo(User, { foreignKey: 'farmerId', as: 'farmer' });

// Farm -> Devices
Farm.hasMany(Device, { foreignKey: 'farmId', as: 'devices' });
Device.belongsTo(Farm, { foreignKey: 'farmId', as: 'farm' });

// Device -> SensorReadings
Device.hasMany(SensorReading, { foreignKey: 'deviceId', as: 'readings' });
SensorReading.belongsTo(Device, { foreignKey: 'deviceId', as: 'device' });

// Farm -> Products
Farm.hasMany(Product, { foreignKey: 'farmId', as: 'products' });
Product.belongsTo(Farm, { foreignKey: 'farmId', as: 'farm' });

// Customer -> Orders
User.hasMany(Order, { foreignKey: 'customerId', as: 'orders' });
Order.belongsTo(User, { foreignKey: 'customerId', as: 'customer' });

// Order -> OrderItems
Order.hasMany(OrderItem, { foreignKey: 'orderId', as: 'items' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

// Product -> OrderItems
Product.hasMany(OrderItem, { foreignKey: 'productId', as: 'orderItems' });
OrderItem.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

// Order -> Delivery
Order.hasOne(Delivery, { foreignKey: 'orderId', as: 'delivery' });
Delivery.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

// Delivery Person -> Deliveries
User.hasMany(Delivery, { foreignKey: 'deliveryPersonId', as: 'deliveries' });
Delivery.belongsTo(User, { foreignKey: 'deliveryPersonId', as: 'deliveryPerson' });

// User -> Notifications
User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'userId', as: 'user' });

module.exports = {
  sequelize,
  User,
  Farm,
  Device,
  SensorReading,
  Product,
  Order,
  OrderItem,
  Delivery,
  Notification
};
