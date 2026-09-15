function cors(res) {
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );
}

function sendJson(res, statusCode, data) {
  cors(res);
  res.status(statusCode).json(data);
}

function sendSuccess(res, data, message = 'Success', statusCode = 200) {
  sendJson(res, statusCode, {
    success: true,
    message,
    data,
  });
}

function sendError(res, message = 'Internal Server Error', statusCode = 500, errors = null) {
  sendJson(res, statusCode, {
    success: false,
    message,
    ...(errors && { errors }),
  });
}

function handleOptions(req, res) {
  if (req.method === 'OPTIONS') {
    cors(res);
    res.status(200).end();
    return true;
  }
  return false;
}

module.exports = {
  cors,
  sendJson,
  sendSuccess,
  sendError,
  handleOptions,
};
