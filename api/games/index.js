const prisma = require('../_lib/prisma');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  if (req.method !== 'GET') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  try {
    const { category, search } = req.query || {};

    const where = {
      isActive: true,
      ...(category && { category }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { publisher: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const games = await prisma.game.findMany({
      where,
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        imageUrl: true,
        bannerUrl: true,
        category: true,
        publisher: true,
        sortOrder: true,
      },
    });

    return sendSuccess(res, games);
  } catch (error) {
    console.error('Fetch games error:', error);
    return sendError(res, 'Failed to fetch games', 500);
  }
};
