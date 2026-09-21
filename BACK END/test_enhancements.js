const app = require('./index');
const { sequelize, User, Farm, Order, Delivery, Product, OrderItem } = require('./src/models');
const { ensureDatabaseExists } = require('./src/config/database');

async function runTests() {
  console.log('--- Starting NOVARA Automated Verification Suite ---\n');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(` PASS: ${message}`);
      passed++;
    } else {
      console.error(` FAIL: ${message}`);
      failed++;
    }
  }

  // Ensure database sync & safe column additions
  await ensureDatabaseExists();
  await sequelize.sync();

  const server = app.listen(5099);
  const baseUrl = 'http://127.0.0.1:5099';

  try {
    // 1. Farmer Registration
    console.log('\n[Test 1: Farmer Registration]');
    const farmerEmail = `farmer_${Date.now()}@testnovara.cm`;
    const farmerCni = `CNI-${Date.now()}`;
    const farmerReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Papa Kouam',
        email: farmerEmail,
        password: 'Password123!',
        confirmPassword: 'Password123!',
        role: 'Farmer',
        phone: '+237 671 234 567',
        cniNumber: farmerCni,
        professionalLicenseNumber: 'AGRI-CM-2026'
      })
    });
    const farmerRes = await farmerReq.json();

    assert(farmerReq.status === 201, `Farmer registration returned HTTP 201 (got ${farmerReq.status})`);
    assert(farmerRes.user.role === 'Farmer', 'User role is Farmer');
    assert(farmerRes.user.status === 'active', 'Farmer status is active immediately');
    assert(farmerRes.user.cniNumber === farmerCni, 'Farmer CNI number stored');
    assert(/^NOV-FRM-\d{5}$/.test(farmerRes.user.farmerId), `Farmer ID formatted as NOV-FRM-xxxxx (${farmerRes.user.farmerId})`);
    assert(!farmerRes.user.password, 'Password omitted from response');

    // Verify no farm was auto-created
    const farmerFarms = await Farm.findAll({ where: { farmerId: farmerRes.user.id } });
    assert(farmerFarms.length === 0, 'No farm automatically created during farmer registration');

    const farmerToken = farmerRes.token;

    // 2. Farm Creation from Dashboard
    console.log('\n[Test 2: Farm Creation via Farmer Dashboard]');
    const farmReq1 = await fetch(`${baseUrl}/api/farms`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${farmerToken}`
      },
      body: JSON.stringify({
        name: 'Poultry Farm Horizon Alpha',
        location: 'Yaounde, Soa Region',
        capacity: 2500
      })
    });
    const farmRes1 = await farmReq1.json();

    assert(farmReq1.status === 201, `Farm 1 created (got ${farmReq1.status})`);
    assert(/^NOV-FARM-\d{5}$/.test(farmRes1.farm.farmId), `Farm ID formatted as NOV-FARM-xxxxx (${farmRes1.farm.farmId})`);
    assert(farmRes1.farm.status === 'approved', 'Farm status is approved');

    // Create a second farm for same farmer (1-to-many relationship)
    const farmReq2 = await fetch(`${baseUrl}/api/farms`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${farmerToken}`
      },
      body: JSON.stringify({
        name: 'Poultry Farm Horizon Beta',
        location: 'Douala, Bonaberi Region',
        capacity: 5000
      })
    });
    const farmRes2 = await farmReq2.json();

    assert(farmReq2.status === 201, `Farm 2 created for same farmer (got ${farmReq2.status})`);
    assert(/^NOV-FARM-\d{5}$/.test(farmRes2.farm.farmId), `Second Farm ID formatted as NOV-FARM-xxxxx (${farmRes2.farm.farmId})`);
    assert(farmRes1.farm.farmId !== farmRes2.farm.farmId, 'Farm IDs are unique across farms');

    // 3. Delivery Person Registration
    console.log('\n[Test 3: Delivery Person Registration]');
    const driverEmail = `driver_${Date.now()}@testnovara.cm`;
    const driverCni = `CNI-DRV-${Date.now()}`;
    const driverReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Jean Express',
        email: driverEmail,
        password: 'Password123!',
        confirmPassword: 'Password123!',
        role: 'Delivery Person',
        phone: '+237 699 876 543',
        cniNumber: driverCni,
        driverLicenseNumber: 'DL-LT-8871',
        vehicleType: 'Motorcycle',
        vehiclePlateNumber: 'LT 9012 XY',
        avatarUrl: '' // Completely optional profile picture, empty string
      })
    });
    const driverRes = await driverReq.json();

    assert(driverReq.status === 201, `Delivery Person registered (got ${driverReq.status})`);
    assert(driverRes.user.role === 'Delivery Person', 'User role is Delivery Person');
    assert(driverRes.user.status === 'active', 'Delivery Person status is active immediately');
    assert(/^NOV-DRV-\d{5}$/.test(driverRes.user.deliveryPersonId), `Driver ID formatted as NOV-DRV-xxxxx (${driverRes.user.deliveryPersonId})`);
    assert(driverRes.user.vehicleType === 'Motorcycle', 'Vehicle type recorded');
    assert(driverRes.user.vehiclePlateNumber === 'LT 9012 XY', 'Vehicle plate number recorded');

    const driverToken = driverRes.token;
    const driverId = driverRes.user.id;

    // 4. Role Security - Disallow Public Admin Registration
    console.log('\n[Test 4: Strict Role Security]');
    const adminReq1 = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Malicious Admin',
        email: `hacker_${Date.now()}@test.cm`,
        password: 'Password123!',
        role: 'Administrator'
      })
    });
    assert(adminReq1.status === 403, `Registration as Administrator rejected with 403 (got ${adminReq1.status})`);

    const adminReq2 = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Malicious Admin Lowercase',
        email: `hacker2_${Date.now()}@test.cm`,
        password: 'Password123!',
        role: 'admin'
      })
    });
    assert(adminReq2.status === 403, `Registration as 'admin' rejected with 403 (got ${adminReq2.status})`);

    // 5. Validation - Duplicate Email & CNI, Password Mismatch
    console.log('\n[Test 5: Validation Rules]');
    const dupEmailReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Duplicate Email User',
        email: farmerEmail,
        password: 'Password123!',
        role: 'Farmer',
        phone: '+237 670 000 000',
        cniNumber: `CNI-NEW-${Date.now()}`
      })
    });
    assert(dupEmailReq.status === 400, `Duplicate email rejected with 400 (got ${dupEmailReq.status})`);

    const dupCniReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Duplicate CNI User',
        email: `unique_${Date.now()}@test.cm`,
        password: 'Password123!',
        role: 'Farmer',
        phone: '+237 670 000 000',
        cniNumber: farmerCni
      })
    });
    assert(dupCniReq.status === 400, `Duplicate CNI rejected with 400 (got ${dupCniReq.status})`);

    const passMismatchReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Mismatch User',
        email: `mismatch_${Date.now()}@test.cm`,
        password: 'Password123!',
        confirmPassword: 'DifferentPassword!',
        role: 'Customer',
        phone: '+237 670 000 000'
      })
    });
    assert(passMismatchReq.status === 400, `Password mismatch rejected with 400 (got ${passMismatchReq.status})`);

    // 6. Delivery Access Control & Traceability
    console.log('\n[Test 6: Delivery Authorization & Traceability]');
    // Create another driver
    const driver2Req = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Other Courier',
        email: `driver2_${Date.now()}@testnovara.cm`,
        password: 'Password123!',
        confirmPassword: 'Password123!',
        role: 'Delivery Person',
        phone: '+237 699 111 222',
        cniNumber: `CNI-DRV2-${Date.now()}`,
        vehicleType: 'Car'
      })
    });
    const driver2Res = await driver2Req.json();
    const driver2Token = driver2Res.token;

    // Create a Customer, Product, Order, and Delivery
    const customerReq = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Alice Client',
        email: `alice_${Date.now()}@testnovara.cm`,
        password: 'Password123!',
        confirmPassword: 'Password123!',
        role: 'Customer',
        phone: '+237 655 444 333'
      })
    });
    const customerRes = await customerReq.json();
    const customerId = customerRes.user.id;

    // Create product
    const product = await Product.create({
      name: 'Fresh Free-Range Eggs',
      farmId: farmRes1.farm.id,
      category: 'Eggs',
      price: 2500,
      stockQuantity: 100,
      unit: 'tray'
    });

    // Create order
    const order = await Order.create({
      customerId,
      totalAmount: 5000,
      status: 'confirmed',
      shippingAddress: 'Bastos, Yaounde',
      paymentStatus: 'paid'
    });

    await OrderItem.create({
      orderId: order.id,
      productId: product.id,
      quantity: 2,
      unitPrice: 2500,
      subtotal: 5000
    });

    // Assign delivery to driver 1
    const delivery = await Delivery.create({
      orderId: order.id,
      deliveryPersonId: driverId,
      status: 'assigned',
      dropoffAddress: 'Bastos, Yaounde',
      assignedAt: new Date()
    });

    // Test Driver 2 attempting to update Driver 1's delivery -> 403 Forbidden
    const unauthReq = await fetch(`${baseUrl}/api/deliveries/${delivery.id}/status`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${driver2Token}`
      },
      body: JSON.stringify({ status: 'picked_up' })
    });
    assert(unauthReq.status === 403, `Unauthorized driver update blocked with 403 (got ${unauthReq.status})`);

    // Test Driver 1 updating their own delivery -> 200 OK
    const authReq = await fetch(`${baseUrl}/api/deliveries/${delivery.id}/status`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${driverToken}`
      },
      body: JSON.stringify({ status: 'picked_up' })
    });
    assert(authReq.status === 200, `Authorized driver update succeeded with 200 (got ${authReq.status})`);

    // Test Traceability retrieval
    const traceReq = await fetch(`${baseUrl}/api/deliveries/${delivery.id}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${driverToken}`
      }
    });
    const traceRes = await traceReq.json();

    assert(traceReq.status === 200, `Delivery fetched with 200`);
    assert(traceRes.delivery.order !== undefined, 'Order details present');
    assert(traceRes.delivery.order.customer.name === 'Alice Client', 'Customer trace present');
    assert(traceRes.delivery.order.items.length > 0, 'Order items trace present');
    assert(traceRes.delivery.order.items[0].product.farm.name === 'Poultry Farm Horizon Alpha', 'Farm trace present');
    assert(traceRes.delivery.order.items[0].product.farm.farmer.farmerId === farmerRes.user.farmerId, 'Farmer trace present');
    assert(traceRes.delivery.deliveryPerson.deliveryPersonId === driverRes.user.deliveryPersonId, 'Delivery person and vehicle trace present');

    console.log(`\n========================================`);
    console.log(`Results: ${passed} Passed, ${failed} Failed`);
    console.log(`========================================\n`);

    server.close();
    if (failed > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  } catch (err) {
    console.error('Test execution error:', err);
    server.close();
    process.exit(1);
  }
}

runTests();
