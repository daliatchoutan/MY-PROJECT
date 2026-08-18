const express = require('express');
const router = express.Router();
const deliveryController = require('../controllers/deliveryController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);

router.get('/', authorizeRoles('Delivery Person', 'Administrator', 'Farmer'), deliveryController.getMyDeliveries);
router.put('/:id/assign', authorizeRoles('Farmer', 'Administrator'), deliveryController.assignDelivery);
router.put('/:id/status', authorizeRoles('Delivery Person', 'Administrator'), deliveryController.updateDeliveryStatus);

module.exports = router;
