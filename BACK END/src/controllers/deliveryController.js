const { Delivery, Order, User, Notification } = require('../models');

const assignDelivery = async (req, res, next) => {
  try {
    const { deliveryPersonId } = req.body;
    const delivery = await Delivery.findByPk(req.params.id);

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found.' });
    }

    const driver = await User.findOne({
      where: { id: deliveryPersonId, role: 'Delivery Person' }
    });

    if (!driver) {
      return res.status(400).json({ message: 'Specified delivery person not found or role is invalid.' });
    }

    delivery.deliveryPersonId = driver.id;
    delivery.status = 'assigned';
    delivery.assignedAt = new Date();
    await delivery.save();

    await Notification.create({
      userId: driver.id,
      title: 'New Delivery Assigned',
      message: `You have been assigned to delivery #${delivery.id.substring(0, 8)}.`,
      type: 'delivery_update'
    });

    return res.json({ message: 'Delivery assigned successfully', delivery });
  } catch (error) {
    next(error);
  }
};

const updateDeliveryStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['accepted', 'picked_up', 'delivered', 'delayed', 'failed'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: `Invalid delivery status '${status}'.` });
    }

    const delivery = await Delivery.findByPk(req.params.id, {
      include: [{ model: Order, as: 'order' }]
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found.' });
    }

    if (req.user.role === 'Delivery Person' && delivery.deliveryPersonId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. This delivery is not assigned to you.' });
    }

    delivery.status = status;
    if (status === 'delivered') {
      delivery.deliveredAt = new Date();
      delivery.confirmedAt = new Date();
      if (delivery.order) {
        delivery.order.status = 'delivered';
        await delivery.order.save();
      }
    } else if (status === 'picked_up') {
      if (delivery.order) {
        delivery.order.status = 'in_transit';
        await delivery.order.save();
      }
    }

    await delivery.save();

    if (delivery.order && delivery.order.customerId) {
      await Notification.create({
        userId: delivery.order.customerId,
        title: 'Delivery Update',
        message: `Your package for order #${delivery.orderId.substring(0, 8)} status is now '${status}'.`,
        type: 'delivery_update'
      });
    }

    return res.json({ message: 'Delivery status updated successfully', delivery });
  } catch (error) {
    next(error);
  }
};

const reportDelayedDelivery = async (req, res, next) => {
  try {
    const { delayReason } = req.body;
    if (!delayReason) {
      return res.status(400).json({ message: 'Delay reason is required.' });
    }

    const delivery = await Delivery.findByPk(req.params.id, {
      include: [{ model: Order, as: 'order' }]
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found.' });
    }

    if (req.user.role === 'Delivery Person' && delivery.deliveryPersonId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. This delivery is not assigned to you.' });
    }

    delivery.status = 'delayed';
    delivery.isDelayed = true;
    delivery.delayReason = delayReason;
    await delivery.save();

    if (delivery.order && delivery.order.customerId) {
      await Notification.create({
        userId: delivery.order.customerId,
        title: 'Delivery Delay Notice',
        message: `Delivery #${delivery.id.substring(0, 8)} has been delayed: ${delayReason}`,
        type: 'delivery_update'
      });
    }

    return res.json({ message: 'Delivery delay reported successfully', delivery });
  } catch (error) {
    next(error);
  }
};

const confirmDelivery = async (req, res, next) => {
  try {
    const delivery = await Delivery.findByPk(req.params.id, {
      include: [{ model: Order, as: 'order' }]
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found.' });
    }

    if (req.user.role === 'Delivery Person' && delivery.deliveryPersonId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. This delivery is not assigned to you.' });
    }

    delivery.status = 'delivered';
    delivery.deliveredAt = new Date();
    delivery.confirmedAt = new Date();

    if (delivery.order) {
      delivery.order.status = 'delivered';
      await delivery.order.save();
    }

    await delivery.save();

    if (delivery.order && delivery.order.customerId) {
      await Notification.create({
        userId: delivery.order.customerId,
        title: 'Delivery Confirmed Successful!',
        message: `Your order #${delivery.orderId.substring(0, 8)} has been successfully delivered and confirmed.`,
        type: 'delivery_update'
      });
    }

    return res.json({ message: 'Delivery confirmed successfully', delivery });
  } catch (error) {
    next(error);
  }
};

const getMyDeliveries = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role === 'Delivery Person') {
      whereClause.deliveryPersonId = req.user.id;
    }

    const deliveries = await Delivery.findAll({
      where: whereClause,
      include: [
        { model: Order, as: 'order', include: [{ model: User, as: 'customer', attributes: ['id', 'name', 'phone'] }] },
        { model: User, as: 'deliveryPerson', attributes: ['id', 'name', 'phone'] }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({ deliveries });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  assignDelivery,
  updateDeliveryStatus,
  reportDelayedDelivery,
  confirmDelivery,
  getMyDeliveries
};
