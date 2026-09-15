const http = require('http');
const url = require('url');
require('dotenv').config();

/**
 * Native Node.js HTTP dev server wrapper for Vercel Serverless Functions.
 * Requires ZERO external packages (no express needed).
 */
function callVercelHandler(handlerPath, req, res, queryParams = {}) {
  const handler = require(handlerPath);

  req.query = { ...req.query, ...queryParams };

  let bodyData = '';
  req.on('data', chunk => {
    bodyData += chunk;
  });

  req.on('end', async () => {
    if (bodyData) {
      try {
        req.body = JSON.parse(bodyData);
      } catch (e) {
        req.body = bodyData;
      }
    }

    res.status = function (code) {
      res.statusCode = code;
      return res;
    };

    res.json = function (data) {
      if (!res.headersSent) {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        res.end(JSON.stringify(data));
      }
      return res;
    };

    if (req.method === 'OPTIONS') {
      res.writeHead(200, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
      return res.end();
    }

    try {
      await handler(req, res);
    } catch (err) {
      console.error(`Error executing ${handlerPath}:`, err);
      if (!res.writableEnded) {
        res.status(500).json({ success: false, message: err.message || 'Internal Server Error' });
      }
    }
  });
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  req.query = parsedUrl.query || {};

  // Auth Routes
  if (pathname === '/api/auth/register') return callVercelHandler('./api/auth/register.js', req, res);
  if (pathname === '/api/auth/login') return callVercelHandler('./api/auth/login.js', req, res);
  if (pathname === '/api/auth/profile') return callVercelHandler('./api/auth/profile.js', req, res);

  // Game Routes
  if (pathname === '/api/games') return callVercelHandler('./api/games/index.js', req, res);
  if (pathname.startsWith('/api/games/')) {
    const slug = pathname.replace('/api/games/', '');
    return callVercelHandler('./api/games/[slug].js', req, res, { slug });
  }

  // Transaction Routes
  if (pathname === '/api/transactions/callback') return callVercelHandler('./api/transactions/callback.js', req, res);
  if (pathname === '/api/transactions') return callVercelHandler('./api/transactions/index.js', req, res);
  if (pathname.startsWith('/api/transactions/')) {
    const id = pathname.replace('/api/transactions/', '');
    return callVercelHandler('./api/transactions/[id].js', req, res, { id });
  }

  // Admin Routes
  if (pathname === '/api/admin/dashboard') return callVercelHandler('./api/admin/dashboard.js', req, res);
  if (pathname === '/api/admin/games') return callVercelHandler('./api/admin/games.js', req, res);
  if (pathname === '/api/admin/products') return callVercelHandler('./api/admin/products.js', req, res);
  if (pathname === '/api/admin/transactions') return callVercelHandler('./api/admin/transactions.js', req, res);

  // Fallback Root Response
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <!DOCTYPE html>
    <html>
    <head><title>DrianStore API Server</title></head>
    <body style="font-family: sans-serif; background: #0b0f19; color: #fff; text-align: center; padding: 50px;">
      <h1 style="color: #00d2ff;">⚡ DrianStore Local API Server Active</h1>
      <p>Local API is running on <code style="color: #ffb800;">http://localhost:3000/api</code></p>
      <p style="color: #94a3b8;">Run Flutter app: <code>cd frontend && flutter run -d chrome</code></p>
    </body>
    </html>
  `);
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log('====================================================');
  console.log(`🚀 DrianStore Local API Server running on: http://localhost:${PORT}`);
  console.log(`📡 API Base URL: http://localhost:${PORT}/api`);
  console.log('====================================================\n');
});
