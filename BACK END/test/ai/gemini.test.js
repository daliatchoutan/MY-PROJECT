const assert = require('assert');
const sinon = require('sinon');
const geminiService = require('../../src/services/geminiService');
const aiController = require('../../src/controllers/aiController');
const { Device, Farm, Notification } = require('../../src/models');

const createMockReq = (data = {}) => ({
  headers: {},
  params: {},
  query: {},
  body: {},
  user: null,
  ...data
});

const createMockRes = () => {
  const res = {
    statusCode: 200,
    data: null,
    status(code) {
      res.statusCode = code;
      return res;
    },
    json(payload) {
      res.data = payload;
      return res;
    }
  };
  return res;
};

describe('Gemini AI Poultry Health & Behavior Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  describe('geminiService', () => {
    it('should report not configured when GEMINI_API_KEY is unset', () => {
      const origKey = process.env.GEMINI_API_KEY;
      delete process.env.GEMINI_API_KEY;
      assert.strictEqual(geminiService.isConfigured(), false);
      process.env.GEMINI_API_KEY = origKey;
    });

    it('should fall back to smart heuristic analysis when unconfigured', async () => {
      const origKey = process.env.GEMINI_API_KEY;
      delete process.env.GEMINI_API_KEY;

      const result = await geminiService.analyzePoultryHealth({
        sensorData: { temperature: 34.5, humidity: 70 },
        farmName: 'Test Broiler Farm'
      });

      assert.strictEqual(result.success, true);
      assert.strictEqual(result.healthStatus, 'warning');
      assert.strictEqual(result.abnormalityDetected, 'Heat Stress Alert');
      assert(result.symptoms.length > 0);
      assert(result.recommendedActions.length > 0);

      process.env.GEMINI_API_KEY = origKey;
    });

    it('should diagnose cold stress when temperature is low (< 18C)', async () => {
      const origKey = process.env.GEMINI_API_KEY;
      delete process.env.GEMINI_API_KEY;

      const result = await geminiService.analyzePoultryHealth({
        sensorData: { temperature: 15.0, humidity: 60 },
        farmName: 'Cold Coop'
      });

      assert.strictEqual(result.success, true);
      assert.strictEqual(result.healthStatus, 'warning');
      assert.strictEqual(result.abnormalityDetected, 'Cold Stress / Huddling');

      process.env.GEMINI_API_KEY = origKey;
    });
  });

  describe('aiController.analyzePoultry', () => {
    it('should analyze poultry and create alert notification on abnormality', async () => {
      const fakeFarm = { id: 'farm-1', name: 'Poultry Farm A', farmerId: 'farmer-100' };
      const fakeDevice = {
        id: 'dev-1',
        deviceSerial: 'ESP32-CAM-01',
        name: 'Coop Camera 1',
        healthStatus: 'good',
        farm: fakeFarm,
        save: sinon.stub().resolves()
      };

      sinon.stub(Device, 'findOne').resolves(fakeDevice);
      sinon.stub(geminiService, 'analyzePoultryHealth').resolves({
        success: true,
        provider: 'Gemini AI',
        healthStatus: 'warning',
        abnormalityDetected: 'Lethargy & Drooping',
        confidence: 0.94,
        flockBehaviorSummary: 'Birds are huddled with drooping wings and reduced mobility.',
        symptoms: ['Drooping wings', 'Head retracted'],
        recommendedActions: ['Isolate affected birds', 'Administer electrolyte solution']
      });

      const fakeNotif = { id: 'notif-1', title: 'AI Health Alert' };
      sinon.stub(Notification, 'create').resolves(fakeNotif);

      const req = createMockReq({
        body: { deviceSerial: 'ESP32-CAM-01', imageBase64: 'data:image/jpeg;base64,abc123' },
        user: { id: 'farmer-100', role: 'Farmer' }
      });
      const res = createMockRes();
      const next = sinon.stub();

      await aiController.analyzePoultry(req, res, next);

      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.success, true);
      assert.strictEqual(res.data.diagnosis.abnormalityDetected, 'Lethargy & Drooping');
      assert.strictEqual(res.data.notificationCreated, true);
      assert.strictEqual(fakeDevice.healthStatus, 'warning');
      assert(fakeDevice.save.calledOnce);
    });

    it('should report AI status', () => {
      const req = createMockReq();
      const res = createMockRes();
      aiController.getAiStatus(req, res);
      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.data.provider, 'Google Gemini');
      assert(Array.isArray(res.data.features));
    });
  });
});
