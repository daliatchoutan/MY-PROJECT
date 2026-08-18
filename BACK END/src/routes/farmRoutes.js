const express = require('express');
const router = express.Router();
const farmController = require('../controllers/farmController');
const { verifyToken, authorizeRoles } = require('../middleware/authMiddleware');

router.use(verifyToken);

router.post('/', authorizeRoles('Farmer', 'Administrator'), farmController.createFarm);
router.get('/', authorizeRoles('Farmer', 'Administrator'), farmController.getFarms);
router.get('/:id', authorizeRoles('Farmer', 'Administrator'), farmController.getFarmById);
router.put('/:id', authorizeRoles('Farmer', 'Administrator'), farmController.updateFarm);
router.delete('/:id', authorizeRoles('Farmer', 'Administrator'), farmController.deleteFarm);

module.exports = router;
