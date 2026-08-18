const { Farm, User, Device } = require('../models');

const createFarm = async (req, res, next) => {
  try {
    const { name, location, capacity, currentPoultryCount } = req.body;
    const farmerId = req.user.role === 'Administrator' && req.body.farmerId ? req.body.farmerId : req.user.id;

    if (!name || !location) {
      return res.status(400).json({ message: 'Farm name and location are required.' });
    }

    const farm = await Farm.create({
      name,
      location,
      capacity: capacity || 0,
      currentPoultryCount: currentPoultryCount || 0,
      farmerId
    });

    return res.status(201).json({ message: 'Farm created successfully', farm });
  } catch (error) {
    next(error);
  }
};

const getFarms = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role === 'Farmer') {
      whereClause.farmerId = req.user.id;
    }

    const farms = await Farm.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'farmer', attributes: ['id', 'name', 'email', 'phone'] },
        { model: Device, as: 'devices' }
      ]
    });

    return res.json({ farms });
  } catch (error) {
    next(error);
  }
};

const getFarmById = async (req, res, next) => {
  try {
    const farm = await Farm.findByPk(req.params.id, {
      include: [
        { model: User, as: 'farmer', attributes: ['id', 'name', 'email', 'phone'] },
        { model: Device, as: 'devices' }
      ]
    });

    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    if (req.user.role === 'Farmer' && farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this farm.' });
    }

    return res.json({ farm });
  } catch (error) {
    next(error);
  }
};

const updateFarm = async (req, res, next) => {
  try {
    const farm = await Farm.findByPk(req.params.id);
    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    if (req.user.role === 'Farmer' && farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this farm.' });
    }

    const { name, location, capacity, currentPoultryCount } = req.body;
    if (name) farm.name = name;
    if (location) farm.location = location;
    if (capacity !== undefined) farm.capacity = capacity;
    if (currentPoultryCount !== undefined) farm.currentPoultryCount = currentPoultryCount;

    await farm.save();
    return res.json({ message: 'Farm updated successfully', farm });
  } catch (error) {
    next(error);
  }
};

const deleteFarm = async (req, res, next) => {
  try {
    const farm = await Farm.findByPk(req.params.id);
    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    if (req.user.role === 'Farmer' && farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this farm.' });
    }

    await farm.destroy();
    return res.json({ message: 'Farm deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createFarm,
  getFarms,
  getFarmById,
  updateFarm,
  deleteFarm
};
