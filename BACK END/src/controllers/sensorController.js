const { SensorReading, Device, Farm, Notification } = require('../models');

const ingestTelemetry = async (req, res, next) => {
  try {
    const { 
      deviceSerial, 
      type,
      foodLevel, 
      waterLevel: rawWaterLevel, 
      waterDetected,
      pumpActive,
      heatLampActive,
      feedCyclesCount,
      streamUrl,
      ipAddress,
      temperature, 
      humidity 
    } = req.body;

    if (!deviceSerial) {
      return res.status(400).json({ message: 'deviceSerial is required.' });
    }

    // Auto-compute numeric water level if boolean waterDetected is sent
    let waterLevel = rawWaterLevel;
    if (waterLevel === undefined && waterDetected !== undefined) {
      waterLevel = waterDetected ? 100.0 : 0.0;
    }

    // 1. Find device or auto-register if device is new
    let device = await Device.findOne({
      where: { deviceSerial },
      include: [{ model: Farm, as: 'farm' }]
    });

    if (!device) {
      // Find first farm to attach device to, or fallback
      const farm = await Farm.findOne();
      if (farm) {
        device = await Device.create({
          deviceSerial,
          name: deviceSerial === 'ESP32-CAM-01' ? 'ESP32-CAM Streamer' : 'ESP32 Poultry Controller',
          type: type || (deviceSerial.includes('CAM') ? 'Camera' : 'ESP32'),
          farmId: farm.id,
          autoMode: true,
          healthStatus: 'excellent'
        });
        device.farm = farm;
        console.log(`✨ Auto-registered new IoT Device: '${deviceSerial}' for farm '${farm.name}'`);
      } else {
        return res.status(404).json({ message: `Device '${deviceSerial}' not found and no farm exists to register it under.` });
      }
    }

    // Update device active state
    device.status = 'active';
    await device.save();

    // 2. Create SensorReading entry
    const reading = await SensorReading.create({
      deviceId: device.id,
      foodLevel: foodLevel !== undefined ? foodLevel : 100.0,
      waterLevel: waterLevel !== undefined ? waterLevel : 100.0,
      temperature: temperature !== undefined ? temperature : 28.0,
      humidity: humidity !== undefined ? humidity : 65.0
    });

    // 3. Automation & Rules Engine
    const automationTriggers = [];

    // Water level alert rule
    if (waterLevel !== undefined && waterLevel < (device.waterThreshold || 20.0)) {
      automationTriggers.push({
        action: 'AUTOMATIC_WATER_PUMP_ON',
        message: `Low water detected (${waterLevel}%). Water pump relay actioned ON.`
      });

      if (device.farm) {
        await Notification.create({
          userId: device.farm.farmerId,
          title: '⚠️ Water Supply Alert',
          message: `Farm '${device.farm.name}' - Low water level detected. Water pump relay actioned ON automatically.`,
          type: 'environmental_alert'
        });
      }
    }

    // Temperature warning rule
    if (temperature !== undefined && (temperature < device.tempMin || temperature > device.tempMax)) {
      const action = temperature > device.tempMax ? 'FAN_COOLING_ON' : 'HEATER_LAMP_ON';
      automationTriggers.push({
        action,
        message: `Temperature anomaly detected (${temperature}°C). System adjusted.`
      });

      if (device.farm) {
        await Notification.create({
          userId: device.farm.farmerId,
          title: '🔥 Chick Thermal Alert',
          message: `Farm '${device.farm.name}' temperature is ${temperature}°C. Heating lamp / climate control adjusted.`,
          type: 'environmental_alert'
        });
      }
    }

    return res.status(201).json({
      message: 'Telemetry ingested successfully',
      deviceSerial,
      reading,
      streamUrl: streamUrl || null,
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
