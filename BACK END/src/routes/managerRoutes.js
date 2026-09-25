const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const deliveryController = require('../controllers/deliveryController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);
router.use(authorizeRoles('Farm Manager', 'Administrator'));

// Farmers Management
router.get('/farmers', adminController.getFarmers);
router.put('/farmers/:id/approve', adminController.approveFarmer);
router.put('/farmers/:id/reject', adminController.rejectFarmer);

// Delivery Persons / Couriers Management
router.get('/drivers', deliveryController.getAvailableDrivers);
router.put('/drivers/:id/approve', adminController.approveDeliveryPerson);
router.put('/drivers/:id/reject', adminController.rejectDeliveryPerson);
router.put('/deliveries/:id/approve', adminController.approveDeliveryPerson);
router.put('/deliveries/:id/reject', adminController.rejectDeliveryPerson);

// Pending approvals queue
router.get('/pending-approvals', adminController.getPendingApprovals);

module.exports = router;
