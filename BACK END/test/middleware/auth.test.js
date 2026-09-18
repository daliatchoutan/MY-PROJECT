const assert = require('assert');
const sinon = require('sinon');
const jwt = require('jsonwebtoken');
const { User } = require('../../src/models');
const { verifyToken, authorizeRoles } = require('../../src/middleware/authMiddleware');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Middleware Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('verifyToken Middleware', () => {
    it('should reject request when no authorization header is provided', async () => {
      const req = createMockReq({ headers: {} });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Should return 401 Unauthorized');
      assert.strictEqual(res.data.message, 'Access denied. No token provided.');
      assert(!next.called, 'Next middleware must not be called');
    });

    it('should reject request when authorization header does not start with Bearer', async () => {
      const req = createMockReq({ headers: { authorization: 'Basic dXNlcjpwYXNz' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Should return 401 Unauthorized');
      assert.strictEqual(res.data.message, 'Access denied. No token provided.');
    });

    it('should reject request when token is invalid or corrupted', async () => {
      const req = createMockReq({ headers: { authorization: 'Bearer invalid.token.value' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Should return 401 Unauthorized');
      assert.strictEqual(res.data.message, 'Invalid or expired token.');
    });

    it('should reject request when token user no longer exists in database', async () => {
      sinon.stub(jwt, 'verify').returns({ id: 'deleted-user', role: 'Customer' });
      sinon.stub(User, 'findByPk').resolves(null);

      const req = createMockReq({ headers: { authorization: 'Bearer valid.jwt.signature' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 401, 'Should return 401 Unauthorized');
      assert.strictEqual(res.data.message, 'User account no longer exists.');
    });

    it('should reject request when user account is suspended', async () => {
      sinon.stub(jwt, 'verify').returns({ id: 'u1', role: 'Customer' });
      sinon.stub(User, 'findByPk').resolves({ id: 'u1', status: 'suspended' });

      const req = createMockReq({ headers: { authorization: 'Bearer valid.jwt.signature' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Should return 403 Forbidden');
      assert(res.data.message.includes('Suspended'));
    });

    it('should reject request when user account is blocked', async () => {
      sinon.stub(jwt, 'verify').returns({ id: 'u2', role: 'Customer' });
      sinon.stub(User, 'findByPk').resolves({ id: 'u2', status: 'blocked' });

      const req = createMockReq({ headers: { authorization: 'Bearer valid.jwt.signature' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Should return 403 Forbidden');
      assert(res.data.message.includes('Blocked'));
    });

    it('should attach user payload and user model to request when token is valid', async () => {
      const decodedPayload = { id: 'u-valid', role: 'Farmer', email: 'farmer@novara.cm' };
      const fakeUserModel = { id: 'u-valid', role: 'Farmer', status: 'active' };

      sinon.stub(jwt, 'verify').returns(decodedPayload);
      sinon.stub(User, 'findByPk').resolves(fakeUserModel);

      const req = createMockReq({ headers: { authorization: 'Bearer valid.jwt.signature' } });
      const res = createMockRes();
      const next = createMockNext();

      await verifyToken(req, res, next);

      assert.strictEqual(req.user, decodedPayload, 'req.user must be populated with decoded token');
      assert.strictEqual(req.userModel, fakeUserModel, 'req.userModel must be populated with database user');
      assert(next.calledOnce, 'next() must be called');
    });
  });

  describe('authorizeRoles Middleware', () => {
    it('should allow Administrator to access Admin-protected routes', () => {
      const middleware = authorizeRoles('Administrator');
      const req = createMockReq({
        user: { role: 'Administrator' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert(next.calledOnce, 'next() should be called for Administrator');
      assert.strictEqual(res.statusCode, 200, 'Status should remain 200');
    });

    it('should allow Farmer to access Farmer-protected routes', () => {
      const middleware = authorizeRoles('Farmer', 'Administrator');
      const req = createMockReq({
        user: { role: 'Farmer' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert(next.calledOnce, 'Farmer with active status should proceed');
    });

    it('should allow Delivery Person to access Delivery-protected routes', () => {
      const middleware = authorizeRoles('Delivery Person', 'Administrator');
      const req = createMockReq({
        user: { role: 'Delivery Person' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert(next.calledOnce, 'Active Delivery Person should proceed');
    });

    it('should allow Customer to access Customer-protected routes', () => {
      const middleware = authorizeRoles('Customer');
      const req = createMockReq({
        user: { role: 'Customer' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert(next.calledOnce, 'Customer should proceed');
    });

    it('should reject Customer attempting to access Admin endpoints (403)', () => {
      const middleware = authorizeRoles('Administrator');
      const req = createMockReq({
        user: { role: 'Customer' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Customer should receive 403 Forbidden');
      assert(res.data.message.includes('not authorized'));
      assert(!next.called, 'next() must not be called');
    });

    it('should reject Farmer attempting to access Admin endpoints (403)', () => {
      const middleware = authorizeRoles('Administrator');
      const req = createMockReq({
        user: { role: 'Farmer' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Farmer should receive 403 Forbidden on Admin routes');
      assert(!next.called);
    });

    it('should reject Delivery Person attempting to access Admin endpoints (403)', () => {
      const middleware = authorizeRoles('Administrator');
      const req = createMockReq({
        user: { role: 'Delivery Person' },
        userModel: { status: 'active' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Delivery Person should receive 403 Forbidden on Admin routes');
      assert(!next.called);
    });

    it('should reject pending Farmer from accessing protected farmer routes (403)', () => {
      const middleware = authorizeRoles('Farmer');
      const req = createMockReq({
        user: { role: 'Farmer' },
        userModel: { status: 'pending' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Pending Farmer must be rejected with 403');
      assert.strictEqual(res.data.accountStatus, 'pending', 'Response must indicate accountStatus pending');
      assert.strictEqual(res.data.message, 'Your account is pending administrator approval.');
      assert(!next.called);
    });

    it('should reject rejected user with rejection reason (403)', () => {
      const middleware = authorizeRoles('Farmer');
      const req = createMockReq({
        user: { role: 'Farmer' },
        userModel: { status: 'rejected', rejectionReason: 'Documentation invalid' }
      });
      const res = createMockRes();
      const next = createMockNext();

      middleware(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Rejected user must receive 403 Forbidden');
      assert.strictEqual(res.data.accountStatus, 'rejected');
      assert.strictEqual(res.data.rejectionReason, 'Documentation invalid');
      assert(!next.called);
    });
  });
});
