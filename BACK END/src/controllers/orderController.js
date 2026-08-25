const { Order, OrderItem, Product, Farm, User, Delivery, Notification, sequelize } = require('../models');

const createOrder = async (req, res, next) => {
  const transaction = await sequelize.transaction();
  try {
    const { items, shippingAddress, notes } = req.body;
    const customerId = req.user.id;

    if (!items || !Array.isArray(items) || items.length === 0) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Order must contain at least one item.' });
    }

    if (!shippingAddress) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Shipping address is required.' });
    }

    let calculatedTotal = 0;
    const orderItemsToCreate = [];
    const affectedFarmers = new Set();

    for (const item of items) {
      const product = await Product.findByPk(item.productId, {
        include: [{ model: Farm, as: 'farm' }],
        transaction
      });

      if (!product || !product.isAvailable) {
        await transaction.rollback();
        return res.status(404).json({ message: `Product ID '${item.productId}' is not available.` });
      }

      if (product.stockQuantity < item.quantity) {
        await transaction.rollback();
        return res.status(400).json({ 
          message: `Insufficient stock for product '${product.name}'. Available: ${product.stockQuantity}, Requested: ${item.quantity}` 
        });
      }

      // Deduct stock quantity
      product.stockQuantity -= item.quantity;
      await product.save({ transaction });

      const itemTotal = parseFloat(product.price) * item.quantity;
      calculatedTotal += itemTotal;

      orderItemsToCreate.push({
        productId: product.id,
        quantity: item.quantity,
        unitPrice: product.price
      });

      if (product.farm && product.farm.farmerId) {
        affectedFarmers.add(product.farm.farmerId);
      }
    }

    const order = await Order.create({
      customerId,
      totalAmount: calculatedTotal,
      currency: 'FCFA',
      status: 'pending',
      paymentStatus: 'pending',
      shippingAddress,
      notes
    }, { transaction });

    for (const orderItem of orderItemsToCreate) {
      await OrderItem.create({
        orderId: order.id,
        ...orderItem
      }, { transaction });
    }

    // Auto-create Delivery record
    await Delivery.create({
      orderId: order.id,
      status: 'unassigned',
      dropoffAddress: shippingAddress
    }, { transaction });

    await transaction.commit();

    // Notify Farmers about new order
    for (const farmerId of affectedFarmers) {
      await Notification.create({
        userId: farmerId,
        title: 'New Order Received',
        message: `New order #${order.id.substring(0, 8)} placed by customer for your farm products (${calculatedTotal} FCFA).`,
        type: 'order_update'
      });
    }

    const createdOrder = await Order.findByPk(order.id, {
      include: [
        { 
          model: OrderItem, 
          as: 'items', 
          include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'unit'] }] 
        },
        { model: Delivery, as: 'delivery' }
      ]
    });

    return res.status(201).json({ message: 'Order placed successfully on NOVARA', order: createdOrder });
  } catch (error) {
    if (transaction) await transaction.rollback();
    next(error);
  }
};

const initiatePayment = async (req, res, next) => {
  try {
    const { paymentMethod } = req.body; // e.g. 'MTN Mobile Money', 'Orange Money', 'Credit Card'
    const order = await Order.findByPk(req.params.id);

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (req.user.role === 'Customer' && order.customerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this order.' });
    }

    order.paymentMethod = paymentMethod || 'MTN Mobile Money';
    order.paymentStatus = 'paid';
    await order.save();

    await Notification.create({
      userId: order.customerId,
      title: 'Payment Confirmed',
      message: `Payment of ${order.totalAmount} FCFA for order #${order.id.substring(0, 8)} was successful via ${order.paymentMethod}.`,
      type: 'order_update'
    });

    return res.json({ message: 'Payment completed successfully in FCFA', order });
  } catch (error) {
    next(error);
  }
};

const getOrders = async (req, res, next) => {
  try {
    let whereClause = {};

    if (req.user.role === 'Customer') {
      whereClause.customerId = req.user.id;
    }

    const orders = await Order.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'customer', attributes: ['id', 'name', 'email', 'phone'] },
        { 
          model: OrderItem, 
          as: 'items', 
          include: [{ model: Product, as: 'product' }] 
        },
        { model: Delivery, as: 'delivery' }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({ orders });
  } catch (error) {
    next(error);
  }
};

const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'accepted', 'rejected', 'in_transit', 'delivered', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: `Invalid status '${status}'.` });
    }

    const order = await Order.findByPk(req.params.id, {
      include: [{ model: Delivery, as: 'delivery' }]
    });

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    order.status = status;
    await order.save();

    // Notify Customer
    await Notification.create({
      userId: order.customerId,
      title: 'Order Status Updated',
      message: `Your order #${order.id.substring(0, 8)} status is now '${status}'.`,
      type: 'order_update'
    });

    return res.json({ message: 'Order status updated successfully', order });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createOrder,
  initiatePayment,
  getOrders,
  updateOrderStatus
};
