const prisma = require('../_lib/prisma');
const { getAuthUser } = require('../_lib/auth');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  const authUser = getAuthUser(req);
  if (!authUser || authUser.role !== 'admin') {
    return sendError(res, 'Access denied. Admin rights required.', 403);
  }

  if (req.method !== 'GET') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  try {
    const [
      totalUsers,
      totalGames,
      totalProducts,
      totalTransactions,
      completedTransactions,
      revenueResult,
      recentTransactions,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.game.count(),
      prisma.product.count(),
      prisma.transaction.count(),
      prisma.transaction.count({ where: { status: 'completed' } }),
      prisma.transaction.aggregate({
        where: { status: 'completed' },
        _sum: { amount: true },
      }),
      prisma.transaction.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          product: {
            select: {
              name: true,
              game: { select: { name: true } },
            },
          },
          user: { select: { name: true, email: true } },
        },
      }),
    ]);

    const totalRevenue = revenueResult._sum.amount ? parseFloat(revenueResult._sum.amount.toString()) : 0;

    return sendSuccess(res, {
      stats: {
        totalUsers,
        totalGames,
        totalProducts,
        totalTransactions,
        completedTransactions,
        totalRevenue,
      },
      recentTransactions,
    });
  } catch (error) {
    console.error('Admin dashboard error:', error);
    return sendError(res, 'Failed to load dashboard data', 500);
  }
};
