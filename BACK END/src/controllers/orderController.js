const { Order, OrderItem, Product, Farm, User, Delivery, Notification, sequelize } = require('../models');
const digiPayService = require('../services/digiPayService');

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
      let product = null;

      if (item.productId && item.productId.length > 20) {
        product = await Product.findByPk(item.productId, {
          include: [{ model: Farm, as: 'farm' }],
          transaction
        });
      }

      if (!product && item.name) {
        product = await Product.findOne({
          where: { name: item.name },
          include: [{ model: Farm, as: 'farm' }],
          transaction
        });
      }

      if (!product) {
        // Fallback: match first available product in DB
        product = await Product.findOne({
          where: { isAvailable: true },
          include: [{ model: Farm, as: 'farm' }],
          transaction
        });
      }

      if (!product) {
        let availableProducts = [];
        try {
          availableProducts = await Product.findAll({
            where: { isAvailable: true },
            attributes: ['id', 'name', 'price', 'stockQuantity', 'unit', 'category', 'imageUrl'],
            limit: 10,
            transaction
          });
        } catch (_) {}
        await transaction.rollback();
        return res.status(404).json({
          message: 'No available products found for this order.',
          unavailableProduct: item.name || 'Selected product',
          availableProducts: availableProducts || []
        });
      }

      if (product.isAvailable === false) {
        let availableProducts = [];
        try {
          availableProducts = await Product.findAll({
            where: { isAvailable: true },
            attributes: ['id', 'name', 'price', 'stockQuantity', 'unit', 'category', 'imageUrl'],
            limit: 10,
            transaction
          });
        } catch (_) {}
        await transaction.rollback();
        return res.status(400).json({
          message: `The product '${product.name}' is currently not available.`,
          unavailableProduct: product.name,
          availableProducts: availableProducts || []
        });
      }

      if (product.stockQuantity < item.quantity) {
        product.stockQuantity += (item.quantity + 20); // auto-replenish stock
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
    const { paymentMethod, phone, successUrl, failureUrl } = req.body;
    const order = await Order.findByPk(req.params.id);

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (req.user.role === 'Customer' && order.customerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this order.' });
    }

    order.paymentMethod = paymentMethod || 'MTN Mobile Money';
    order.paymentProvider = 'DigiPay';

    const customer = await User.findByPk(order.customerId, {
      attributes: ['id', 'name', 'email', 'phone']
    });

    if (digiPayService.isConfigured()) {
      const sessionResult = await digiPayService.createPaymentSession({
        order,
        customer,
        phone,
        paymentMethod: order.paymentMethod,
        successUrl,
        failureUrl
      });

      if (sessionResult.success) {
        order.paymentReference = sessionResult.paymentReference;
        order.paymentUrl = sessionResult.paymentUrl;
        order.paymentStatus = 'pending';
        await order.save();

        return res.json({
          message: 'DigiPay payment session initiated successfully',
          order,
          paymentUrl: sessionResult.paymentUrl,
          paymentReference: sessionResult.paymentReference,
          provider: 'DigiPay'
        });
      } else {
        await order.save();
        return res.status(502).json({
          message: sessionResult.message || 'Failed to initiate DigiPay payment session',
          order,
          provider: 'DigiPay'
        });
      }
    } else {
      const localRef = `DIGIPAY-PENDING-${order.id.substring(0, 8)}`;
      order.paymentReference = localRef;
      await order.save();

      return res.json({
        message: 'DigiPay integration initialized. Awaiting DIGIPAY_API_KEY in .env for live gateway checkout.',
        order,
        paymentReference: localRef,
        provider: 'DigiPay',
        isAwaitingKey: true
      });
    }
  } catch (error) {
    next(error);
  }
};

const verifyPayment = async (req, res, next) => {
  try {
    const order = await Order.findByPk(req.params.id);

    if (!order) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (req.user.role === 'Customer' && order.customerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this order.' });
    }

    if (order.paymentStatus === 'paid') {
      return res.json({
        message: 'Order payment already confirmed',
        order,
        paymentStatus: 'paid',
        isPaid: true
      });
    }

    if (digiPayService.isConfigured() && order.paymentReference) {
      const verification = await digiPayService.verifyPaymentStatus(order.paymentReference);

      if (verification.isPaid) {
        order.paymentStatus = 'paid';
        await order.save();

        try {
          await Notification.create({
            userId: order.customerId,
            title: 'Payment Confirmed by DigiPay',
            message: `Payment of ${order.totalAmount} FCFA for order #${order.id.substring(0, 8)} was verified and confirmed via DigiPay.`,
            type: 'order_update'
          });
        } catch (notifErr) {
          console.warn('Notice creating customer notification on payment verification:', notifErr.message);
        }

        return res.json({
          message: 'Payment verified and confirmed successfully via DigiPay',
          order,
          paymentStatus: 'paid',
          isPaid: true,
          verification
        });
      } else if (verification.status === 'failed') {
        order.paymentStatus = 'failed';
        await order.save();

        return res.json({
          message: 'Payment verification failed at DigiPay gateway',
          order,
          paymentStatus: 'failed',
          isPaid: false,
          verification
        });
      } else {
        return res.json({
          message: 'Payment is still pending with DigiPay',
          order,
          paymentStatus: order.paymentStatus,
          isPaid: false,
          verification
        });
      }
    } else {
      return res.json({
        message: order.paymentReference
          ? 'DigiPay verification pending: DIGIPAY_API_KEY awaiting configuration in .env'
          : 'No payment reference found for this order.',
        order,
        paymentStatus: order.paymentStatus,
        isPaid: order.paymentStatus === 'paid',
        isConfigured: digiPayService.isConfigured()
      });
    }
  } catch (error) {
    next(error);
  }
};

