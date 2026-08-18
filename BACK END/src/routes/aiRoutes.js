const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');

// Python CV service endpoint
router.post('/health-alert', aiController.receiveHealthAlert);

module.exports = router;
