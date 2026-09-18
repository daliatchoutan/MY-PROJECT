const assert = require('assert');
const sinon = require('sinon');
const jwt = require('jsonwebtoken');
const { User, Farm, Notification } = require('../../src/models');
const authController = require('../../src/controllers/authController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Authentication Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('User Registration', () => {
    it('should register a new Customer with valid data and active status', async () => {
      sinon.stub(User, 'findOne').resolves(null);
      const fakeCreatedUser = {
        id: 'usr-cust-001',
        name: 'Jane Customer',
        email: 'jane@example.com',
        role: 'Customer',
        status: 'active',
        phone: '+237600000001',
        address: 'Douala',
        avatarUrl: null
      };
      sinon.stub(User, 'create').resolves(fakeCreatedUser);

      const req = createMockReq({
        body: {
          name: 'Jane Customer',
          email: 'jane@example.com',
          password: 'Password123!',
          role: 'Customer',
          phone: '+237600000001',
          address: 'Douala'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.register(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201 Created');
      assert.strictEqual(res.data.user.role, 'Customer', 'Assigned role must be Customer');
      assert.strictEqual(res.data.user.status, 'active', 'Customer status must be active immediately');
      assert(typeof res.data.token === 'string', 'JWT token should be returned');
      assert(!next.called, 'Next middleware should not be called on success');
    });

    it('should reject registration when required fields are missing', async () => {
      const req = createMockReq({
        body: { email: 'incomplete@example.com' } // Missing name & password
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.register(req, res, next);

      assert.strictEqual(res.statusCode, 400, 'Status code should be 400 Bad Request');
      assert.strictEqual(res.data.message, 'Name, email, and password are required.');
    });

    it('should reject registration when email already exists', async () => {
      sinon.stub(User, 'findOne').resolves({ id: 'existing-id', email: 'duplicate@example.com' });

      const req = createMockReq({
        body: {
          name: 'Existing User',
          email: 'duplicate@example.com',
          password: 'Password123!'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.register(req, res, next);

      assert.strictEqual(res.statusCode, 400, 'Status code should be 400 Bad Request');
      assert.strictEqual(res.data.message, 'Email is already registered.');
    });

    it('should register a Farmer with pending status and auto-create initial pending farm', async () => {
      sinon.stub(User, 'findOne').resolves(null);
      const fakeFarmer = {
        id: 'usr-farmer-001',
        name: 'Farmer John',
        email: 'farmer.john@example.com',
        role: 'Farmer',
        status: 'pending',
        phone: '+237600000002',
        address: 'Bafoussam'
      };
      sinon.stub(User, 'create').resolves(fakeFarmer);
      sinon.stub(User, 'findAll').resolves([{ id: 'admin-1' }]); // For admin notification
      sinon.stub(Notification, 'create').resolves({});

      const fakeFarm = {
        id: 'farm-001',
        name: 'Sunrise Poultry',
        location: 'West Region',
        capacity: 1500,
        status: 'pending',
        farmerId: 'usr-farmer-001'
      };
      sinon.stub(Farm, 'create').resolves(fakeFarm);

      const req = createMockReq({
        body: {
          name: 'Farmer John',
          email: 'farmer.john@example.com',
          password: 'Password123!',
          role: 'Farmer',
          farmName: 'Sunrise Poultry',
          farmLocation: 'West Region',
          farmCapacity: 1500
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.register(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201 Created');
      assert.strictEqual(res.data.user.role, 'Farmer', 'Role must be Farmer');
      assert.strictEqual(res.data.user.status, 'pending', 'Farmer account must be set to pending approval');
      assert.strictEqual(res.data.user.farm.name, 'Sunrise Poultry', 'Auto-created farm name matched');
      assert.strictEqual(res.data.user.farm.status, 'pending', 'Farm status must be pending');
    });

    it('should register a Delivery Person with pending status', async () => {
      sinon.stub(User, 'findOne').resolves(null);
      const fakeCourier = {
        id: 'usr-courier-001',
        name: 'Speedy Express',
        email: 'speedy@example.com',
        role: 'Delivery Person',
        status: 'pending'
      };
      sinon.stub(User, 'create').resolves(fakeCourier);
      sinon.stub(User, 'findAll').resolves([]);

      const req = createMockReq({
        body: {
          name: 'Speedy Express',
          email: 'speedy@example.com',
          password: 'Password123!',
          role: 'Delivery Person'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.register(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201 Created');
      assert.strictEqual(res.data.user.role, 'Delivery Person', 'Role must be Delivery Person');
      assert.strictEqual(res.data.user.status, 'pending', 'Delivery Person status must be pending');
    });

    it('should reject attempts to register as ADMIN or Administrator with HTTP 403', async () => {
      const rolesToReject = ['Administrator', 'ADMIN', 'admin', 'SuperAdmin'];

      for (const role of rolesToReject) {
        const req = createMockReq({
          body: {
            name: 'Malicious Attacker',
            email: 'hacker@example.com',
            password: 'Password123!',
            role
          }
        });
        const res = createMockRes();
        const next = createMockNext();

        await authController.register(req, res, next);

        assert.strictEqual(res.statusCode, 403, `Role '${role}' must be rejected with HTTP 403`);
        assert.strictEqual(res.data.message, 'Creating an Administrator account via public registration is prohibited.');
      }
    });
  });

  describe('User Login', () => {
    it('should authenticate user with valid email and password', async () => {
      const fakeUser = {
        id: 'usr-100',
        name: 'Paul Farmer',
        email: 'paul@example.com',
        role: 'Farmer',
        status: 'active',
        validPassword: sinon.stub().resolves(true),
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeUser);

      const req = createMockReq({
        body: { email: 'paul@example.com', password: 'validPassword123' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 200, 'Login status should be 200 OK');
      assert(typeof res.data.token === 'string', 'Token should be returned');
      assert.strictEqual(res.data.user.email, 'paul@example.com', 'User email should match');
      assert(fakeUser.save.calledOnce, 'lastLoginAt should be updated');
    });

    it('should reject login when email or password is missing', async () => {
      const req = createMockReq({ body: { email: 'test@example.com' } });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 400, 'Status code should be 400 Bad Request');
      assert.strictEqual(res.data.message, 'Email and password are required.');
    });

    it('should reject login when user email is not found', async () => {
      sinon.stub(User, 'findOne').resolves(null);

      const req = createMockReq({
        body: { email: 'unknown@example.com', password: 'somePassword' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Status code should be 401 Unauthorized');
      assert.strictEqual(res.data.message, 'Invalid credentials.');
    });

    it('should reject login with incorrect password', async () => {
      const fakeUser = {
        id: 'usr-101',
        email: 'user@example.com',
        status: 'active',
        validPassword: sinon.stub().resolves(false)
      };
      sinon.stub(User, 'findOne').resolves(fakeUser);

      const req = createMockReq({
        body: { email: 'user@example.com', password: 'wrongPassword' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Status code should be 401 Unauthorized');
      assert.strictEqual(res.data.message, 'Invalid credentials.');
    });

    it('should reject login when account is suspended', async () => {
      const fakeUser = {
        id: 'usr-suspended',
        email: 'suspended@example.com',
        status: 'suspended'
      };
      sinon.stub(User, 'findOne').resolves(fakeUser);

      const req = createMockReq({
        body: { email: 'suspended@example.com', password: 'password123' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Suspended account should return 403 Forbidden');
      assert(res.data.message.includes('suspended'), 'Message should indicate account suspension');
    });

    it('should reject login when account is blocked', async () => {
      const fakeUser = {
        id: 'usr-blocked',
        email: 'blocked@example.com',
        status: 'blocked'
      };
      sinon.stub(User, 'findOne').resolves(fakeUser);

      const req = createMockReq({
        body: { email: 'blocked@example.com', password: 'password123' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Blocked account should return 403 Forbidden');
      assert(res.data.message.includes('blocked'), 'Message should indicate account blocked');
    });

    it('should allow pending or rejected users to log in with their review status and reason', async () => {
      const fakeUser = {
        id: 'usr-rejected',
        name: 'Rejected Farmer',
        email: 'rejected@example.com',
        role: 'Farmer',
        status: 'rejected',
        rejectionReason: 'Invalid land certificate',
        validPassword: sinon.stub().resolves(true),
        save: sinon.stub().resolves()
      };
      sinon.stub(User, 'findOne').resolves(fakeUser);

      const req = createMockReq({
        body: { email: 'rejected@example.com', password: 'password123' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await authController.login(req, res, next);

      assert.strictEqual(res.statusCode, 200, 'Login status should be 200 so status screen can render');
      assert.strictEqual(res.data.user.status, 'rejected', 'Status should be returned as rejected');
      assert.strictEqual(res.data.user.rejectionReason, 'Invalid land certificate', 'Rejection reason returned');
    });
  });

  describe('User Profile', () => {
    it('should retrieve user profile excluding password', async () => {
      const fakeProfile = {
        id: 'usr-1',
        name: 'Dalia Admin',
        email: 'dalia@example.com',
        role: 'Administrator',
        status: 'active',
        farms: []
      };
      sinon.stub(User, 'findByPk').resolves(fakeProfile);

      const req = createMockReq({ user: { id: 'usr-1' } });
      const res = createMockRes();
      const next = createMockNext();

      await authController.getProfile(req, res, next);

      assert.strictEqual(res.statusCode, 200, 'Profile retrieved with 200 OK');
      assert.strictEqual(res.data.user.id, 'usr-1');
      assert.strictEqual(res.data.user.email, 'dalia@example.com');
    });

    it('should return 404 when profile user does not exist', async () => {
      sinon.stub(User, 'findByPk').resolves(null);

      const req = createMockReq({ user: { id: 'non-existent' } });
      const res = createMockRes();
      const next = createMockNext();

      await authController.getProfile(req, res, next);

      assert.strictEqual(res.statusCode, 404, 'Status code should be 404 Not Found');
      assert.strictEqual(res.data.message, 'User not found.');
    });
  });
});
