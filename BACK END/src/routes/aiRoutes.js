const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { verifyToken, optionalVerifyToken } = require('../middleware/authMiddleware');

// Gemini AI Status
router.get('/status', aiController.getAiStatus);

// Gemini AI Multimodal Vision & Behavior Analysis
router.post('/analyze-poultry', optionalVerifyToken, aiController.analyzePoultry);

// Direct ESP32-CAM frame snapshot upload
router.post('/espcam-frame', aiController.receiveEspCamFrame);

// Legacy CV service health alert
router.post('/health-alert', aiController.receiveHealthAlert);

module.exports = router;
