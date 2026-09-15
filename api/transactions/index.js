const prisma = require('../_lib/prisma');
const { getAuthUser } = require('../_lib/auth');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

function generateInvoiceId() {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const randomStr = Math.floor(1000 + Math.random() * 9000);
  return `DRS-${dateStr}-${randomStr}`;
}

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  const authUser = getAuthUser(req);

  try {
    if (req.method === 'POST') {
      const {
        productId,
        gameUserId,
        gameServerId,
        paymentMethod = 'QRIS',
        email,
        phone,
        notes,
      } = req.body || {};

      if (!productId || !gameUserId) {
        return sendError(res, 'productId and gameUserId are required', 400);
      }

      const product = await prisma.product.findUnique({
        where: { id: productId },
        include: { game: true },
      });

      if (!product || !product.isActive) {
        return sendError(res, 'Selected product is not available', 400);
      }

      const invoiceId = generateInvoiceId();
      const amount = product.sellPrice;

      // Simulated payment URL (Midtrans sandbox integration point)
      const paymentUrl = `https://checkout.sandbox.midtrans.com/v2/snap/v4/popup?token=demo-${Date.now()}`;

      const transaction = await prisma.transaction.create({
        data: {
          invoiceId,
          userId: authUser ? authUser.userId : null,
          productId: product.id,
          gameUserId,
          gameServerId: gameServerId || null,
          amount,
          status: 'pending',
          paymentMethod,
          paymentUrl,
          email: email || (authUser ? authUser.email : null),
          phone: phone || null,
          notes: notes || null,
        },
        include: {
          product: {
            select: {
              name: true,
              sellPrice: true,
              game: {
                select: {
                  name: true,
                  slug: true,
                  imageUrl: true,
                },
              },
            },
          },
        },
      });

      return sendSuccess(res, transaction, 'Transaction created successfully', 201);
    }

    if (req.method === 'GET') {
      if (!authUser) {
        return sendError(res, 'Authentication required to list transactions', 401);
      }

      const transactions = await prisma.transaction.findMany({
        where: { userId: authUser.userId },
        orderBy: { createdAt: 'desc' },
        include: {
          product: {
            select: {
              name: true,
              game: {
                select: {
                  name: true,
                  imageUrl: true,
                },
              },
            },
          },
        },
      });

      return sendSuccess(res, transactions);
    }

    return sendError(res, 'Method Not Allowed', 405);
  } catch (error) {
    console.error('Transaction API error:', error);
    return sendError(res, 'Failed to process transaction request', 500);
  }
};
