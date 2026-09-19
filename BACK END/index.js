const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

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

// Ensure uploads directories exist
const uploadsDir = path.join(__dirname, 'uploads');
const productUploadsDir = path.join(uploadsDir, 'products');
if (!fs.existsSync(productUploadsDir)) {
  fs.mkdirSync(productUploadsDir, { recursive: true });
}

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Static file serving for uploaded product & farm images
app.use('/uploads', express.static(uploadsDir));

// Health Check Endpoints
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    system: 'NOVARA Smart Poultry Farm API',
    timestamp: new Date().toISOString()
  });
});

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

// Backup Seed Endpoint (restores users, farms, products, devices if needed)
app.all('/api/seed-backup', async (req, res) => {
  try {
    const { autoSeedBackup } = require('./src/config/seedBackup');
    const force = req.query.force === 'true' || req.body?.force === true;
    const result = await autoSeedBackup(force);
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({ message: `Route '${req.originalUrl}' not found.` });
});

// Global Error Handler
app.use(errorHandler);

// Start server immediately so cloud orchestrators (Railway/Render) detect healthy port
const server = app.listen(port, '0.0.0.0', () => {
  console.log(` Smart Poultry Farm Backend listening on 0.0.0.0:${port}`);
});

const initDatabase = async () => {
  try {
    const { ensureDatabaseExists } = require('./src/config/database');
    if (ensureDatabaseExists) {
      await ensureDatabaseExists();
    }

    await sequelize.authenticate();
    console.log(' Database connection established successfully.');

    // Sync database models safely
    await sequelize.sync();
    console.log(' Database models synchronized.');

    // Auto-seed pre-existing data from backup
    const { autoSeedBackup } = require('./src/config/seedBackup');
    await autoSeedBackup();
  } catch (error) {
    console.error(' Database initialization notice:', error.message);
  }
};

process.on('unhandledRejection', (err) => {
  console.error('Process Notice (unhandledRejection):', err ? (err.message || err) : 'Unknown');
});

process.on('uncaughtException', (err) => {
  console.error('Process Notice (uncaughtException):', err ? (err.message || err) : 'Unknown');
});

initDatabase();

module.exports = app;