/**
 * SecureMart - Centralized error handling & 404 fallback.
 *
 * Purpose: guarantee that unexpected failures never leak SQL text, stack
 * traces, connection strings, secrets or filesystem paths to the client.
 * Full diagnostics are written to the server log for the operator instead.
 */

/** 404 for unknown API routes (JSON, never an HTML stack page). */
function notFound(req, res) {
  res.status(404).json({ error: 'Resource not found.' });
}

/**
 * Final error middleware. Express identifies it by arities (err, req, res, next).
 * We intentionally return a generic message; details stay server-side.
 */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  // Log the full error for the operator (never sent to the client).
  // eslint-disable-next-line no-console
  console.error('[error]', {
    time: new Date().toISOString(),
    method: req.method,
    path: req.originalUrl,
    message: err.message,
    // Stack only in development logs, never in the HTTP response.
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });

  // Map a few well-known error types to safe status codes.
  let status = err.status || err.statusCode || 500;
  let message = 'Internal server error.';

  if (err.code === 'ER_DUP_ENTRY') {
    status = 409;
    message = 'That record already exists.';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'Malformed request body.';
  } else if (err.code === 'LIMIT_FILE_SIZE') {
    status = 413;
    message = 'Upload too large.';
  }

  res.status(status).json({ error: message });
}

module.exports = { notFound, errorHandler };