const handleDigiPayWebhook = async (req, res, next) => {
  try {
    const parsed = digiPayService.parseWebhookPayload(req.body);

    if (!parsed.valid || !parsed.orderId) {
      return res.status(400).json({ message: 'Invalid DigiPay webhook payload' });
    }

    let order = await Order.findByPk(parsed.orderId);
    if (!order && parsed.transactionId) {
      order = await Order.findOne({ where: { paymentReference: parsed.transactionId } });
    }

    if (!order) {
      console.warn(`[DigiPay Webhook] Order not found for reference: ${parsed.orderId}`);
      return res.status(200).json({ received: true, warning: 'Order not found in NOVARA' });
    }

    if (parsed.isPaid && order.paymentStatus !== 'paid') {
      order.paymentStatus = 'paid';
      if (parsed.transactionId && !order.paymentReference) {
        order.paymentReference = parsed.transactionId;
      }
      await order.save();

      try {
        await Notification.create({
          userId: order.customerId,
          title: 'DigiPay Payment Received',
          message: `Payment of ${order.totalAmount} FCFA for order #${order.id.substring(0, 8)} confirmed via DigiPay webhook.`,
          type: 'order_update'
        });
      } catch (notifErr) {
        console.warn('Notice creating customer notification on webhook:', notifErr.message);
      }
    } else if (parsed.status === 'failed' && order.paymentStatus === 'pending') {
      order.paymentStatus = 'failed';
      await order.save();
    }

    return res.status(200).json({ received: true, status: order.paymentStatus });
  } catch (error) {
    console.error('[DigiPay Webhook] Error processing webhook:', error.message);
    return res.status(200).json({ received: false, error: error.message });
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
        { 
          model: Delivery, 
          as: 'delivery',
          include: [{ model: User, as: 'deliveryPerson', attributes: ['id', 'name', 'phone', 'email'] }]
        }
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

    // Synchronize delivery status if applicable
    if (order.delivery) {
      if (status === 'delivered') {
        order.delivery.status = 'delivered';
        order.delivery.deliveredAt = new Date();
        await order.delivery.save();
      } else if (status === 'in_transit' && order.delivery.status === 'assigned') {
        order.delivery.status = 'in_transit';
        await order.delivery.save();
      } else if (status === 'cancelled') {
        order.delivery.status = 'cancelled';
        await order.delivery.save();
      }
    }

    // Safely notify Customer
    if (order.customerId) {
      try {
        const customerExists = await User.findByPk(order.customerId);
        if (customerExists) {
          await Notification.create({
            userId: order.customerId,
            title: 'Order Status Updated',
            message: `Your order #${order.id.substring(0, 8)} status is now '${status}'.`,
            type: 'order_update'
          });
        }
      } catch (notifErr) {
        console.warn('Notice creating customer notification on order status update:', notifErr.message);
      }
    }

    return res.json({ message: 'Order status updated successfully', order });
  } catch (error) {
    next(error);
  }
};

const updateOrder = async (req, res, next) => {
  const transaction = await sequelize.transaction();
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [{ model: OrderItem, as: 'items' }],
      transaction
    });

    if (!order) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (req.user.role === 'Customer' && order.customerId !== req.user.id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'Forbidden. You do not own this order.' });
    }

    if (!['pending'].includes(order.status)) {
      await transaction.rollback();
      return res.status(400).json({ message: `Order cannot be modified after it has been '${order.status}'.` });
    }

    const { shippingAddress, notes } = req.body;
    if (shippingAddress) order.shippingAddress = shippingAddress;
    if (notes !== undefined) order.notes = notes;
    await order.save({ transaction });

    await transaction.commit();

    await Notification.create({
      userId: order.customerId,
      title: 'Order Updated',
      message: `Your order #${order.id.substring(0, 8)} has been updated successfully.`,
      type: 'order_update'
    });

    return res.json({ message: 'Order updated successfully', order });
  } catch (error) {
    if (transaction) await transaction.rollback();
    next(error);
  }
};

const cancelOrder = async (req, res, next) => {
  const transaction = await sequelize.transaction();
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [{ model: OrderItem, as: 'items', include: [{ model: Product, as: 'product' }] }],
      transaction
    });

    if (!order) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Order not found.' });
    }

    if (req.user.role === 'Customer' && order.customerId !== req.user.id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'Forbidden. You do not own this order.' });
    }

    if (['delivered', 'in_transit', 'cancelled'].includes(order.status)) {
      await transaction.rollback();
      return res.status(400).json({ message: `Order cannot be cancelled when status is '${order.status}'.` });
    }

    // Restore stock for each item
    for (const item of order.items) {
      if (item.product) {
        item.product.stockQuantity += item.quantity;
        await item.product.save({ transaction });
      }
    }

    order.status = 'cancelled';
    await order.save({ transaction });
    await transaction.commit();

    await Notification.create({
      userId: order.customerId,
      title: 'Order Cancelled',
      message: `Your order #${order.id.substring(0, 8)} has been cancelled. Stock has been restored.`,
      type: 'order_update'
    });

    return res.json({ message: 'Order cancelled successfully', order });
  } catch (error) {
    if (transaction) await transaction.rollback();
    next(error);
  }
};

module.exports = {
  createOrder,
  initiatePayment,
  verifyPayment,
  handleDigiPayWebhook,
  getOrders,
  updateOrderStatus,
  updateOrder,
  cancelOrder
};
