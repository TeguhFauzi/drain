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
      const { gameId } = req.query;
      const products = await prisma.product.findMany({
        where: gameId ? { gameId: gameId.toString() } : {},
        orderBy: { sortOrder: 'asc' },
        include: {
          game: { select: { id: true, name: true, slug: true } },
        },
      });
      return sendSuccess(res, products);
    }

    if (req.method === 'POST') {
      const {
        gameId,
        name,
        description,
        price,
        sellPrice,
        providerCode,
        category = 'topup',
        isActive = true,
        sortOrder = 0,
      } = req.body || {};

      if (!gameId || !name || price === undefined || sellPrice === undefined) {
        return sendError(res, 'gameId, name, price, and sellPrice are required', 400);
      }

      const product = await prisma.product.create({
        data: {
          gameId,
          name,
          description: description || null,
          price: parseFloat(price),
          sellPrice: parseFloat(sellPrice),
          providerCode: providerCode || null,
          category,
          isActive,
          sortOrder: parseInt(sortOrder) || 0,
        },
      });

      return sendSuccess(res, product, 'Product created successfully', 201);
    }

    if (req.method === 'PUT') {
      const {
        id,
        name,
        description,
        price,
        sellPrice,
        providerCode,
        category,
        isActive,
        sortOrder,
      } = req.body || {};

      if (!id) {
        return sendError(res, 'Product ID is required for update', 400);
      }

      const updatedProduct = await prisma.product.update({
        where: { id },
        data: {
          ...(name !== undefined && { name }),
          ...(description !== undefined && { description }),
          ...(price !== undefined && { price: parseFloat(price) }),
          ...(sellPrice !== undefined && { sellPrice: parseFloat(sellPrice) }),
          ...(providerCode !== undefined && { providerCode }),
          ...(category !== undefined && { category }),
          ...(isActive !== undefined && { isActive }),
          ...(sortOrder !== undefined && { sortOrder: parseInt(sortOrder) }),
        },
      });

      return sendSuccess(res, updatedProduct, 'Product updated successfully');
    }

    if (req.method === 'DELETE') {
      const { id } = req.query;

      if (!id) {
        return sendError(res, 'Product ID is required for deletion', 400);
      }

      await prisma.product.delete({
        where: { id: id.toString() },
      });

      return sendSuccess(res, null, 'Product deleted successfully');
    }

    return sendError(res, 'Method Not Allowed', 405);
  } catch (error) {
    console.error('Admin products API error:', error);
    return sendError(res, 'Failed to process product operation', 500);
  }
};
