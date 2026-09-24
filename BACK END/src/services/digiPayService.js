/**
 * DigiPay Payment Gateway Service for NOVARA
 * Handles checkout session initialization, verification, and webhook notifications.
 *
 * NOTE: Credentials are read directly from environment variables.
 * Never hard-code, log, or expose the real API key in source code or responses.
 */

const getBaseUrl = () => {
  if (process.env.DIGIPAY_BASE_URL && process.env.DIGIPAY_BASE_URL.trim() !== '') {
    return process.env.DIGIPAY_BASE_URL.trim().replace(/\/+$/, '');
  }
  const env = (process.env.DIGIPAY_ENV || 'staging').toLowerCase();
  return env === 'production'
    ? 'https://api.digetpay.com/v1'
    : 'https://fin-api.digetpay.com/v1';
};

const getApiKey = () => {
  return (process.env.DIGIPAY_API_KEY || '').trim();
};

const isConfigured = () => {
  const key = getApiKey();
  return Boolean(key && key.length > 0);
};

/**
 * Creates a DigiPay checkout payment session.
 *
 * @param {Object} params
 * @param {Object} params.order - Order Sequelize model or object with id, totalAmount, currency
 * @param {Object} [params.customer] - Customer object with name, email, phone
 * @param {string} [params.paymentMethod] - Selected channel (e.g., 'MTN Mobile Money', 'Orange Money')
 * @param {string} [params.successUrl] - Client redirect URL on success
 * @param {string} [params.failureUrl] - Client redirect URL on failure
 * @returns {Promise<Object>} Session details containing paymentUrl and paymentReference
 */
