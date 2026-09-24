const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

// Public Webhook route for DigiPay payment notifications (called by payment gateway)
router.post('/webhook/digipay', orderController.handleDigiPayWebhook);

router.use(verifyToken);

router.post('/', authorizeRoles('Customer', 'Administrator'), orderController.createOrder);
router.post('/:id/pay', authorizeRoles('Customer', 'Administrator'), orderController.initiatePayment);
router.get('/:id/verify-payment', authorizeRoles('Customer', 'Farmer', 'Administrator'), orderController.verifyPayment);
router.get('/', orderController.getOrders);
router.put('/:id/status', authorizeRoles('Farmer', 'Administrator'), orderController.updateOrderStatus);
router.put('/:id', authorizeRoles('Customer', 'Administrator'), orderController.updateOrder);
router.delete('/:id', authorizeRoles('Customer', 'Administrator'), orderController.cancelOrder);

module.exports = router;
