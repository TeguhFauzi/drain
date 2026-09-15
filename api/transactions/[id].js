const prisma = require('../_lib/prisma');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  if (req.method !== 'GET') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  const { id } = req.query;

  if (!id) {
    return sendError(res, 'Transaction ID or Invoice ID is required', 400);
  }

  try {
    const transaction = await prisma.transaction.findFirst({
      where: {
        OR: [
          { id: id.toString() },
          { invoiceId: id.toString() },
        ],
      },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            sellPrice: true,
            game: {
              select: {
                id: true,
                name: true,
                slug: true,
                imageUrl: true,
                publisher: true,
              },
            },
          },
        },
      },
    });

    if (!transaction) {
      return sendError(res, 'Transaction not found', 404);
    }

    return sendSuccess(res, transaction);
  } catch (error) {
    console.error('Fetch transaction detail error:', error);
    return sendError(res, 'Failed to fetch transaction detail', 500);
  }
};
