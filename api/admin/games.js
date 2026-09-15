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
      const games = await prisma.game.findMany({
        orderBy: { sortOrder: 'asc' },
        include: {
          _count: { select: { products: true } },
        },
      });
      return sendSuccess(res, games);
    }

    if (req.method === 'POST') {
      const {
        name,
        slug,
        description,
        imageUrl,
        bannerUrl,
        publisher,
        inputLabel,
        inputPlaceholder,
        inputLabel2,
        inputPlaceholder2,
        isActive = true,
        sortOrder = 0,
      } = req.body || {};

      if (!name || !slug) {
        return sendError(res, 'Name and slug are required', 400);
      }

      const game = await prisma.game.create({
        data: {
          name,
          slug,
          description: description || null,
          imageUrl: imageUrl || null,
          bannerUrl: bannerUrl || null,
          publisher: publisher || null,
          inputLabel: inputLabel || 'User ID',
          inputPlaceholder: inputPlaceholder || 'Masukkan User ID',
          inputLabel2: inputLabel2 || null,
          inputPlaceholder2: inputPlaceholder2 || null,
          isActive,
          sortOrder: parseInt(sortOrder) || 0,
        },
      });

      return sendSuccess(res, game, 'Game created successfully', 201);
    }

    if (req.method === 'PUT') {
      const {
        id,
        name,
        slug,
        description,
        imageUrl,
        bannerUrl,
        publisher,
        inputLabel,
        inputPlaceholder,
        inputLabel2,
        inputPlaceholder2,
        isActive,
        sortOrder,
      } = req.body || {};

      if (!id) {
        return sendError(res, 'Game ID is required for update', 400);
      }

      const updatedGame = await prisma.game.update({
        where: { id },
        data: {
          ...(name !== undefined && { name }),
          ...(slug !== undefined && { slug }),
          ...(description !== undefined && { description }),
          ...(imageUrl !== undefined && { imageUrl }),
          ...(bannerUrl !== undefined && { bannerUrl }),
          ...(publisher !== undefined && { publisher }),
          ...(inputLabel !== undefined && { inputLabel }),
          ...(inputPlaceholder !== undefined && { inputPlaceholder }),
          ...(inputLabel2 !== undefined && { inputLabel2 }),
          ...(inputPlaceholder2 !== undefined && { inputPlaceholder2 }),
          ...(isActive !== undefined && { isActive }),
          ...(sortOrder !== undefined && { sortOrder: parseInt(sortOrder) }),
        },
      });

      return sendSuccess(res, updatedGame, 'Game updated successfully');
    }

    if (req.method === 'DELETE') {
      const { id } = req.query;

      if (!id) {
        return sendError(res, 'Game ID is required for deletion', 400);
      }

      await prisma.game.delete({
        where: { id: id.toString() },
      });

      return sendSuccess(res, null, 'Game deleted successfully');
    }

    return sendError(res, 'Method Not Allowed', 405);
  } catch (error) {
    console.error('Admin games API error:', error);
    return sendError(res, 'Failed to process game operation', 500);
  }
};