const createPaymentSession = async ({ order, customer, paymentMethod, successUrl, failureUrl }) => {
  const apiKey = getApiKey();
  const baseUrl = getBaseUrl();

  if (!isConfigured()) {
    console.warn('[DigiPay] Warning: DIGIPAY_API_KEY is not configured in .env. Payment session will not reach external gateway.');
    return {
      success: false,
      configured: false,
      message: 'DigiPay API key is not configured in environment variables. Please add DIGIPAY_API_KEY to .env.',
      paymentUrl: null,
      paymentReference: `LOCAL-${order.id}`
    };
  }

  // Normalize currency: FCFA -> XAF for standard banking gateways
  let currencyCode = (order.currency || 'XAF').toUpperCase();
  if (currencyCode === 'FCFA') currencyCode = 'XAF';

  const payload = {
    merchantOrderId: order.id,
    amount: parseFloat(order.totalAmount),
    currency: currencyCode,
    paymentMethod: paymentMethod || 'MTN Mobile Money',
    customerName: customer?.name || 'Novara Customer',
    customerEmail: customer?.email || 'customer@novara.app',
    customerPhone: customer?.phone || '',
    successUrl: successUrl || '',
    failureUrl: failureUrl || ''
  };

  try {
    // Attempt standard initiate endpoint (spelled 'intiate' or 'initiate' per DigiPay docs)
    let endpoint = `${baseUrl}/payment/checkout/intiate`;
    let response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey
      },
      body: JSON.stringify(payload)
    });

    // If 404, fallback to initiate spelling
    if (response.status === 404) {
      endpoint = `${baseUrl}/payment/checkout/initiate`;
      response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey
        },
        body: JSON.stringify(payload)
      });
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errMsg = data.message || data.error || `DigiPay API error (HTTP ${response.status})`;
      console.error(`[DigiPay] Failed to initiate session: ${errMsg}`);
      return {
        success: false,
        configured: true,
        message: errMsg,
        paymentUrl: null,
        paymentReference: null,
        error: data
      };
    }

    // DigiPay responses typically provide: { id, redirectUrl } or { data: { id, redirectUrl } }
    const sessionData = data.data || data;
    const paymentReference = sessionData.id || sessionData.transactionId || sessionData.reference || null;
    const paymentUrl = sessionData.redirectUrl || sessionData.paymentUrl || sessionData.checkoutUrl || null;

    return {
      success: true,
      configured: true,
      paymentReference,
      paymentUrl,
      raw: sessionData
    };
  } catch (error) {
    console.error('[DigiPay] Network or execution error initiating checkout session:', error.message);
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
 * Verifies payment status with DigiPay API.
 * An order should only be marked 'paid' when confirmed by the gateway status.
 *
 * @param {string} paymentReference - The DigiPay session/transaction ID
 * @returns {Promise<Object>} Verification result with normalized status
 */
const verifyPaymentStatus = async (paymentReference) => {
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

  if (!paymentReference) {
    return {
      isPaid: false,
      status: 'failed',
      message: 'No payment reference provided for verification.'
    };
  }

  try {
    const endpoint = `${baseUrl}/payment/checkout/status?id=${encodeURIComponent(paymentReference)}`;
    const response = await fetch(endpoint, {
      method: 'GET',
      headers: {
        'x-api-key': apiKey
      }
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error(`[DigiPay] Verification check failed with HTTP ${response.status}`);
      return {
        isPaid: false,
        status: 'pending',
        message: data.message || `DigiPay status check returned HTTP ${response.status}`,
        raw: data
      };
    }

    const payload = data.data || data;
    const txStatus = (payload.transactionStatus || payload.status || '').toUpperCase();
    const payStatus = (payload.paymentStatus || '').toUpperCase();

    // Positive verification according to DigiPay spec:
    // transactionStatus === 'SUCCESS' && paymentStatus === 'APPROVED'
    const isPaid = (txStatus === 'SUCCESS' && (payStatus === 'APPROVED' || !payload.paymentStatus)) ||
                   payStatus === 'APPROVED' ||
                   txStatus === 'COMPLETED' ||
                   txStatus === 'PAID';

    let normalizedStatus = 'pending';
    if (isPaid) {
      normalizedStatus = 'paid';
    } else if (txStatus === 'FAILED' || txStatus === 'REJECTED' || payStatus === 'DECLINED' || payStatus === 'FAILED') {
      normalizedStatus = 'failed';
    } else if (txStatus === 'CANCELLED' || txStatus === 'CANCELED') {
      normalizedStatus = 'cancelled';
    }

    return {
      isPaid,
      status: normalizedStatus,
      transactionStatus: txStatus,
      paymentStatus: payStatus,
      raw: payload
    };
  } catch (error) {
    console.error('[DigiPay] Error querying payment status:', error.message);
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
 * @param {Object} body - Webhook request payload
 * @returns {Object} Normalized webhook data
 */
const parseWebhookPayload = (body) => {
  if (!body || typeof body !== 'object') {
    return { valid: false, message: 'Invalid webhook payload' };
  }

  const orderId = body.merchantOrderId || body.orderId || body.reference;
  const transactionId = body.transactionId || body.id;
  const statusStr = (body.status || body.transactionStatus || '').toUpperCase();
  const paymentStatus = (body.paymentStatus || '').toUpperCase();

  const isPaid = (statusStr === 'SUCCESS' && (paymentStatus === 'APPROVED' || !paymentStatus)) ||
                 paymentStatus === 'APPROVED' ||
                 statusStr === 'COMPLETED' ||
                 statusStr === 'PAID';

  let normalizedStatus = 'pending';
  if (isPaid) {
    normalizedStatus = 'paid';
  } else if (statusStr === 'FAILED' || statusStr === 'REJECTED' || paymentStatus === 'DECLINED' || paymentStatus === 'FAILED') {
    normalizedStatus = 'failed';
  } else if (statusStr === 'CANCELLED' || statusStr === 'CANCELED') {
    normalizedStatus = 'cancelled';
  }

  return {
    valid: Boolean(orderId),
    orderId,
    transactionId,
    amount: body.amount,
    currencyCode: body.currencyCode || body.currency,
    isPaid,
    status: normalizedStatus,
    raw: body
  };
};

module.exports = {
  isConfigured,
  createPaymentSession,
  verifyPaymentStatus,
  parseWebhookPayload,
  getBaseUrl
};
