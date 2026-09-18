const assert = require('assert');
const sinon = require('sinon');
const { Farm } = require('../../src/models');
const farmController = require('../../src/controllers/farmController');
const { createMockReq, createMockRes, createMockNext } = require('../helpers/mockHelper');

describe('Farm Management Unit Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('createFarm', () => {
    it('should create a farm with valid data for authenticated Farmer', async () => {
      const fakeFarm = {
        id: 'farm-10',
        name: 'Green Field Poultry',
        location: 'Yaounde',
        capacity: 2000,
        currentPoultryCount: 500,
        farmerId: 'farmer-123'
      };
      sinon.stub(Farm, 'create').resolves(fakeFarm);

      const req = createMockReq({
        user: { id: 'farmer-123', role: 'Farmer' },
        body: {
          name: 'Green Field Poultry',
          location: 'Yaounde',
          capacity: 2000,
          currentPoultryCount: 500
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.createFarm(req, res, next);

      assert.strictEqual(res.statusCode, 201, 'Status code should be 201 Created');
      assert.strictEqual(res.data.farm.name, 'Green Field Poultry');
      assert.strictEqual(res.data.farm.farmerId, 'farmer-123');
    });

    it('should reject farm creation when name or location is missing (400)', async () => {
      const req = createMockReq({
        user: { id: 'farmer-123', role: 'Farmer' },
        body: { name: 'Only Name' } // Missing location
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.createFarm(req, res, next);

      assert.strictEqual(res.statusCode, 400, 'Should return 400 Bad Request');
      assert.strictEqual(res.data.message, 'Farm name and location are required.');
    });

    it('should allow Administrator to specify farmerId when creating a farm', async () => {
      const fakeFarm = {
        id: 'farm-admin-created',
        name: 'Assigned Farm',
        location: 'Bamenda',
        farmerId: 'target-farmer-id'
      };
      sinon.stub(Farm, 'create').resolves(fakeFarm);

      const req = createMockReq({
        user: { id: 'admin-id', role: 'Administrator' },
        body: {
          name: 'Assigned Farm',
          location: 'Bamenda',
          farmerId: 'target-farmer-id'
        }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.createFarm(req, res, next);

      assert.strictEqual(res.statusCode, 201);
      assert.strictEqual(res.data.farm.farmerId, 'target-farmer-id');
    });
  });

  describe('getFarms', () => {
    it('should return only the farmer\'s own farms when requested by Farmer', async () => {
      sinon.stub(Farm, 'findAll').callsFake(async (options) => {
        assert.strictEqual(options.where.farmerId, 'farmer-me', 'Where clause must filter by farmerId');
        return [{ id: 'farm-1', name: 'My Farm', farmerId: 'farmer-me' }];
      });

      const req = createMockReq({ user: { id: 'farmer-me', role: 'Farmer' } });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.getFarms(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.farms.length, 1);
    });

    it('should return all farms without farmerId filter when requested by Administrator', async () => {
      sinon.stub(Farm, 'findAll').callsFake(async (options) => {
        assert.strictEqual(options.where.farmerId, undefined, 'Administrator should have no farmerId constraint');
        return [
          { id: 'f1', name: 'Farm 1' },
          { id: 'f2', name: 'Farm 2' }
        ];
      });

      const req = createMockReq({ user: { id: 'admin-id', role: 'Administrator' } });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.getFarms(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.farms.length, 2);
    });
  });

  describe('getFarmById', () => {
    it('should return 404 when farm is not found', async () => {
      sinon.stub(Farm, 'findByPk').resolves(null);

      const req = createMockReq({
        params: { id: 'non-existent' },
        user: { id: 'farmer-1', role: 'Farmer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.getFarmById(req, res, next);

      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.data.message, 'Farm not found.');
    });

    it('should return 403 when farmer attempts to access another farmer\'s farm', async () => {
      const otherFarmerFarm = { id: 'farm-other', name: 'Other Farm', farmerId: 'someone-else' };
      sinon.stub(Farm, 'findByPk').resolves(otherFarmerFarm);

      const req = createMockReq({
        params: { id: 'farm-other' },
        user: { id: 'farmer-me', role: 'Farmer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.getFarmById(req, res, next);

      assert.strictEqual(res.statusCode, 403, 'Must return 403 Forbidden');
      assert.strictEqual(res.data.message, 'Forbidden. You do not own this farm.');
    });

    it('should allow Administrator to access any farm', async () => {
      const anyFarm = { id: 'farm-other', name: 'Other Farm', farmerId: 'someone-else' };
      sinon.stub(Farm, 'findByPk').resolves(anyFarm);

      const req = createMockReq({
        params: { id: 'farm-other' },
        user: { id: 'admin-1', role: 'Administrator' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.getFarmById(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.farm.id, 'farm-other');
    });
  });

  describe('updateFarm', () => {
    it('should allow owning farmer to update farm details', async () => {
      const existingFarm = {
        id: 'farm-own',
        name: 'Old Name',
        farmerId: 'farmer-me',
        save: sinon.stub().resolves()
      };
      sinon.stub(Farm, 'findByPk').resolves(existingFarm);

      const req = createMockReq({
        params: { id: 'farm-own' },
        user: { id: 'farmer-me', role: 'Farmer' },
        body: { name: 'Updated Farm Name', capacity: 3000 }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.updateFarm(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(existingFarm.name, 'Updated Farm Name');
      assert.strictEqual(existingFarm.capacity, 3000);
      assert(existingFarm.save.calledOnce);
    });

    it('should reject update with 403 when farmer does not own the farm', async () => {
      const notMyFarm = { id: 'farm-alien', farmerId: 'other-farmer' };
      sinon.stub(Farm, 'findByPk').resolves(notMyFarm);

      const req = createMockReq({
        params: { id: 'farm-alien' },
        user: { id: 'farmer-me', role: 'Farmer' },
        body: { name: 'Hack Name' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.updateFarm(req, res, next);

      assert.strictEqual(res.statusCode, 403);
    });
  });

  describe('deleteFarm', () => {
    it('should allow owning farmer to delete their farm', async () => {
      const myFarm = {
        id: 'farm-to-delete',
        farmerId: 'farmer-me',
        destroy: sinon.stub().resolves()
      };
      sinon.stub(Farm, 'findByPk').resolves(myFarm);

      const req = createMockReq({
        params: { id: 'farm-to-delete' },
        user: { id: 'farmer-me', role: 'Farmer' }
      });
      const res = createMockRes();
      const next = createMockNext();

      await farmController.deleteFarm(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.message, 'Farm deleted successfully');
      assert(myFarm.destroy.calledOnce);
    });
  });
});
