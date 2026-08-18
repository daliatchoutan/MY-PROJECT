const express = require('express');
const router = express.Router();
const sensorController = require('../controllers/sensorController');
const { verifyToken } = require('../middleware/authMiddleware');

// ESP32 Telemetry endpoint (Public/IoT Serial Auth)
router.post('/telemetry', sensorController.ingestTelemetry);

// Authenticated Reading queries
router.get('/live/:deviceId', verifyToken, sensorController.getLiveReadings);
router.get('/history/:deviceId', verifyToken, sensorController.getReadingHistory);

module.exports = router;
