const prisma = require('../_lib/prisma');
const bcrypt = require('bcryptjs');
const { generateToken } = require('../_lib/auth');
const { handleOptions, sendSuccess, sendError } = require('../_lib/response');

module.exports = async function handler(req, res) {
  if (handleOptions(req, res)) return;

  if (req.method !== 'POST') {
    return sendError(res, 'Method Not Allowed', 405);
  }

  try {
    const { email, password, name, phone } = req.body || {};

    if (!email || !password || !name) {
      return sendError(res, 'Email, password, and name are required', 400);
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return sendError(res, 'Email is already registered', 400);
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
        phone: phone || null,
        role: 'user',
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        role: true,
        balance: true,
        createdAt: true,
      },
    });

    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    return sendSuccess(
      res,
      { user, token },
      'Registration successful',
      201
    );
  } catch (error) {
    console.error('Registration error:', error);
    return sendError(res, 'Failed to register user', 500);
  }
};
