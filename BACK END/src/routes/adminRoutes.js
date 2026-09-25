const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);

// Administrator-only management & statistics
router.get('/stats', authorizeRoles('Administrator'), adminController.getDashboardStats);
router.get('/reports', authorizeRoles('Administrator'), adminController.getReports);
router.get('/users', authorizeRoles('Administrator'), adminController.getAllUsers);
router.post('/users', authorizeRoles('Administrator'), adminController.createUser);
router.put('/users/:id', authorizeRoles('Administrator'), adminController.updateUser);
router.put('/users/:id/status', authorizeRoles('Administrator'), adminController.setUserStatus);
router.delete('/users/:id', authorizeRoles('Administrator'), adminController.deleteUser);
router.put('/farms/:id/approve', authorizeRoles('Administrator'), adminController.approveFarm);
router.put('/farms/:id/reject', authorizeRoles('Administrator'), adminController.rejectFarm);

// Farm Manager validation (Administrator approves/rejects Farm Managers)
router.get('/farm-managers', authorizeRoles('Administrator'), adminController.getFarmManagers);
router.put('/farm-managers/:id/approve', authorizeRoles('Administrator'), adminController.approveFarmManager);
router.put('/farm-managers/:id/reject', authorizeRoles('Administrator'), adminController.rejectFarmManager);

// Farmer & Delivery Person approvals (managed by Farm Manager, accessible by Administrator)
router.get('/farmers', authorizeRoles('Administrator', 'Farm Manager'), adminController.getFarmers);
router.post('/farmers', authorizeRoles('Administrator', 'Farm Manager'), adminController.createFarmer);
router.get('/pending-approvals', authorizeRoles('Administrator', 'Farm Manager'), adminController.getPendingApprovals);
router.put('/farmers/:id/approve', authorizeRoles('Administrator', 'Farm Manager'), adminController.approveFarmer);
router.put('/farmers/:id/reject', authorizeRoles('Administrator', 'Farm Manager'), adminController.rejectFarmer);
router.put('/deliveries/:id/approve', authorizeRoles('Administrator', 'Farm Manager'), adminController.approveDeliveryPerson);
router.put('/deliveries/:id/reject', authorizeRoles('Administrator', 'Farm Manager'), adminController.rejectDeliveryPerson);
router.put('/drivers/:id/approve', authorizeRoles('Administrator', 'Farm Manager'), adminController.approveDeliveryPerson);
router.put('/drivers/:id/reject', authorizeRoles('Administrator', 'Farm Manager'), adminController.rejectDeliveryPerson);

module.exports = router;
