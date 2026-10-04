/**
 * SecureMart - JWT authentication & role authorization middleware.
 *
 * authenticateToken : validates the Bearer token and attaches req.user.
 * requireRole(...)   : enforces RBAC AFTER authentication.
 * requireOwnership   : enforces object-level ownership checks.
 *
 * The backend is the authority for access control - the React router
 * protection is a usability feature only, never a security control.
 */
require('dotenv').config();
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'insecure_dev_secret_change_me';

function authenticateToken(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Authentication required.' });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    // Attach only the safe claims we need - never the whole raw token.
    req.user = {
      id: payload.sub,
      role: payload.role,
      name: payload.name,
      email: payload.email,
    };
    return next();
  } catch (err) {
    const reason =
      err.name === 'TokenExpiredError' ? 'Session expired.' : 'Invalid token.';
    return res.status(401).json({ error: reason });
  }
}

/** Guard a route to one or more roles: requireRole('admin') */
function requireRole(...allowed) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required.' });
    }
    if (!allowed.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions.' });
    }
    return next();
  };
}

/**
 * Object-level ownership: the acting user must own the resource, OR be admin.
 * ownerUserId is resolved by the caller from the database.
 */
function assertOwnership(ownerUserId, req, res) {
  if (!req.user) {
    res.status(401).json({ error: 'Authentication required.' });
    return false;
  }
  const isSelf = Number(ownerUserId) === Number(req.user.id);
  const isAdmin = req.user.role === 'admin';
  if (!isSelf && !isAdmin) {
    res.status(403).json({ error: 'You may only access your own resources.' });
    return false;
  }
  return true;
}

module.exports = { authenticateToken, requireRole, assertOwnership, JWT_SECRET };
