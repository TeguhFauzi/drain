const prisma = require('../_lib/prisma');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  if (req.method !== 'GET') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  const { slug } = req.query;

  if (!slug) {
    return sendError(res, 'Game slug is required', 400);
  }

  try {
    const game = await prisma.game.findFirst({
      where: {
        slug: slug.toString(),
        isActive: true,
      },
      include: {
        products: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          select: {
            id: true,
            name: true,
            description: true,
            price: true,
            sellPrice: true,
            category: true,
            sortOrder: true,
          },
        },
      },
    });

    if (!game) {
      return sendError(res, 'Game not found', 404);
    }

    return sendSuccess(res, game);
  } catch (error) {
    console.error('Fetch game detail error:', error);
    return sendError(res, 'Failed to fetch game details', 500);
  }
};
