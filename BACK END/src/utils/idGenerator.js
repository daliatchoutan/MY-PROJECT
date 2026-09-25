const { Op } = require('sequelize');

/**
 * Helper to generate sequential NOVARA identifiers
 * Format:
 *  - Farmer: NOV-FRM-xxxxx (e.g. NOV-FRM-00001)
 *  - Delivery Person: NOV-DRV-xxxxx (e.g. NOV-DRV-00001)
 *  - Farm: NOV-FARM-xxxxx (e.g. NOV-FARM-00001)
 */

async function generateFarmerId(UserModel) {
  const prefix = 'NOV-FRM-';
  try {
    const lastUser = await UserModel.findOne({
      where: {
        farmerId: {
          [Op.like]: `${prefix}%`
        }
      },
      order: [['createdAt', 'DESC']]
    });

    let nextNumber = 1;
    if (lastUser && lastUser.farmerId) {
      const parts = lastUser.farmerId.split('-');
      const lastNum = parseInt(parts[parts.length - 1], 10);
      if (!isNaN(lastNum)) {
        nextNumber = lastNum + 1;
      }
    } else {
      // Fallback check total farmers
      const count = await UserModel.count({ where: { role: 'Farmer' } });
      nextNumber = count + 1;
    }

    // Ensure uniqueness in case of gaps
    let candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
    let exists = await UserModel.findOne({ where: { farmerId: candidate } });
    while (exists) {
      nextNumber++;
      candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
      exists = await UserModel.findOne({ where: { farmerId: candidate } });
    }

    return candidate;
  } catch (err) {
    const randomSuffix = Math.floor(10000 + Math.random() * 90000);
    return `${prefix}${randomSuffix}`;
  }
}

async function generateFarmManagerId(UserModel) {
  const prefix = 'NOV-MGR-';
  try {
    const lastUser = await UserModel.findOne({
      where: {
        farmManagerId: {
          [Op.like]: `${prefix}%`
        }
      },
      order: [['createdAt', 'DESC']]
    });

    let nextNumber = 1;
    if (lastUser && lastUser.farmManagerId) {
      const parts = lastUser.farmManagerId.split('-');
      const lastNum = parseInt(parts[parts.length - 1], 10);
      if (!isNaN(lastNum)) {
        nextNumber = lastNum + 1;
      }
    } else {
      const count = await UserModel.count({ where: { role: 'Farm Manager' } });
      nextNumber = count + 1;
    }

    let candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
    let exists = await UserModel.findOne({ where: { farmManagerId: candidate } });
    while (exists) {
      nextNumber++;
      candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
      exists = await UserModel.findOne({ where: { farmManagerId: candidate } });
    }

    return candidate;
  } catch (err) {
    const randomSuffix = Math.floor(10000 + Math.random() * 90000);
    return `${prefix}${randomSuffix}`;
  }
}

async function generateDeliveryPersonId(UserModel) {
  const prefix = 'NOV-DRV-';
  try {
    const lastCourier = await UserModel.findOne({
      where: {
        deliveryPersonId: {
          [Op.like]: `${prefix}%`
        }
      },
      order: [['createdAt', 'DESC']]
    });

    let nextNumber = 1;
    if (lastCourier && lastCourier.deliveryPersonId) {
      const parts = lastCourier.deliveryPersonId.split('-');
      const lastNum = parseInt(parts[parts.length - 1], 10);
      if (!isNaN(lastNum)) {
        nextNumber = lastNum + 1;
      }
    } else {
      const count = await UserModel.count({ where: { role: 'Delivery Person' } });
      nextNumber = count + 1;
    }

    let candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
    let exists = await UserModel.findOne({ where: { deliveryPersonId: candidate } });
    while (exists) {
      nextNumber++;
      candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
      exists = await UserModel.findOne({ where: { deliveryPersonId: candidate } });
    }

    return candidate;
  } catch (err) {
    const randomSuffix = Math.floor(10000 + Math.random() * 90000);
    return `${prefix}${randomSuffix}`;
  }
}

async function generateFarmId(FarmModel) {
  const prefix = 'NOV-FARM-';
  try {
    const lastFarm = await FarmModel.findOne({
      where: {
        farmId: {
          [Op.like]: `${prefix}%`
        }
      },
      order: [['createdAt', 'DESC']]
    });

    let nextNumber = 1;
    if (lastFarm && lastFarm.farmId) {
      const parts = lastFarm.farmId.split('-');
      const lastNum = parseInt(parts[parts.length - 1], 10);
      if (!isNaN(lastNum)) {
        nextNumber = lastNum + 1;
      }
    } else {
      const count = await FarmModel.count();
      nextNumber = count + 1;
    }

    let candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
    let exists = await FarmModel.findOne({ where: { farmId: candidate } });
    while (exists) {
      nextNumber++;
      candidate = `${prefix}${String(nextNumber).padStart(5, '0')}`;
      exists = await FarmModel.findOne({ where: { farmId: candidate } });
    }

    return candidate;
  } catch (err) {
    const randomSuffix = Math.floor(10000 + Math.random() * 90000);
    return `${prefix}${randomSuffix}`;
  }
}

module.exports = {
  generateFarmerId,
  generateFarmManagerId,
  generateDeliveryPersonId,
  generateFarmId
};
