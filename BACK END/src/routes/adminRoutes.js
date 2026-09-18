const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);
router.use(authorizeRoles('Administrator'));

router.get('/stats', adminController.getDashboardStats);
router.get('/reports', adminController.getReports);
router.get('/farmers', adminController.getFarmers);
router.get('/users', adminController.getAllUsers);
router.post('/users', adminController.createUser);
router.put('/users/:id', adminController.updateUser);
router.put('/users/:id/status', adminController.setUserStatus);
router.delete('/users/:id', adminController.deleteUser);

// Pending approvals and approval workflow
router.get('/pending-approvals', adminController.getPendingApprovals);
router.put('/farmers/:id/approve', adminController.approveFarmer);
router.put('/farmers/:id/reject', adminController.rejectFarmer);
router.put('/deliveries/:id/approve', adminController.approveDeliveryPerson);
router.put('/deliveries/:id/reject', adminController.rejectDeliveryPerson);
router.put('/farms/:id/approve', adminController.approveFarm);
router.put('/farms/:id/reject', adminController.rejectFarm);

module.exports = router;
