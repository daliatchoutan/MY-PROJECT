const { SensorReading, Device, Farm, Notification } = require('../models');

const ingestTelemetry = async (req, res, next) => {
  try {
    const { deviceSerial, foodLevel, waterLevel, temperature, humidity } = req.body;

    if (!deviceSerial) {
      return res.status(400).json({ message: 'deviceSerial is required.' });
    }

    const device = await Device.findOne({
      where: { deviceSerial },
      include: [{ model: Farm, as: 'farm' }]
    });

    if (!device) {
      return res.status(404).json({ message: `Device '${deviceSerial}' not found.` });
    }

    const reading = await SensorReading.create({
      deviceId: device.id,
      foodLevel,
      waterLevel,
      temperature,
      humidity
    });

    // Phase 6: Automation & Threshold Rules Engine
    const automationTriggers = [];

    if (foodLevel !== undefined && foodLevel < device.foodThreshold) {
      automationTriggers.push({
        action: 'AUTOMATIC_FEEDING_DISPENSER_ON',
        message: `Low food level detected (${foodLevel}% < ${device.foodThreshold}% threshold). Dispenser activated.`
      });

      await Notification.create({
        userId: device.farm.farmerId,
        title: 'Low Food Level Warning',
        message: `Farm '${device.farm.name}' - Device '${device.name}' food level dropped to ${foodLevel}%. Automated feeding triggered.`,
        type: 'environmental_alert'
      });
    }

    if (waterLevel !== undefined && waterLevel < device.waterThreshold) {
      automationTriggers.push({
        action: 'AUTOMATIC_WATER_VALVE_OPEN',
        message: `Low water level detected (${waterLevel}% < ${device.waterThreshold}% threshold). Valve opened.`
      });

      await Notification.create({
        userId: device.farm.farmerId,
        title: 'Low Water Level Warning',
        message: `Farm '${device.farm.name}' - Device '${device.name}' water level dropped to ${waterLevel}%. Automated refill triggered.`,
        type: 'environmental_alert'
      });
    }

    if (temperature !== undefined && (temperature < device.tempMin || temperature > device.tempMax)) {
      const action = temperature > device.tempMax ? 'FAN_COOLING_ON' : 'HEATER_ON';
      automationTriggers.push({
        action,
        message: `Temperature anomaly detected (${temperature}°C outside ${device.tempMin}-${device.tempMax}°C range). System adjusted.`
      });

      await Notification.create({
        userId: device.farm.farmerId,
        title: 'Temperature Threshold Alert',
        message: `Farm '${device.farm.name}' - Device '${device.name}' temperature is ${temperature}°C. Automated climate adjustment activated.`,
        type: 'environmental_alert'
      });
    }

    return res.status(201).json({
      message: 'Telemetry ingested successfully',
      reading,
      automationTriggers
    });
  } catch (error) {
    next(error);
  }
};

const getLiveReadings = async (req, res, next) => {
  try {
    const { deviceId } = req.params;

    const latestReading = await SensorReading.findOne({
      where: { deviceId },
      order: [['createdAt', 'DESC']]
    });

    return res.json({ latestReading });
  } catch (error) {
    next(error);
  }
};

const getReadingHistory = async (req, res, next) => {
  try {
    const { deviceId } = req.params;
    const limit = parseInt(req.query.limit) || 50;

    const history = await SensorReading.findAll({
      where: { deviceId },
      order: [['createdAt', 'DESC']],
      limit
    });

    return res.json({ history });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  ingestTelemetry,
  getLiveReadings,
  getReadingHistory
};
