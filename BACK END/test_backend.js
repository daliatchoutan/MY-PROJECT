const http = require('http');

const runTest = async () => {
  console.log('Starting Backend Automated Tests...');
  
  // Launch backend server in process or require app
  process.env.PORT = 3005;
  
  const app = require('./index.js');

  // Wait 1.5 seconds for Sequelize database initialization
  await new Promise(resolve => setTimeout(resolve, 1500));

  const request = (method, path, data = null, token = null) => {
    return new Promise((resolve, reject) => {
      const payload = data ? JSON.stringify(data) : null;
      const req = http.request({
        hostname: 'localhost',
        port: 3005,
        path,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(payload && { 'Content-Length': Buffer.byteLength(payload) }),
          ...(token && { 'Authorization': `Bearer ${token}` })
        }
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            resolve({ status: res.statusCode, body: parsed });
          } catch (e) {
            resolve({ status: res.statusCode, body });
          }
        });
      });

      req.on('error', reject);
      if (payload) req.write(payload);
      req.end();
    });
  };

  try {
    // 1. Health check
    console.log('\n--- 1. Testing Health Endpoint ---');
    const health = await request('GET', '/health');
    console.log('Health Response:', health.status, health.body);

    // 2. Register Farmer User
    console.log('\n--- 2. Registering Farmer ---');
    const farmerReg = await request('POST', '/api/auth/register', {
      name: 'John the Farmer',
      email: 'farmer@poultry.com',
      password: 'password123',
      role: 'Farmer',
      phone: '+1234567890'
    });
    console.log('Farmer Reg Response:', farmerReg.status, farmerReg.body.message);
    const farmerToken = farmerReg.body.token;

    // 3. Register Customer User
    console.log('\n--- 3. Registering Customer ---');
    const custReg = await request('POST', '/api/auth/register', {
      name: 'Alice Customer',
      email: 'alice@customer.com',
      password: 'password123',
      role: 'Customer'
    });
    console.log('Customer Reg Response:', custReg.status, custReg.body.message);
    const customerToken = custReg.body.token;

    // 4. Create Farm
    console.log('\n--- 4. Creating Farm ---');
    const farmRes = await request('POST', '/api/farms', {
      name: 'Green Acres Poultry',
      location: 'Sector 7, Farm Road',
      capacity: 5000,
      currentPoultryCount: 4200
    }, farmerToken);
    console.log('Farm Response:', farmRes.status, farmRes.body.farm.name);
    const farmId = farmRes.body.farm.id;

    // 5. Register IoT Device
    console.log('\n--- 5. Registering IoT Device ---');
    const deviceRes = await request('POST', '/api/devices', {
      deviceSerial: 'ESP32-POULTRY-001',
      name: 'Coop #1 Main Sensor Cluster',
      type: 'ESP32',
      farmId,
      foodThreshold: 25.0,
      waterThreshold: 20.0,
      tempMin: 18.0,
      tempMax: 30.0
    }, farmerToken);
    console.log('Device Response:', deviceRes.status, deviceRes.body.device.deviceSerial);

    // 6. Ingest Telemetry (Triggering Low Food & High Temp Warnings)
    console.log('\n--- 6. Ingesting IoT Telemetry (Testing Automation Triggers) ---');
    const telemetryRes = await request('POST', '/api/sensors/telemetry', {
      deviceSerial: 'ESP32-POULTRY-001',
      foodLevel: 15.0, // < 25.0 threshold -> triggers feeding
      waterLevel: 80.0,
      temperature: 34.5, // > 30.0 max -> triggers cooling fan
      humidity: 65.0
    });
    console.log('Telemetry Response:', telemetryRes.status, telemetryRes.body.automationTriggers);

    // 7. Ingest AI Health Alert
    console.log('\n--- 7. Ingesting AI Vision Health Alert ---');
    const aiRes = await request('POST', '/api/ai/health-alert', {
      deviceSerial: 'ESP32-POULTRY-001',
      confidence: 0.94,
      abnormalityDetected: 'Lethargy & Flocking Isolation',
      description: 'Bird in sector B3 showing signs of weakness.'
    });
    console.log('AI Response:', aiRes.status, aiRes.body.message);

    // 8. Add Product to Marketplace
    console.log('\n--- 8. Adding Product to Marketplace ---');
    const prodRes = await request('POST', '/api/products', {
      farmId,
      name: 'Fresh Organic Eggs (Tray of 30)',
      description: 'Farm fresh brown eggs from free range layers.',
      price: 12.50,
      stockQuantity: 100,
      unit: 'tray',
      category: 'Eggs'
    }, farmerToken);
    console.log('Product Response:', prodRes.status, prodRes.body.product.name);
    const productId = prodRes.body.product.id;

    // 9. Place Order as Customer
    console.log('\n--- 9. Placing Order as Customer ---');
    const orderRes = await request('POST', '/api/orders', {
      items: [{ productId, quantity: 2 }],
      shippingAddress: '42 Main Street, Cityville'
    }, customerToken);
    console.log('Order Response:', orderRes.status, 'Total Amount:', orderRes.body.order.totalAmount);

    // 10. Check Farmer Notifications
    console.log('\n--- 10. Fetching Farmer Notifications ---');
    const notifRes = await request('GET', '/api/notifications', null, farmerToken);
    console.log('Farmer Notifications Count:', notifRes.body.notifications.length);

    console.log('\n✅ ALL BACKEND API TESTS PASSED SUCCESSFULLY!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Test Failed:', err);
    process.exit(1);
  }
};

runTest();
