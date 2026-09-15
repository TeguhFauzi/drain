const prisma = require('../_lib/prisma');
const { getAuthUser } = require('../_lib/auth');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  const authUser = getAuthUser(req);
  if (!authUser || authUser.role !== 'admin') {
    return sendError(res, 'Access denied. Admin rights required.', 403);
  }

  try {
    if (req.method === 'GET') {
      const { status, search } = req.query || {};

      const where = {
        ...(status && { status: status.toString() }),
        ...(search && {
          OR: [
            { invoiceId: { contains: search, mode: 'insensitive' } },
            { gameUserId: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
          ],
        }),
      };

      const transactions = await prisma.transaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        include: {
          product: {
            select: {
              name: true,
              game: { select: { name: true, imageUrl: true } },
            },
          },
          user: { select: { name: true, email: true } },
        },
      });

      return sendSuccess(res, transactions);
    }

    if (req.method === 'PUT') {
      const { id, status, notes } = req.body || {};

      if (!id || !status) {
        return sendError(res, 'Transaction ID and status are required', 400);
      }

      const updatedTransaction = await prisma.transaction.update({
        where: { id },
        data: {
          status,
          ...(notes !== undefined && { notes }),
          ...(status === 'completed' && { completedAt: new Date() }),
        },
      });

      return sendSuccess(res, updatedTransaction, `Transaction status updated to ${status}`);
    }

    return sendError(res, 'Method Not Allowed', 405);
  } catch (error) {
    console.error('Admin transactions API error:', error);
    return sendError(res, 'Failed to process admin transaction operation', 500);
  }
};
