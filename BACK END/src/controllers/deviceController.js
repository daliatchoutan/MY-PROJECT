const { Device, Farm, SensorReading, Notification } = require('../models');

const registerDevice = async (req, res, next) => {
  try {
    const { deviceSerial, name, type, farmId, foodThreshold, waterThreshold, tempMin, tempMax, humidityMin, humidityMax } = req.body;

    if (!deviceSerial || !name || !farmId) {
      return res.status(400).json({ message: 'deviceSerial, name, and farmId are required.' });
    }

    const farm = await Farm.findByPk(farmId);
    if (!farm) {
      return res.status(404).json({ message: 'Target farm not found.' });
    }

    const existingDevice = await Device.findOne({ where: { deviceSerial } });
    if (existingDevice) {
      return res.status(400).json({ message: 'Device serial number already registered.' });
    }

    const device = await Device.create({
      deviceSerial,
      name,
      type: type || 'ESP32',
      farmId,
      autoMode: true,
      healthStatus: 'good',
      foodThreshold: foodThreshold !== undefined ? foodThreshold : 20.0,
      waterThreshold: waterThreshold !== undefined ? waterThreshold : 20.0,
      tempMin: tempMin !== undefined ? tempMin : 20.0,
      tempMax: tempMax !== undefined ? tempMax : 32.0,
      humidityMin: humidityMin !== undefined ? humidityMin : 50.0,
      humidityMax: humidityMax !== undefined ? humidityMax : 75.0
    });

    return res.status(201).json({ message: 'IoT Device registered successfully', device });
  } catch (error) {
    next(error);
  }
};

const getDevices = async (req, res, next) => {
  try {
    const { farmId } = req.query;
    let whereClause = {};
    if (farmId) whereClause.farmId = farmId;

    const devices = await Device.findAll({
      where: whereClause,
      include: [{ model: Farm, as: 'farm', attributes: ['id', 'name', 'location'] }]
    });

    return res.json({ devices });
  } catch (error) {
    next(error);
  }
};

const updateDeviceThresholds = async (req, res, next) => {
  try {
    const device = await Device.findByPk(req.params.id);
    if (!device) {
      return res.status(404).json({ message: 'Device not found.' });
    }

    const { status, autoMode, healthStatus, foodThreshold, waterThreshold, tempMin, tempMax, humidityMin, humidityMax } = req.body;
    if (status) device.status = status;
    if (autoMode !== undefined) device.autoMode = autoMode;
    if (healthStatus) device.healthStatus = healthStatus;
    if (foodThreshold !== undefined) device.foodThreshold = foodThreshold;
    if (waterThreshold !== undefined) device.waterThreshold = waterThreshold;
    if (tempMin !== undefined) device.tempMin = tempMin;
    if (tempMax !== undefined) device.tempMax = tempMax;
    if (humidityMin !== undefined) device.humidityMin = humidityMin;
    if (humidityMax !== undefined) device.humidityMax = humidityMax;

    await device.save();
    return res.json({ message: 'Device thresholds updated successfully', device });
  } catch (error) {
    next(error);
  }
};

const toggleAutoMode = async (req, res, next) => {
  try {
    const device = await Device.findByPk(req.params.id);
    if (!device) {
      return res.status(404).json({ message: 'Device not found.' });
    }

    const { autoMode } = req.body;
    device.autoMode = autoMode !== undefined ? autoMode : !device.autoMode;
    await device.save();

    return res.json({
      message: `Automatic Control Mode is now ${device.autoMode ? 'ACTIVATED' : 'DEACTIVATED'}`,
      device
    });
  } catch (error) {
    next(error);
  }
};

const manualOverride = async (req, res, next) => {
  try {
    const { action } = req.body; // 'FEEDER_ON', 'WATER_VALVE_ON', 'FAN_ON', 'HEATER_ON'
    const device = await Device.findByPk(req.params.id, {
      include: [{ model: Farm, as: 'farm' }]
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found.' });
    }

    const validActions = ['FEEDER_ON', 'WATER_VALVE_ON', 'FAN_ON', 'HEATER_ON'];
    if (!validActions.includes(action)) {
      return res.status(400).json({ message: `Invalid override action '${action}'. Valid actions: ${validActions.join(', ')}` });
    }

    await Notification.create({
      userId: device.farm.farmerId,
      title: `Manual Actuator Override: ${action}`,
      message: `Manual override triggered for device '${device.name}' (${action}).`,
      type: 'environmental_alert'
    });

    return res.json({
      message: `Manual actuator command '${action}' executed successfully on device '${device.name}'.`,
      action,
      deviceId: device.id,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
};

const deleteDevice = async (req, res, next) => {
  try {
    const device = await Device.findByPk(req.params.id);
    if (!device) {
      return res.status(404).json({ message: 'Device not found.' });
    }

    await device.destroy();
    return res.json({ message: 'Device removed successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerDevice,
  getDevices,
  updateDeviceThresholds,
  toggleAutoMode,
  manualOverride,
  deleteDevice
};
