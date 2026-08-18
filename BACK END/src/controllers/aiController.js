const { Device, Farm, Notification } = require('../models');

const receiveHealthAlert = async (req, res, next) => {
  try {
    const { deviceSerial, confidence, abnormalityDetected, description, imageUrl } = req.body;

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

    // Create high priority notification for the farmer
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

module.exports = {
  receiveHealthAlert
};
