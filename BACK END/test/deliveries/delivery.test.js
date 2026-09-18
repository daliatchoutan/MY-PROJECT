const assert = require('assert');
const sinon = require('sinon');
const { Delivery, Order, User, Notification } = require('../../src/models');
const deliveryController = require('../../src/controllers/deliveryController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Delivery Management Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('getAvailableDrivers', () => {
    it('should retrieve list of couriers with Delivery Person role', async () => {
      const fakeDrivers = [
        { id: 'drv-1', name: 'Alain Courier', role: 'Delivery Person', status: 'active' },
        { id: 'drv-2', name: 'Michel Express', role: 'Delivery Person', status: 'active' }
      ];
      sinon.stub(User, 'findAll').resolves(fakeDrivers);

      const req = createMockReq();
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.getAvailableDrivers(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.drivers.length, 2);
      assert.strictEqual(res.data.drivers[0].name, 'Alain Courier');
    });
  });

  describe('assignDelivery', () => {
    it('should assign delivery to a valid delivery person and notify courier and customer', async () => {
      const fakeDelivery = {
        id: 'del-1',
        orderId: 'ord-12345678',
        dropoffAddress: 'Akwa, Douala',
        save: sinon.stub().resolves()
      };
      sinon.stub(Delivery, 'findByPk').onFirstCall().resolves(fakeDelivery).onSecondCall().resolves({
        ...fakeDelivery,
        status: 'assigned',
        deliveryPersonId: 'drv-target'
      });

      const fakeDriver = { id: 'drv-target', name: 'Jean Livreur', role: 'Delivery Person' };
      sinon.stub(User, 'findOne').resolves(fakeDriver);

      const fakeOrder = {
        id: 'ord-12345678',
        customerId: 'cust-9',
        customer: { name: 'Customer Alice', phone: '+237612345678' }
      };
      sinon.stub(Order, 'findByPk').resolves(fakeOrder);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'del-1' },
        body: { deliveryPersonId: 'drv-target' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.assignDelivery(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeDelivery.deliveryPersonId, 'drv-target');
      assert.strictEqual(fakeDelivery.status, 'assigned');
      assert(fakeDelivery.save.calledOnce);
    });

    it('should reject assignment when delivery person is not found or has invalid role (400)', async () => {
      const fakeDelivery = { id: 'del-1', orderId: 'ord-1' };
      sinon.stub(Delivery, 'findByPk').resolves(fakeDelivery);
      sinon.stub(User, 'findOne').resolves(null); // Not a delivery person

      const req = createMockReq({
        params: { id: 'del-1' },
        body: { deliveryPersonId: 'non-driver' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.assignDelivery(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Specified delivery person not found or role is invalid.');
    });

    it('should return 404 when delivery record does not exist', async () => {
      sinon.stub(Delivery, 'findByPk').resolves(null);
      sinon.stub(Delivery, 'findOne').resolves(null);
      sinon.stub(Order, 'findByPk').resolves(null);

      const req = createMockReq({
        params: { id: 'unknown-del' },
        body: { deliveryPersonId: 'drv-1' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.assignDelivery(req, res, next);

      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'Delivery record not found.');
    });
  });

  describe('updateDeliveryStatus', () => {
    it('should reject invalid delivery status values (400)', async () => {
      const req = createMockReq({
        params: { id: 'del-1' },
        body: { status: 'flying_in_sky' } // Invalid status
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.updateDeliveryStatus(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert(res.data.message.includes('Invalid delivery status'));
    });

    it('should allow assigned courier to update status to delivered and complete the order', async () => {
      const fakeOrder = { id: 'ord-1', status: 'in_transit', customerId: 'cust-1', save: sinon.stub().resolves() };
      const fakeDelivery = {
        id: 'del-1',
        orderId: 'ord-1',
        deliveryPersonId: 'courier-me',
        order: fakeOrder,
        save: sinon.stub().resolves()
      };
      sinon.stub(Delivery, 'findByPk').resolves(fakeDelivery);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'del-1' },
        user: { id: 'courier-me', role: 'Delivery Person' },
        body: { status: 'delivered' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.updateDeliveryStatus(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeDelivery.status, 'delivered');
      assert.strictEqual(fakeOrder.status, 'delivered', 'Order status must be set to delivered');
      assert(fakeDelivery.save.calledOnce);
      assert(fakeOrder.save.calledOnce);
    });

    it('should reject update with 403 when courier is not assigned to the delivery', async () => {
      const fakeDelivery = {
        id: 'del-1',
        deliveryPersonId: 'someone-else-courier',
        order: {}
      };
      sinon.stub(Delivery, 'findByPk').resolves(fakeDelivery);

      const req = createMockReq({
        params: { id: 'del-1' },
        user: { id: 'courier-me', role: 'Delivery Person' },
        body: { status: 'delivered' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.updateDeliveryStatus(req, res, next);

      assert.strictEqual(res.statusCode, 403);
      assert.strictEqual(res.data.message, 'Forbidden. This delivery is not assigned to you.');
    });
  });

  describe('reportDelayedDelivery', () => {
    it('should record delay reason and update delivery status to delayed', async () => {
      const fakeDelivery = {
        id: 'del-1',
        deliveryPersonId: 'courier-me',
        order: { customerId: 'cust-1' },
        save: sinon.stub().resolves()
      };
      sinon.stub(Delivery, 'findByPk').resolves(fakeDelivery);
      sinon.stub(Notification, 'create').resolves({});

      const req = createMockReq({
        params: { id: 'del-1' },
        user: { id: 'courier-me', role: 'Delivery Person' },
        body: { delayReason: 'Heavy tropical rain on highway' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.reportDelayedDelivery(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeDelivery.status, 'delayed');
      assert.strictEqual(fakeDelivery.isDelayed, true);
      assert.strictEqual(fakeDelivery.delayReason, 'Heavy tropical rain on highway');
      assert(fakeDelivery.save.calledOnce);
    });

    it('should reject delay report when delayReason is missing (400)', async () => {
      const req = createMockReq({
        params: { id: 'del-1' },
        body: {} // Missing delayReason
      });
      const res = createMockRes();
      const next = createMockNext();

      await deliveryController.reportDelayedDelivery(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Delay reason is required.');
    });
  });
});
