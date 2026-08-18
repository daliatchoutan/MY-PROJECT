const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

const { sequelize } = require('./src/models');
const errorHandler = require('./src/middleware/errorHandler');

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const farmRoutes = require('./src/routes/farmRoutes');
const deviceRoutes = require('./src/routes/deviceRoutes');
const sensorRoutes = require('./src/routes/sensorRoutes');
const aiRoutes = require('./src/routes/aiRoutes');
const productRoutes = require('./src/routes/productRoutes');
const orderRoutes = require('./src/routes/orderRoutes');
const deliveryRoutes = require('./src/routes/deliveryRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');
const adminRoutes = require('./src/routes/adminRoutes');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    system: 'Smart Poultry Farm Automation API',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/farms', farmRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/sensors', sensorRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/deliveries', deliveryRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({ message: `Route '${req.originalUrl}' not found.` });
});

// Global Error Handler
app.use(errorHandler);

// Database Sync and Server Startup
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log(' Database connection established successfully.');

    // Sync database models (alter in dev mode)
    await sequelize.sync({ alter: false });
    console.log(' Database models synchronized.');

    app.listen(port, () => {
      console.log(` Smart Poultry Farm Backend listening on port ${port}`);
    });
  } catch (error) {
    console.error(' Failed to start server:', error);
  }
};

startServer();

module.exports = app;