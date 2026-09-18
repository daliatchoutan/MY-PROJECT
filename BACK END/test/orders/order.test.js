const assert = require('assert');
const sinon = require('sinon');
const { Order, OrderItem, Product, Delivery, Notification, sequelize } = require('../../src/models');
const orderController = require('../../src/controllers/orderController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Order Management Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('createOrder', () => {
    it('should successfully create order for customer with valid items and shipping address', async () => {
      const fakeTransaction = {
        commit: sinon.stub().resolves(),
        rollback: sinon.stub().resolves()
      };
      sinon.stub(sequelize, 'transaction').resolves(fakeTransaction);

      const fakeProduct = {
        id: 'prod-chick-12345678901234567890',
        name: 'Broiler Chicken',
        price: 4000,
        stockQuantity: 50,
        farm: { farmerId: 'farmer-xyz' },
        save: sinon.stub().resolves()
      };
      sinon.stub(Product, 'findByPk').resolves(fakeProduct);

      const fakeCreatedOrder = {
        id: 'ord-12345678-abcd',
        customerId: 'cust-1',
        totalAmount: 8000,
        status: 'pending'
      };
      sinon.stub(Order, 'create').resolves(fakeCreatedOrder);
      sinon.stub(OrderItem, 'create').resolves({});
      sinon.stub(Delivery, 'create').resolves({});
      sinon.stub(Notification, 'create').resolves({});

      sinon.stub(Order, 'findByPk').resolves({
        ...fakeCreatedOrder,
        items: [{ productId: fakeProduct.id, quantity: 2, unitPrice: 4000 }],
        delivery: { status: 'unassigned' }
      });

      const req = createMockReq({
        user: { id: 'cust-1', role: 'Customer' },
        body: {
          items: [{ productId: 'prod-chick-12345678901234567890', quantity: 2 }],
          shippingAddress: 'Bonapriso, Douala',
          notes: 'Deliver in morning'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.createOrder(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201');
      assert.strictEqual(res.data.message, 'Order placed successfully on NOVARA');
      assert(fakeProduct.save.calledOnce, 'Stock should be updated');
      assert.strictEqual(fakeProduct.stockQuantity, 48, 'Stock quantity deducted (50 - 2 = 48)');
      assert(fakeTransaction.commit.calledOnce, 'Transaction must be committed');
      assert(!fakeTransaction.rollback.called, 'Rollback should not be called');
    });

    it('should reject order when items array is empty or missing (400)', async () => {
      const fakeTransaction = { rollback: sinon.stub().resolves() };
      sinon.stub(sequelize, 'transaction').resolves(fakeTransaction);

      const req = createMockReq({
        user: { id: 'cust-1' },
        body: { items: [], shippingAddress: 'Douala' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.createOrder(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Order must contain at least one item.');
      assert(fakeTransaction.rollback.calledOnce);
    });

    it('should reject order when shipping address is missing (400)', async () => {
      const fakeTransaction = { rollback: sinon.stub().resolves() };
      sinon.stub(sequelize, 'transaction').resolves(fakeTransaction);

      const req = createMockReq({
        user: { id: 'cust-1' },
        body: { items: [{ productId: 'p1', quantity: 1 }] } // No shippingAddress
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.createOrder(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'Shipping address is required.');
      assert(fakeTransaction.rollback.calledOnce);
    });

    it('should return 404 when ordered product cannot be found', async () => {
      const fakeTransaction = { rollback: sinon.stub().resolves() };
      sinon.stub(sequelize, 'transaction').resolves(fakeTransaction);

      sinon.stub(Product, 'findByPk').resolves(null);
      sinon.stub(Product, 'findOne').resolves(null);

      const req = createMockReq({
        user: { id: 'cust-1' },
        body: {
          items: [{ productId: 'prod-12345678901234567890', quantity: 1 }],
          shippingAddress: 'Yaounde'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await orderController.createOrder(req, res, next);

      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'No available products found for this order.');
      assert(fakeTransaction.rollback.calledOnce);
    });
  });
});
