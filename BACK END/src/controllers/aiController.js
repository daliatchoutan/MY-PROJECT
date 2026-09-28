const { Device, Farm, Notification, SensorReading } = require('../models');
const geminiService = require('../services/geminiService');

/**
 * Live Gemini AI Poultry Health & Behavior Analysis
 * Analyzes an image (from ESP32-CAM or uploaded photo) + sensor metrics
 */
const analyzePoultry = async (req, res, next) => {
  try {
    const { deviceSerial, imageBase64, imageUrl, farmId, customPrompt } = req.body;

    let device = null;
    let farm = null;
    let sensorData = req.body.sensorData || {};

    if (deviceSerial) {
      device = await Device.findOne({
        where: { deviceSerial },
        include: [{ model: Farm, as: 'farm' }]
      });
      if (device && device.farm) {
        farm = device.farm;
      }
    } else if (farmId) {
      farm = await Farm.findByPk(farmId);
    }

    // If device found and no sensorData provided, fetch latest sensor reading
    if (device && (!sensorData.temperature && !sensorData.humidity)) {
      const latestReading = await SensorReading.findOne({
        where: { deviceId: device.id },
        order: [['createdAt', 'DESC']]
      });
      if (latestReading) {
        sensorData = {
          temperature: latestReading.temperature,
          humidity: latestReading.humidity,
          foodLevel: latestReading.foodLevel,
          waterLevel: latestReading.waterLevel
        };
      }
    }

    const diagnosis = await geminiService.analyzePoultryHealth({
      imageBase64,
      imageUrl,
      sensorData,
      farmName: farm ? farm.name : 'NOVARA Poultry Coop',
      flockType: farm ? farm.type || 'Broiler / Layer' : 'Poultry'
    });

    // Update device health status in database if device is linked
    if (device && diagnosis.healthStatus) {
      device.healthStatus = diagnosis.healthStatus;
      await device.save();
    }

    // Automatically create a notification for the farmer if an abnormality is detected
    let notification = null;
    const recipientId = farm ? farm.farmerId : req.user?.id;
    if (recipientId && diagnosis.healthStatus !== 'healthy' && diagnosis.abnormalityDetected !== 'None') {
      notification = await Notification.create({
        userId: recipientId,
        title: `AI Health Alert: ${diagnosis.abnormalityDetected}`,
        message: `Farm '${farm ? farm.name : 'Poultry Coop'}': ${diagnosis.flockBehaviorSummary} Symptoms: ${(diagnosis.symptoms || []).join(', ')}. Action: ${(diagnosis.recommendedActions || []).slice(0, 2).join('; ')}`,
        type: 'ai_alert'
      });
    }

    return res.json({
      success: true,
      diagnosis,
      sensorData,
      deviceSerial: deviceSerial || null,
      farmName: farm ? farm.name : null,
      notificationCreated: Boolean(notification),
      notification
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Direct ESP32-CAM frame upload endpoint for automated background flock monitoring
 */
const receiveEspCamFrame = async (req, res, next) => {
  try {
    const deviceSerial = req.query.deviceSerial || req.body.deviceSerial || 'ESP32-CAM-01';
    const imageBase64 = req.body.imageBase64 || req.body.image;

    const device = await Device.findOne({
      where: { deviceSerial },
      include: [{ model: Farm, as: 'farm' }]
    });

    const diagnosis = await geminiService.analyzePoultryHealth({
      imageBase64,
      farmName: device?.farm?.name || 'ESP32-CAM Monitored Coop',
      flockType: 'Poultry Flock'
    });

    if (device && diagnosis.healthStatus) {
      device.healthStatus = diagnosis.healthStatus;
      await device.save();
    }

    let alertCreated = false;
    if (device?.farm?.farmerId && diagnosis.healthStatus !== 'healthy' && diagnosis.abnormalityDetected !== 'None') {
      await Notification.create({
        userId: device.farm.farmerId,
        title: `ESP32-CAM AI Alert: ${diagnosis.abnormalityDetected}`,
        message: `Camera '${device.name}' detected flock anomaly: ${diagnosis.flockBehaviorSummary} (Confidence: ${Math.round((diagnosis.confidence || 0.9) * 100)}%)`,
        type: 'ai_alert'
      });
      alertCreated = true;
    }

    return res.status(201).json({
      success: true,
      message: 'ESP32-CAM frame analyzed with Gemini AI',
      diagnosis,
      alertCreated
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Legacy health alert ingestion
 */
const receiveHealthAlert = async (req, res, next) => {
  try {
    const { deviceSerial, confidence, abnormalityDetected, description } = req.body;

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

    const notification = await Notification.create({
      userId: device.farm.farmerId,
      title: `AI Health Alert: ${abnormalityDetected || 'Abnormality Detected'}`,
      message: `Farm '${device.farm.name}' - Camera '${device.name}' detected health issue: ${description || 'Irregular poultry movement or symptom detected.'} (Confidence: ${((confidence || 0) * 100).toFixed(1)}%).`,
      type: 'ai_alert'
    });

    return res.status(201).json({
      message: 'AI Health detection alert processed and farmer notified.',
      notification
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Check Gemini AI status
 */
const getAiStatus = (req, res) => {
  return res.json({
    configured: geminiService.isConfigured(),
    provider: 'Google Gemini',
    features: [
      'Multimodal Poultry Vision Analysis',
      'Flock Behavioral Anomaly Detection',
      'ESP32-CAM Real-time Stream Frame Diagnostics',
      'Environmental Telemetry Correlation (Heat & Cold Stress)'
    ]
  });
};

module.exports = {
  analyzePoultry,
  receiveEspCamFrame,
  receiveHealthAlert,
  getAiStatus
};
