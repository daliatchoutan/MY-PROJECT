/**
 * DigiPay Payment Gateway Service for NOVARA
 * Based on official documentation: https://digitalcertify.tech/docs
 *
 * Base URL: https://digitalcertify.tech/v1/api
 * Authentication: Header "x-api-key: dpk_YOUR_API_KEY"
 *
 * NOTE: Credentials are read directly from environment variables.
 * Never hard-code, log, or expose the real API key in source code or responses.
 */

const getBaseUrl = () => {
  if (process.env.DIGIPAY_BASE_URL && process.env.DIGIPAY_BASE_URL.trim() !== '') {
    return process.env.DIGIPAY_BASE_URL.trim().replace(/\/+$/, '');
  }
  return 'https://digitalcertify.tech/v1/api';
};

const getApiKey = () => {
  return (process.env.DIGIPAY_API_KEY || '').trim();
};

const isConfigured = () => {
  const key = getApiKey();
  return Boolean(key && key.length > 0);
};

/**
 * Normalizes phone numbers to standard Cameroon format: 237XXXXXXXXX (digits only).
 * E.g., "+237 671 234 567" -> "237671234567"
 * E.g., "671234567" -> "237671234567"
 */
const formatPhone = (phone) => {
  if (!phone) return '';
  const digits = phone.toString().replace(/\D/g, '');
  if (digits.startsWith('237') && digits.length === 12) return digits;
  if (digits.length === 9) return `237${digits}`;
  return digits;
};

/**
 * Initiates a Mobile Money Pay-in request via DigiPay API.
 * The customer receives a push notification on their phone to approve the transaction.
 *
 * Endpoint: POST /payments/initiate
 *
 * @param {Object} params
 * @param {Object} params.order - Order Sequelize model or object with id, totalAmount
 * @param {Object} [params.customer] - Customer object with name, email, phone
 * @param {string} [params.phone] - Optional phone override for Mobile Money push
 * @param {string} [params.paymentMethod] - Selected channel (e.g., 'MTN Mobile Money', 'Orange Money')
 * @param {string} [params.webhookUrl] - Optional webhook callback URL
 * @returns {Promise<Object>} Session / transaction details
 */
