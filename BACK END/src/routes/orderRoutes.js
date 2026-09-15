const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);

router.post('/', authorizeRoles('Customer', 'Administrator'), orderController.createOrder);
router.post('/:id/pay', authorizeRoles('Customer', 'Administrator'), orderController.initiatePayment);
router.get('/', orderController.getOrders);
router.put('/:id/status', authorizeRoles('Farmer', 'Administrator'), orderController.updateOrderStatus);
router.put('/:id', authorizeRoles('Customer', 'Administrator'), orderController.updateOrder);
router.delete('/:id', authorizeRoles('Customer', 'Administrator'), orderController.cancelOrder);

module.exports = router;
