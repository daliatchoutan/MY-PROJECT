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
const managerRoutes = require('./src/routes/managerRoutes');

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
app.use('/api/manager', managerRoutes);

// App Version check for automated in-app OTA updates
app.get('/api/app/version', (req, res) => {
  const versionInfo = {
    appName: 'NOVARA Smart Poultry Farm',
    version: '1.0.2',
    buildNumber: 3,
    releaseNotes: '• Resolved Android photo upload & camera permissions in APK\n• Added Farm Manager operational role & multi-tier governance\n• Live stock tracking & out-of-stock alternative recommendations\n• Updated Pinterest-grade feed photography\n• Automated in-app update system',
    apkDownloadUrl: `${req.protocol}://${req.get('host')}/download/novara-latest.apk`,
    webAppUrl: 'https://novara-poultry.netlify.app/',
    forceUpdate: false,
    updatedAt: new Date().toISOString()
  };
  res.json(versionInfo);
});

// Dedicated APK download endpoint
const downloadDir = path.join(__dirname, 'public', 'download');
if (!fs.existsSync(downloadDir)) {
  fs.mkdirSync(downloadDir, { recursive: true });
}
app.get('/download/novara-latest.apk', (req, res) => {
  const apkPath = path.join(downloadDir, 'novara-latest.apk');
  if (fs.existsSync(apkPath)) {
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', 'attachment; filename="NOVARA-SmartPoultry.apk"');
    return res.sendFile(apkPath);
  }
  return res.status(404).json({ error: 'APK release file is currently being built. Please check back shortly.' });
});
app.use('/download', express.static(downloadDir));

// Flutter Web Application Static Serving & SPA Routing
const publicWebDir = path.join(__dirname, 'public');
if (fs.existsSync(publicWebDir)) {
  app.use(express.static(publicWebDir));

  // Express 5 SPA fallback: Return index.html for non-API, non-upload, non-download GET requests
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api') && !req.path.startsWith('/uploads') && !req.path.startsWith('/download')) {
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

      // Ensure default farm and initial products exist if catalog is empty
      const { Farm, Product } = require('./src/models');
      const productCount = await Product.count();
      if (productCount === 0) {
        let demoFarm = await Farm.findOne({ where: { status: 'approved' } });
        if (!demoFarm) {
          demoFarm = await Farm.create({
            name: 'NOVARA Demonstration Poultry Farm',
            location: 'Yaoundé - Obala Agro-Hub',
            capacity: 5000,
            flockType: 'Broilers & Layers',
            farmerId: admin ? admin.id : null,
            status: 'approved'
          });
        }

        await Product.bulkCreate([
          {
            farmId: demoFarm.id,
            name: 'Live Broiler Chicken',
            description: 'Healthy, prime-weight broiler chicken ready for fresh processing.',
            price: 4500,
            stockQuantity: 250,
            unit: 'bird',
            category: 'Live Poultry',
            imageUrl: '/uploads/products/product_broiler.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Layer Hen (Point of Lay)',
            description: 'Vaccinated point-of-lay layer hen for high-yield egg production.',
            price: 6000,
            stockQuantity: 200,
            unit: 'bird',
            category: 'Live Poultry',
            imageUrl: '/uploads/products/product_layer.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Day-old Chicks (Pack of 50)',
            description: 'Certified vaccinated day-old broiler and layer chicks.',
            price: 35000,
            stockQuantity: 150,
            unit: 'pack',
            category: 'Live Poultry',
            imageUrl: '/uploads/products/product_chicks.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Mature Rooster (Cockerel)',
            description: 'Vigorous, mature cockerel for quality breeding and culinary delight.',
            price: 6500,
            stockQuantity: 100,
            unit: 'bird',
            category: 'Live Poultry',
            imageUrl: '/uploads/products/product_rooster.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Farm-Fresh Whole Chicken',
            description: 'Dressed and chilled farm-fresh chicken, inspected for highest quality.',
            price: 4000,
            stockQuantity: 180,
            unit: 'chicken',
            category: 'Poultry Meat',
            imageUrl: '/uploads/products/product_fresh_chicken.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Fresh Chicken Breast & Cuts',
            description: 'Boneless tender cuts, hygienic and vacuum sealed.',
            price: 3500,
            stockQuantity: 160,
            unit: 'kg',
            category: 'Poultry Meat',
            imageUrl: '/uploads/products/product_meat.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Organic Brown Eggs (Tray of 30)',
            description: 'Locally collected organic brown eggs from grain-fed hens.',
            price: 3500,
            stockQuantity: 400,
            unit: 'tray',
            category: 'Eggs',
            imageUrl: '/uploads/products/product_brown_eggs.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Farm-Fresh Table Eggs (Pack of 12)',
            description: 'Carefully sorted table eggs in eco-friendly carton packaging.',
            price: 1500,
            stockQuantity: 350,
            unit: 'pack',
            category: 'Eggs',
            imageUrl: '/uploads/products/product_eggs.jpg',
            isAvailable: true
          },
          {
            farmId: demoFarm.id,
            name: 'Nutritional Poultry Feed (Starter & Finisher)',
            description: 'Balanced protein-dense poultry feed with essential micronutrients.',
            price: 18500,
            stockQuantity: 120,
            unit: '50kg bag',
            category: 'Poultry Feed',
            imageUrl: '/uploads/products/product_feed.jpg',
            isAvailable: true
          }
        ]);
        console.log(' Default poultry products catalog automatically initialized with live stock.');
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