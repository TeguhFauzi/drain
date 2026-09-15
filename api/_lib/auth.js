const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'drianstore_super_secret_jwt_key_2026';

function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
}

function getAuthUser(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.split(' ')[1];
  return verifyToken(token);
}

module.exports = {
  JWT_SECRET,
  generateToken,
  verifyToken,
  getAuthUser,
};
