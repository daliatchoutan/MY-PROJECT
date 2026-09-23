const { Delivery, Order, User, Notification, OrderItem, Product, Farm } = require('../models');
const bcrypt = require('bcryptjs');

// Traceability helper include
const deliveryTraceabilityInclude = [
  {
    model: Order,
    as: 'order',
    include: [
      { model: User, as: 'customer', attributes: ['id', 'name', 'phone', 'email', 'address'] },
      {
        model: OrderItem,
        as: 'items',
        include: [
          {
            model: Product,
            as: 'product',
            attributes: ['id', 'name', 'category', 'price', 'imageUrl'],
            include: [
              {
                model: Farm,
                as: 'farm',
                attributes: ['id', 'farmId', 'name', 'location'],
                include: [
                  {
                    model: User,
                    as: 'farmer',
                    attributes: ['id', 'name', 'phone', 'email', 'farmerId']
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  },
  {
    model: User,
    as: 'deliveryPerson',
    attributes: [
      'id',
      'name',
      'phone',
      'email',
      'avatarUrl',
      'deliveryPersonId',
      'driverLicenseNumber',
      'vehicleType',
      'vehiclePlateNumber'
    ]
  }
];

const getDeliveryById = async (req, res, next) => {
  try {
    const delivery = await Delivery.findByPk(req.params.id, {
      include: deliveryTraceabilityInclude
    });

    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found.' });
    }

    if (req.user.role === 'Delivery Person' && delivery.deliveryPersonId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. This delivery is not assigned to you.' });
    }

    return res.json({ delivery });
  } catch (error) {
    next(error);
  }
};

const getAvailableDrivers = async (req, res, next) => {
  try {
    let drivers = await User.findAll({
      where: { role: 'Delivery Person' },
      attributes: ['id', 'name', 'email', 'phone', 'avatarUrl', 'status', 'deliveryPersonId', 'vehicleType', 'vehiclePlateNumber']
    });

    return res.json({ drivers });
  } catch (error) {
    next(error);
  }
};

const assignDelivery = async (req, res, next) => {
  try {
    const { deliveryPersonId } = req.body;
    let delivery = await Delivery.findByPk(req.params.id);

    // If not found by primary key, check if req.params.id is an orderId
    if (!delivery) {
      delivery = await Delivery.findOne({ where: { orderId: req.params.id } });
    }

    // If still not found, check if Order exists and auto-create the Delivery
    if (!delivery) {
      const order = await Order.findByPk(req.params.id);
      if (order) {
        delivery = await Delivery.create({
          orderId: order.id,
          status: 'unassigned',
          dropoffAddress: order.shippingAddress || 'Customer Address'
        });
      }
    }

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

    // Fetch order details for rich notification
    const order = await Order.findByPk(delivery.orderId, {
      include: [{ model: User, as: 'customer', attributes: ['name', 'phone'] }]
    });

    const customerName = order?.customer?.name || 'Customer';
    const customerPhone = order?.customer?.phone ? ` (Tel: ${order.customer.phone})` : '';
    const dropoff = delivery.dropoffAddress ? ` - Delivery to: ${delivery.dropoffAddress}` : '';

    // Create immediate notification for the Delivery Person (safely wrapped)
    try {
      if (driver && driver.id) {
        await Notification.create({
          userId: driver.id,
          title: 'New Delivery Assigned! 🛵',
          message: `You have been assigned to deliver order #${delivery.orderId.substring(0, 8)} for ${customerName}${customerPhone}${dropoff}. Tap to accept.`,
          type: 'delivery_update'
        });
      }
    } catch (notifErr) {
      console.warn('Notice creating driver notification:', notifErr.message);
    }

    // Also notify Customer that courier was assigned (safely checked)
    if (order && order.customerId) {
      try {
        const customerExists = await User.findByPk(order.customerId);
        if (customerExists) {
          await Notification.create({
            userId: order.customerId,
            title: 'Delivery Courier Assigned 🚚',
            message: `${driver.name} has been assigned as your delivery courier for order #${order.id.substring(0, 8)}.`,
            type: 'delivery_update'
          });
        }
      } catch (notifErr) {
        console.warn('Notice creating customer notification:', notifErr.message);
      }
    }

    // Reload with full traceability associations
    const updatedDelivery = await Delivery.findByPk(delivery.id, {
      include: deliveryTraceabilityInclude
    });

    return res.json({ message: 'Delivery assigned successfully', delivery: updatedDelivery });
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
      include: deliveryTraceabilityInclude,
      order: [['createdAt', 'DESC']]
    });

    return res.json({ deliveries });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAvailableDrivers,
  assignDelivery,
  updateDeliveryStatus,
  reportDelayedDelivery,
  confirmDelivery,
  getMyDeliveries,
  getDeliveryById
};
