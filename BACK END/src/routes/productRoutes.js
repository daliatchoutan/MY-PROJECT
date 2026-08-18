const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

// Public Marketplace Endpoints
router.get('/', productController.getProducts);
router.get('/:id', productController.getProductById);

// Farmer & Admin Inventory Endpoints
router.post('/', verifyToken, authorizeRoles('Farmer', 'Administrator'), productController.createProduct);
router.put('/:id', verifyToken, authorizeRoles('Farmer', 'Administrator'), productController.updateProduct);
router.delete('/:id', verifyToken, authorizeRoles('Farmer', 'Administrator'), productController.deleteProduct);

module.exports = router;
