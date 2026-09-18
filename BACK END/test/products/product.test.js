const assert = require('assert');
const sinon = require('sinon');
const { Product, Farm } = require('../../src/models');
const productController = require('../../src/controllers/productController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Product Management Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('createProduct', () => {
    it('should create a poultry product with valid data for owning farmer', async () => {
      const fakeFarm = { id: 'farm-1', farmerId: 'farmer-1' };
      sinon.stub(Farm, 'findByPk').resolves(fakeFarm);

      const fakeProduct = {
        id: 'prod-10',
        farmId: 'farm-1',
        name: 'Broiler Chicken',
        price: 4500,
        stockQuantity: 100,
        unit: 'bird',
        category: 'Live Poultry',
        imageUrl: '/uploads/products/product_broiler.jpg'
      };
      sinon.stub(Product, 'create').resolves(fakeProduct);

      const req = createMockReq({
        user: { id: 'farmer-1', role: 'Farmer' },
        body: {
          farmId: 'farm-1',
          name: 'Broiler Chicken',
          price: 4500,
          stockQuantity: 100,
          unit: 'bird',
          category: 'Live Poultry'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.createProduct(req, res, next);

      assert.strictEqual(res.statusCode, 201);
      assert.strictEqual(res.data.product.name, 'Broiler Chicken');
      assert.strictEqual(res.data.product.price, 4500);
    });

    it('should reject creation when farmId, name, or price is missing (400)', async () => {
      const req = createMockReq({
        user: { id: 'farmer-1', role: 'Farmer' },
        body: { name: 'Only Name' } // Missing farmId and price
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.createProduct(req, res, next);

      assert.strictEqual(res.statusCode, 400);
      assert.strictEqual(res.data.message, 'farmId, name, and price are required.');
    });

    it('should return 404 when target farm does not exist', async () => {
      sinon.stub(Farm, 'findByPk').resolves(null);

      const req = createMockReq({
        user: { id: 'farmer-1', role: 'Farmer' },
        body: { farmId: 'unknown-farm', name: 'Eggs', price: 2000 }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.createProduct(req, res, next);

      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'Farm not found.');
    });

    it('should return 403 when farmer attempts to add product to a farm they do not own', async () => {
      const foreignFarm = { id: 'farm-other', farmerId: 'other-farmer' };
      sinon.stub(Farm, 'findByPk').resolves(foreignFarm);

      const req = createMockReq({
        user: { id: 'farmer-1', role: 'Farmer' },
        body: { farmId: 'farm-other', name: 'Eggs', price: 2000 }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.createProduct(req, res, next);

      assert.strictEqual(res.statusCode, 403);
      assert.strictEqual(res.data.message, 'Forbidden. You can only add products to your own farm.');
    });
  });

  describe('getProducts', () => {
    it('should retrieve available products list', async () => {
      const productList = [
        { id: 'p1', name: 'Brown Eggs', price: 3500, category: 'Eggs', isAvailable: true },
        { id: 'p2', name: 'Poultry Feed', price: 18000, category: 'Poultry Feed', isAvailable: true }
      ];
      sinon.stub(Product, 'findAll').resolves(productList);

      const req = createMockReq({ query: { category: 'All' } });
      const res = createMockRes();
      const next = createMockNext();

      await productController.getProducts(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.products.length, 2);
    });
  });

  describe('getProductById', () => {
    it('should return product details when product exists', async () => {
      const fakeProduct = { id: 'p-1', name: 'Organic Eggs', price: 3000 };
      sinon.stub(Product, 'findByPk').resolves(fakeProduct);

      const req = createMockReq({ params: { id: 'p-1' } });
      const res = createMockRes();
      const next = createMockNext();

      await productController.getProductById(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.product.id, 'p-1');
    });

    it('should return 404 when product does not exist', async () => {
      sinon.stub(Product, 'findByPk').resolves(null);

      const req = createMockReq({ params: { id: 'unknown-p' } });
      const res = createMockRes();
      const next = createMockNext();

      await productController.getProductById(req, res, next);

      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'Product not found.');
    });
  });

  describe('updateProduct', () => {
    it('should allow owning farmer to update product fields', async () => {
      const fakeProduct = {
        id: 'p-update',
        name: 'Old Feed',
        price: 15000,
        farm: { farmerId: 'farmer-me' },
        save: sinon.stub().resolves()
      };
      sinon.stub(Product, 'findByPk').resolves(fakeProduct);

      const req = createMockReq({
        params: { id: 'p-update' },
        user: { id: 'farmer-me', role: 'Farmer' },
        body: { name: 'Premium Layer Feed', price: 18500 }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.updateProduct(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(fakeProduct.name, 'Premium Layer Feed');
      assert.strictEqual(fakeProduct.price, 18500);
      assert(fakeProduct.save.calledOnce);
    });

    it('should reject update with 403 when farmer does not own the product\'s farm', async () => {
      const foreignProduct = {
        id: 'p-foreign',
        farm: { farmerId: 'other-farmer' }
      };
      sinon.stub(Product, 'findByPk').resolves(foreignProduct);

      const req = createMockReq({
        params: { id: 'p-foreign' },
        user: { id: 'farmer-me', role: 'Farmer' },
        body: { price: 1000 }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.updateProduct(req, res, next);

      assert.strictEqual(res.statusCode, 403);
      assert.strictEqual(res.data.message, 'Forbidden. You do not own this product.');
    });
  });

  describe('deleteProduct', () => {
    it('should allow owning farmer to delete product', async () => {
      const fakeProduct = {
        id: 'p-del',
        farm: { farmerId: 'farmer-me' },
        destroy: sinon.stub().resolves()
      };
      sinon.stub(Product, 'findByPk').resolves(fakeProduct);

      const req = createMockReq({
        params: { id: 'p-del' },
        user: { id: 'farmer-me', role: 'Farmer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await productController.deleteProduct(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.message, 'Product deleted successfully');
      assert(fakeProduct.destroy.calledOnce);
    });
  });

  describe('getProductTemplates', () => {
    it('should return standard poultry product templates', async () => {
      const req = createMockReq();
      const res = createMockRes();
      const next = createMockNext();

      await productController.getProductTemplates(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert(Array.isArray(res.data.templates));
      assert(res.data.templates.length >= 7, 'Should have broiler, layer, chicks, eggs, etc.');
    });
  });
});
