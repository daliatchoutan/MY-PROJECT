const assert = require('assert');
const sinon = require('sinon');
const { Order, User, Notification } = require('../../src/models');
const orderController = require('../../src/controllers/orderController');
const digiPayService = require('../../src/services/digiPayService');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('DigiPay Payment Integration Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('digiPayService', () => {
    it('should report not configured when DIGIPAY_API_KEY is unset or empty', () => {
      const origKey = process.env.DIGIPAY_API_KEY;
      delete process.env.DIGIPAY_API_KEY;
      assert.strictEqual(digiPayService.isConfigured(), false);
      process.env.DIGIPAY_API_KEY = origKey;
    });

    it('should parse webhook payload correctly for successful approval', () => {
      const payload = {
        merchantOrderId: 'ord-12345678',
        transactionId: 'txn-digipay-999',
        amount: 5000,
        currencyCode: 'XAF',
        status: 'SUCCESS',
        paymentStatus: 'APPROVED'
      };

      const result = digiPayService.parseWebhookPayload(payload);
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.orderId, 'ord-12345678');
      assert.strictEqual(result.isPaid, true);
      assert.strictEqual(result.status, 'paid');
    });

    it('should parse webhook payload correctly for failed payment', () => {
      const payload = {
        merchantOrderId: 'ord-12345678',
        transactionId: 'txn-digipay-999',
        amount: 5000,
        status: 'FAILED',
        paymentStatus: 'DECLINED'
      };

      const result = digiPayService.parseWebhookPayload(payload);
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.isPaid, false);
      assert.strictEqual(result.status, 'failed');
    });
  });

  describe('orderController.initiatePayment', () => {
    it('should return 404 if order is not found', async () => {
      sinon.stub(Order, 'findByPk').resolves(null);

      const req = createMockReq({
        params: { id: 'nonexistent-order' },
        user: { id: 'cust-1', role: 'Customer' },
        body: { paymentMethod: 'MTN Mobile Money' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.initiatePayment(req, res, next);
      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'Order not found.');
    });

    it('should return 403 if Customer does not own the order', async () => {
      const fakeOrder = {
        id: 'ord-1',
        customerId: 'different-customer',
        totalAmount: 12000
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);

      const req = createMockReq({
        params: { id: 'ord-1' },
        user: { id: 'cust-1', role: 'Customer' },
        body: { paymentMethod: 'Orange Money' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.initiatePayment(req, res, next);
      assert.strictEqual(res.statusCode, 403);
      assert.strictEqual(res.data.message, 'Forbidden. You do not own this order.');
    });

    it('should initiate session with DigiPay when service is configured', async () => {
      const fakeOrder = {
        id: 'ord-1',
        customerId: 'cust-1',
        totalAmount: 15000,
        currency: 'FCFA',
        paymentMethod: null,
        paymentProvider: null,
        paymentReference: null,
        paymentUrl: null,
        paymentStatus: 'pending',
        save: sinon.stub().resolves()
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);
      sinon.stub(User, 'findByPk').resolves({ id: 'cust-1', name: 'John Doe', email: 'john@example.com', phone: '670000000' });
      sinon.stub(digiPayService, 'isConfigured').returns(true);
      sinon.stub(digiPayService, 'createPaymentSession').resolves({
        success: true,
        paymentReference: 'DGP-SESSION-888',
        paymentUrl: 'https://checkout.digipay.com/pay/888'
      });

      const req = createMockReq({
        params: { id: 'ord-1' },
        user: { id: 'cust-1', role: 'Customer' },
        body: { paymentMethod: 'MTN Mobile Money' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.initiatePayment(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.provider, 'DigiPay');
      assert.strictEqual(res.data.paymentReference, 'DGP-SESSION-888');
      assert.strictEqual(res.data.paymentUrl, 'https://checkout.digipay.com/pay/888');
      assert.strictEqual(fakeOrder.paymentStatus, 'pending');
      assert(fakeOrder.save.calledOnce);
    });
  });

  describe('orderController.verifyPayment', () => {
    it('should mark order paid when DigiPay confirms APPROVED / SUCCESS', async () => {
      const fakeOrder = {
        id: 'ord-verify-1',
        customerId: 'cust-1',
        totalAmount: 7500,
        paymentStatus: 'pending',
        paymentReference: 'DGP-SESSION-888',
        save: sinon.stub().resolves()
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);
      sinon.stub(digiPayService, 'isConfigured').returns(true);
      sinon.stub(digiPayService, 'verifyPaymentStatus').resolves({
        isPaid: true,
        status: 'paid',
        transactionStatus: 'SUCCESS',
        paymentStatus: 'APPROVED'
      });
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'ord-verify-1' },
        user: { id: 'cust-1', role: 'Customer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.verifyPayment(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.isPaid, true);
      assert.strictEqual(res.data.paymentStatus, 'paid');
      assert.strictEqual(fakeOrder.paymentStatus, 'paid');
      assert(fakeOrder.save.calledOnce);
      assert(Notification.create.calledOnce);
    });

    it('should keep order pending when DigiPay confirms payment is not yet completed', async () => {
      const fakeOrder = {
        id: 'ord-verify-2',
        customerId: 'cust-1',
        totalAmount: 7500,
        paymentStatus: 'pending',
        paymentReference: 'DGP-SESSION-888',
        save: sinon.stub().resolves()
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);
      sinon.stub(digiPayService, 'isConfigured').returns(true);
      sinon.stub(digiPayService, 'verifyPaymentStatus').resolves({
        isPaid: false,
        status: 'pending',
        transactionStatus: 'PENDING'
      });

      const req = createMockReq({
        params: { id: 'ord-verify-2' },
        user: { id: 'cust-1', role: 'Customer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.verifyPayment(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.isPaid, false);
      assert.strictEqual(fakeOrder.paymentStatus, 'pending');
      assert(!fakeOrder.save.called);
    });
  });

  describe('orderController.handleDigiPayWebhook', () => {
    it('should process webhook and update order to paid', async () => {
      const fakeOrder = {
        id: 'ord-hook-1',
        customerId: 'cust-1',
        totalAmount: 10000,
        paymentStatus: 'pending',
        paymentReference: null,
        save: sinon.stub().resolves()
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        body: {
          merchantOrderId: 'ord-hook-1',
          transactionId: 'txn-digipay-hook-77',
          status: 'SUCCESS',
          paymentStatus: 'APPROVED',
          amount: 10000
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.handleDigiPayWebhook(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.received, true);
      assert.strictEqual(res.data.status, 'paid');
      assert.strictEqual(fakeOrder.paymentStatus, 'paid');
      assert.strictEqual(fakeOrder.paymentReference, 'txn-digipay-hook-77');
      assert(fakeOrder.save.calledOnce);
      assert(Notification.create.calledOnce);
    });

    it('should return 400 for invalid webhook payload without order reference', async () => {
      const req = createMockReq({
        body: {}
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.handleDigiPayWebhook(req, res, next);
      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Invalid DigiPay webhook payload');
    });
  });
});
