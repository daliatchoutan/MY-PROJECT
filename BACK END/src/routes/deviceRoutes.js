const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);

router.post('/', authorizeRoles('Farmer', 'Administrator'), deviceController.registerDevice);
router.get('/', authorizeRoles('Farmer', 'Administrator'), deviceController.getDevices);
router.put('/:id', authorizeRoles('Farmer', 'Administrator'), deviceController.updateDeviceThresholds);
router.put('/:id/mode', authorizeRoles('Farmer', 'Administrator'), deviceController.toggleAutoMode);
router.post('/:id/override', authorizeRoles('Farmer', 'Administrator'), deviceController.manualOverride);
router.delete('/:id', authorizeRoles('Farmer', 'Administrator'), deviceController.deleteDevice);

module.exports = router;