const createPaymentSession = async ({ order, customer, phone, paymentMethod, webhookUrl }) => {
  const apiKey = getApiKey();
  const baseUrl = getBaseUrl();

  if (!isConfigured()) {
    console.warn('[DigiPay] Warning: DIGIPAY_API_KEY is not configured in .env. Payment request will not reach external gateway.');
    return {
      success: false,
      configured: false,
      message: 'DigiPay API key is not configured in environment variables. Please add DIGIPAY_API_KEY to .env.',
      paymentUrl: null,
      paymentReference: `LOCAL-${order.id}`
    };
  }

  const customerPhone = formatPhone(phone || customer?.phone);

  const payload = {
    amount: Math.round(parseFloat(order.totalAmount)),
    customerPhone: customerPhone || '237699000000',
    customerEmail: customer?.email || 'customer@novara.app',
    metadata: {
      orderId: order.id,
      paymentMethod: paymentMethod || 'MTN Mobile Money',
      customerName: customer?.name || 'Novara Customer'
    }
  };

  const effectiveWebhookUrl = webhookUrl ||
    process.env.DIGIPAY_WEBHOOK_URL ||
    (process.env.APP_BASE_URL ? `${process.env.APP_BASE_URL.replace(/\/+$/, '')}/api/orders/webhook/digipay` : undefined) ||
    (process.env.RAILWAY_PUBLIC_DOMAIN ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/api/orders/webhook/digipay` : undefined);

  if (effectiveWebhookUrl) {
    payload.webhookUrl = effectiveWebhookUrl;
  }

  try {
    const endpoint = `${baseUrl}/payments/initiate`;
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errMsg = data.message || data.error || `DigiPay API error (HTTP ${response.status})`;
      console.error(`[DigiPay] Failed to initiate pay-in: ${errMsg}`);
      return {
        success: false,
        configured: true,
        message: errMsg,
        paymentUrl: null,
        paymentReference: null,
        error: data
      };
    }

    // DigiPay initiate response shape: { success: true, transactionId: "TXN_...", amount: 5000, status: "pending" }
    const transactionId = data.transactionId || (data.data && data.data.transactionId) || data.id || null;
    const paymentUrl = data.paymentUrl || (data.data && data.data.paymentUrl) || null;

    return {
      success: true,
      configured: true,
      paymentReference: transactionId,
      paymentUrl,
      customerPhone,
      status: data.status || 'pending',
      raw: data
    };
  } catch (error) {
    console.error('[DigiPay] Network error initiating pay-in with DigiPay:', error.message);
    return {
      success: false,
      configured: true,
      message: `Failed to connect to DigiPay gateway: ${error.message}`,
      paymentUrl: null,
      paymentReference: null
    };
  }
};

/**
 * Checks transaction status with DigiPay API.
 * An order should only be marked 'paid' when confirmed by the gateway status.
 *
 * Endpoint: GET /payments/transactions/{transactionId}
 *
 * @param {string} transactionId - The DigiPay transaction ID
 * @returns {Promise<Object>} Verification result with normalized status
 */
const verifyPaymentStatus = async (transactionId) => {
  const apiKey = getApiKey();
  const baseUrl = getBaseUrl();

  if (!isConfigured()) {
    return {
      isPaid: false,
      status: 'pending',
      configured: false,
      message: 'DigiPay API key is not configured.'
    };
  }

  if (!transactionId) {
    return {
      isPaid: false,
      status: 'failed',
      message: 'No transaction ID provided for verification.'
    };
  }

  try {
    const endpoint = `${baseUrl}/payments/transactions/${encodeURIComponent(transactionId)}`;
    const response = await fetch(endpoint, {
      method: 'GET',
      headers: {
        'x-api-key': apiKey
      }
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error(`[DigiPay] Transaction check failed with HTTP ${response.status}`);
      return {
        isPaid: false,
        status: 'pending',
        message: data.message || `DigiPay status check returned HTTP ${response.status}`,
        raw: data
      };
    }

    const payload = data.data || data;
    const statusStr = (payload.status || '').toLowerCase();

    // In DigiPay: "success", "pending", "failed", "refunded"
    const isPaid = statusStr === 'success' || statusStr === 'completed' || statusStr === 'approved';

    let normalizedStatus = 'pending';
    if (isPaid) {
      normalizedStatus = 'paid';
    } else if (statusStr === 'failed' || statusStr === 'declined' || statusStr === 'rejected') {
      normalizedStatus = 'failed';
    } else if (statusStr === 'refunded' || statusStr === 'cancelled') {
      normalizedStatus = 'cancelled';
    }

    return {
      isPaid,
      status: normalizedStatus,
      rawStatus: statusStr,
      transactionId: payload.transactionId || transactionId,
      amount: payload.amount,
      raw: payload
    };
  } catch (error) {
    console.error('[DigiPay] Error querying transaction status:', error.message);
    return {
      isPaid: false,
      status: 'pending',
      message: `Failed to query DigiPay status: ${error.message}`
    };
  }
};

/**
 * Validates and processes an incoming DigiPay webhook notification.
 *
 * Official DigiPay Webhook format:
 * - Success: { "event": "payment.success", "data": { "transactionId": "TXN_...", "status": "success", "metadata": { "orderId": "..." } } }
 * - Failed: { "event": "payment.failed", "data": { "transactionId": "TXN_...", "status": "failed", "reason": "..." } }
 *
 * @param {Object} body - Webhook request payload
 * @returns {Object} Normalized webhook data
 */
const parseWebhookPayload = (body) => {
  if (!body || typeof body !== 'object') {
    return { valid: false, message: 'Invalid webhook payload' };
  }

  const event = body.event || '';
  const data = body.data || body;
  const metadata = data.metadata || {};

  const orderId = metadata.orderId || data.merchantOrderId || data.orderId || body.orderId;
  const transactionId = data.transactionId || data.id || body.transactionId;
  const statusStr = (data.status || '').toLowerCase();

  const isPaid = event === 'payment.success' || statusStr === 'success' || statusStr === 'completed' || statusStr === 'approved';

  let normalizedStatus = 'pending';
  if (isPaid) {
    normalizedStatus = 'paid';
  } else if (event === 'payment.failed' || statusStr === 'failed' || statusStr === 'declined') {
    normalizedStatus = 'failed';
  } else if (statusStr === 'refunded' || statusStr === 'cancelled') {
    normalizedStatus = 'cancelled';
  }

  return {
    valid: Boolean(orderId || transactionId),
    orderId,
    transactionId,
    amount: data.amount,
    isPaid,
    status: normalizedStatus,
    event,
    raw: body
  };
};

module.exports = {
  isConfigured,
  formatPhone,
  createPaymentSession,
  verifyPaymentStatus,
  parseWebhookPayload,
  getBaseUrl
};
