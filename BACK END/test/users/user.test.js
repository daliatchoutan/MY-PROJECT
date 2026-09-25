const assert = require('assert');
const sinon = require('sinon');
const { User, Farm, Device, Order, Product, Notification } = require('../../src/models');
const adminController = require('../../src/controllers/adminController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('User Governance & Admin Approval Workflow Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('getDashboardStats', () => {
    it('should calculate and return platform metrics correctly', async () => {
      sinon.stub(User, 'count').onFirstCall().resolves(50)  // totalUsers
                              .onSecondCall().resolves(10) // totalFarmers
                              .onThirdCall().resolves(35)  // totalCustomers
                              .onCall(3).resolves(5);      // totalDrivers
      sinon.stub(Farm, 'count').resolves(8);
      sinon.stub(Device, 'count').resolves(16);
      sinon.stub(Order, 'count').resolves(42);
      sinon.stub(Product, 'count').resolves(25);
      sinon.stub(Order, 'findAll').resolves([
        { totalAmount: 15000, status: 'delivered', paymentStatus: 'paid' },
        { totalAmount: 25000, status: 'pending', paymentStatus: 'paid' }
      ]);

      const req = createMockReq();
      const res = createMockRes();
      const next = createMockNext();

      await adminController.getDashboardStats(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.stats.totalUsers, 50);
      assert.strictEqual(res.data.stats.totalFarmers, 10);
      assert.strictEqual(res.data.stats.totalRevenue, 40000);
      assert.strictEqual(res.data.stats.currency, 'FCFA');
    });
  });

  describe('createUser (Admin Provisioning)', () => {
    it('should allow Administrator to create another Administrator account', async () => {
      sinon.stub(User, 'findOne').resolves(null);
      const fakeNewAdmin = {
        id: 'new-admin-id',
        name: 'Co-Admin User',
        email: 'coadmin@novara.cm',
        role: 'Administrator',
        status: 'active'
      };
      sinon.stub(User, 'create').resolves(fakeNewAdmin);

      const req = createMockReq({
        user: { role: 'Administrator' },
        body: {
          name: 'Co-Admin User',
          email: 'coadmin@novara.cm',
          password: 'SecureAdminPassword123!',
          role: 'Administrator'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.createUser(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201');
      assert.strictEqual(res.data.user.role, 'Administrator', 'Admin can provision another Administrator');
      assert.strictEqual(res.data.user.status, 'active');
    });

    it('should reject user creation when required fields are missing', async () => {
      const req = createMockReq({
        user: { role: 'Administrator' },
        body: { email: 'incomplete@novara.cm' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.createUser(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Name, email, and password are required.');
    });
  });

  describe('setUserStatus', () => {
    it('should update user status to suspended and notify user', async () => {
      const fakeUser = {
        id: 'u-target',
        name: 'Target User',
        status: 'active',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findByPk').resolves(fakeUser);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'u-target' },
        user: { id: 'admin-id', role: 'Administrator' },
        body: { status: 'suspended' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.setUserStatus(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeUser.status, 'suspended');
      assert(fakeUser.save.calledOnce);
    });

    it('should reject invalid status values (400)', async () => {
      const req = createMockReq({
        params: { id: 'u-target' },
        body: { status: 'super_active' } // Invalid
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.setUserStatus(req, res, next);

      assert.strictEqual(res.statusCode, 400);
    });
  });

  describe('Admin Approval Workflow', () => {
    it('should list all pending farmers, pending drivers, and pending farms', async () => {
      sinon.stub(User, 'findAll')
        .onFirstCall().resolves([{ id: 'farmer-p1', role: 'Farmer', status: 'pending', farms: [] }])
        .onSecondCall().resolves([{ id: 'driver-p1', role: 'Delivery Person', status: 'pending' }]);
      sinon.stub(Farm, 'findAll').resolves([{ id: 'farm-p1', status: 'pending' }]);

      const req = createMockReq({ user: { role: 'Administrator' } });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.getPendingApprovals(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.pendingFarmers.length, 1);
      assert.strictEqual(res.data.pendingDrivers.length, 1);
      assert.strictEqual(res.data.pendingFarms.length, 1);
      assert.strictEqual(res.data.totalPending, 3);
    });

    it('should approve farmer and automatically approve their associated pending farms', async () => {
      const fakeFarmer = {
        id: 'f-pending',
        name: 'Paul Farmer',
        role: 'Farmer',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeFarmer);
      sinon.stub(Farm, 'update').resolves([1]);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'f-pending' },
        user: { id: 'admin-id', role: 'Administrator' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.approveFarmer(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeFarmer.status, 'active');
      assert.strictEqual(res.data.farmer.status, 'active');
      assert(fakeFarmer.save.calledOnce);
      assert(Farm.update.calledOnce, 'Farm.update must be called to approve associated pending farms');
    });

    it('should reject farmer with reason and update associated farms', async () => {
      const fakeFarmer = {
        id: 'f-to-reject',
        name: 'Declined Farmer',
        role: 'Farmer',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeFarmer);
      sinon.stub(Farm, 'update').resolves([1]);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'f-to-reject' },
        user: { id: 'admin-id', role: 'Administrator' },
        body: { reason: 'Could not verify GPS coordinates of poultry facility' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.rejectFarmer(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeFarmer.status, 'rejected');
      assert.strictEqual(fakeFarmer.rejectionReason, 'Could not verify GPS coordinates of poultry facility');
      assert(fakeFarmer.save.calledOnce);
      assert(Farm.update.calledOnce);
    });

    it('should approve delivery person account', async () => {
      const fakeDriver = {
        id: 'drv-pending',
        name: 'Pending Courier',
        role: 'Delivery Person',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeDriver);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'drv-pending' },
        user: { id: 'admin-id', role: 'Administrator' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.approveDeliveryPerson(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeDriver.status, 'active');
      assert(fakeDriver.save.calledOnce);
    });

    it('should reject delivery person with reason', async () => {
      const fakeDriver = {
        id: 'drv-bad',
        name: 'Declined Courier',
        role: 'Delivery Person',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeDriver);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'drv-bad' },
        user: { id: 'admin-id', role: 'Administrator' },
        body: { reason: 'Driver license expired' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.rejectDeliveryPerson(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeDriver.status, 'rejected');
      assert.strictEqual(fakeDriver.rejectionReason, 'Driver license expired');
      assert(fakeDriver.save.calledOnce);
    });

    it('should approve farm manager account by Administrator', async () => {
      const fakeManager = {
        id: 'mgr-pending',
        name: 'Manager Robert',
        role: 'Farm Manager',
        status: 'pending',
        farmManagerId: 'NOV-MGR-00001',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeManager);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'mgr-pending' },
        user: { id: 'admin-id', role: 'Administrator' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.approveFarmManager(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeManager.status, 'active');
      assert.strictEqual(fakeManager.rejectionReason, null);
      assert(fakeManager.save.calledOnce);
    });

    it('should reject farm manager account with reason by Administrator', async () => {
      const fakeManager = {
        id: 'mgr-declined',
        name: 'Declined Manager',
        role: 'Farm Manager',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeManager);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'mgr-declined' },
        user: { id: 'admin-id', role: 'Administrator' },
        body: { reason: 'CNI verification failed' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.rejectFarmManager(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeManager.status, 'rejected');
      assert.strictEqual(fakeManager.rejectionReason, 'CNI verification failed');
      assert(fakeManager.save.calledOnce);
    });

    it('should allow Farm Manager to approve farmer account', async () => {
      const fakeFarmer = {
        id: 'farmer-app-1',
        name: 'Applicant Farmer',
        role: 'Farmer',
        status: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeFarmer);
      sinon.stub(Farm, 'update').resolves([1]);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'farmer-app-1' },
        user: { id: 'mgr-id', role: 'Farm Manager' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.approveFarmer(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeFarmer.status, 'active');
      assert.strictEqual(fakeFarmer.approvedBy, 'mgr-id');
      assert(fakeFarmer.save.calledOnce);
    });

    it('should allow Farm Manager to create a farmer account directly', async () => {
      sinon.stub(User, 'findOne').resolves(null);
      sinon.stub(User, 'create').resolves({
        id: 'new-farmer-id',
        name: 'Direct Farmer',
        email: 'direct@farmer.com',
        role: 'Farmer',
        status: 'active',
        phone: '677112233',
        cniNumber: '1122334455',
        farmerId: 'NOV-FRM-00099',
        address: 'Bafoussam'
      });
      sinon.stub(Farm, 'create').resolves({
        id: 'farm-123',
        farmId: 'NOV-FARM-00010',
        name: 'Highland Farm',
        location: 'Bafoussam'
      });

      const req = createMockReq({
        user: { id: 'mgr-id', role: 'Farm Manager' },
        body: {
          name: 'Direct Farmer',
          email: 'direct@farmer.com',
          password: 'SecretPassword123!',
          phone: '677112233',
          cniNumber: '1122334455',
          address: 'Bafoussam',
          farmName: 'Highland Farm',
          farmLocation: 'Bafoussam'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await adminController.createFarmer(req, res, next);

      assert.strictEqual(res.statusCode, 201);
      assert.strictEqual(res.data.farmer.role, 'Farmer');
      assert.strictEqual(res.data.farmer.status, 'active');
      assert.strictEqual(res.data.farmer.name, 'Direct Farmer');
      assert(User.create.calledOnce);
      assert(Farm.create.calledOnce);
    });
  });
});
