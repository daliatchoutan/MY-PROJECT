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

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    system: 'NOVARA Smart Poultry Farm Automation API',
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

// Flutter Web Application Static Serving & SPA Routing
const publicWebDir = path.join(__dirname, 'public');
if (fs.existsSync(publicWebDir)) {
  app.use(express.static(publicWebDir));

  // Express 5 SPA fallback: Return index.html for non-API, non-upload GET requests
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api') && !req.path.startsWith('/uploads')) {
      return res.sendFile(path.join(publicWebDir, 'index.html'));
    }
    next();
  });
} else {
  app.get('/', (req, res) => {
    res.json({
      status: 'online',
      system: 'NOVARA Smart Poultry Farm API',
      timestamp: new Date().toISOString()
    });
  });
}

// 404 Handler for undefined API routes
app.use((req, res, next) => {
  res.status(404).json({ message: `Route '${req.originalUrl}' not found.` });
});

// Global Error Handler
app.use(errorHandler);

// Start server immediately so cloud orchestrators (Railway/Render) detect healthy port
const server = app.listen(port, '0.0.0.0', () => {
  console.log(` Smart Poultry Farm Backend listening on 0.0.0.0:${port}`);
});

// Dedicated Endpoint to Ensure Administrator Ben Exists
app.all('/api/setup-admin', async (req, res) => {
  try {
    const { User } = require('./src/models');
    const adminEmail = 'ben@gmail.com';
    let admin = await User.findOne({ where: { email: adminEmail } });
    if (!admin) {
      admin = await User.create({
        name: 'Ben',
        email: adminEmail,
        password: '11111111',
        role: 'Administrator',
        status: 'active',
        phone: '+237 600 000 001'
      });
      return res.json({
        message: "Administrator account 'Ben' created successfully!",
        user: { id: admin.id, name: admin.name, email: admin.email, role: admin.role, status: admin.status }
      });
    } else {
      admin.name = 'Ben';
      admin.role = 'Administrator';
      admin.status = 'active';
      admin.password = '11111111';
      await admin.save();
      return res.json({
        message: "Administrator account 'Ben' updated with role Administrator and active status!",
        user: { id: admin.id, name: admin.name, email: admin.email, role: admin.role, status: admin.status }
      });
    }
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
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

    // Ensure requested Administrator 'Ben' exists with active status and role Administrator
    try {
      const { User } = require('./src/models');
      const adminEmail = 'ben@gmail.com';
      let admin = await User.findOne({ where: { email: adminEmail } });
      if (!admin) {
        await User.create({
          name: 'Ben',
          email: adminEmail,
          password: '11111111',
          role: 'Administrator',
          status: 'active',
          phone: '+237 600 000 001'
        });
        console.log(` Administrator 'Ben' (${adminEmail}) created successfully.`);
      } else {
        admin.name = 'Ben';
        admin.role = 'Administrator';
        admin.status = 'active';
        admin.password = '11111111';
        await admin.save();
        console.log(` Administrator 'Ben' (${adminEmail}) verified and updated with active role.`);
      }
    } catch (adminErr) {
      console.error('Notice ensuring Administrator Ben:', adminErr.message);
    }
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