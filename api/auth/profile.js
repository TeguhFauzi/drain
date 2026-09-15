const prisma = require('../_lib/prisma');
const { getAuthUser } = require('../_lib/auth');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  const authUser = getAuthUser(req);
  if (!authUser) {
    return sendError(res, 'Unauthorized access', 401);
  }

  try {
    if (req.method === 'GET') {
      const user = await prisma.user.findUnique({
        where: { id: authUser.userId },
        select: {
          id: true,
          email: true,
          name: true,
          phone: true,
          role: true,
          balance: true,
          avatarUrl: true,
          createdAt: true,
        },
      });

      if (!user) {
        return sendError(res, 'User not found', 404);
      }

      return sendSuccess(res, user);
    }

    if (req.method === 'PUT') {
      const { name, phone, avatarUrl } = req.body || {};

      const updatedUser = await prisma.user.update({
        where: { id: authUser.userId },
        data: {
          ...(name && { name }),
          ...(phone && { phone }),
          ...(avatarUrl && { avatarUrl }),
        },
        select: {
          id: true,
          email: true,
          name: true,
          phone: true,
          role: true,
          balance: true,
          avatarUrl: true,
          createdAt: true,
        },
      });

      return sendSuccess(res, updatedUser, 'Profile updated successfully');
    }

    return sendError(res, 'Method Not Allowed', 405);
  } catch (error) {
    console.error('Profile error:', error);
    return sendError(res, 'Failed to process profile request', 500);
  }
};
