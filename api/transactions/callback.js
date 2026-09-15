const prisma = require('../_lib/prisma');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  if (req.method !== 'POST') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  try {
    const payload = req.body || {};
    const { order_id, transaction_status, fraud_status } = payload;

    const invoiceId = order_id || payload.invoiceId;

    if (!invoiceId) {
      return sendError(res, 'Invoice ID / order_id missing from callback', 400);
    }

    let newStatus = 'pending';

    if (transaction_status === 'capture' || transaction_status === 'settlement' || payload.status === 'completed') {
      newStatus = 'completed';
    } else if (transaction_status === 'deny' || transaction_status === 'cancel' || transaction_status === 'expire' || payload.status === 'failed') {
      newStatus = 'failed';
    } else if (transaction_status === 'pending') {
      newStatus = 'pending';
    }

    const transaction = await prisma.transaction.findUnique({
      where: { invoiceId },
    });

    if (!transaction) {
      return sendError(res, 'Transaction not found for callback', 404);
    }

    const updatedTransaction = await prisma.transaction.update({
      where: { invoiceId },
      data: {
        status: newStatus,
        ...(newStatus === 'completed' && { completedAt: new Date() }),
      },
    });

    // Log the callback payload
    await prisma.paymentLog.create({
      data: {
        transactionId: transaction.id,
        eventType: `midtrans.${transaction_status || payload.status || 'callback'}`,
        payload,
      },
    });

    return sendSuccess(res, updatedTransaction, 'Payment status updated successfully');
  } catch (error) {
    console.error('Payment callback error:', error);
    return sendError(res, 'Failed to process payment callback', 500);
  }
};
