/**
 * SecureMart - Authentication controller.
 * register | login | logout | me
 *
 * Security properties:
 *  - passwords stored only as bcrypt hashes (cost 10)
 *  - login returns generic error (no user enumeration)
 *  - JWT carries only safe claims; password never leaves the server
 *  - success/failure recorded in audit_logs
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');
const { audit } = require('../utils/audit');
const { isNonEmptyString, isValidEmail, isValidPassword } = require('../utils/validate');

const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';
const BCRYPT_ROUNDS = 10;

function signToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      name: user.name,
      email: user.email,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

/** POST /api/auth/register */
async function register(req, res, next) {
  try {
    const { name, email, password, passwordConfirm } = req.body || {};

    if (!isNonEmptyString(name) || name.trim().length > 80) {
      return res.status(400).json({ error: 'Name is required (max 80 chars).' });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'A valid email address is required.' });
    }
    if (!isValidPassword(password)) {
      return res.status(400).json({
        error: 'Password must be 8+ characters and include a letter and a digit.',
      });
    }
    if (password !== passwordConfirm) {
      return res.status(400).json({ error: 'Passwords do not match.' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

    // Role is ALWAYS customer on self-registration - never trust a client role.
    const [result] = await pool.execute(
      `INSERT INTO users (name, email, password_hash, role_id)
       VALUES (?, ?, ?, (SELECT id FROM roles WHERE name = 'customer'))`,
      [name.trim(), cleanEmail, hash]
    );

    const [rows] = await pool.execute(
      `SELECT u.id, u.name, u.email, r.name AS role
         FROM users u JOIN roles r ON r.id = u.role_id
        WHERE u.id = ?`,
      [result.insertId]
    );
    const user = rows[0];

    await audit({
      userId: user.id,
      eventType: 'REGISTER',
      description: 'New account self-registered',
      req,
    });

    return res.status(201).json({
      message: 'Account created successfully.',
      token: signToken(user),
      user,
    });
  } catch (err) {
    // Unique constraint violation -> friendly message instead of SQL text.
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'An account with that email already exists.' });
    }
    return next(err);
  }
}

/** POST /api/auth/login */
async function login(req, res, next) {
  try {
    const { email, password } = req.body || {};

    if (!isValidEmail(email) || typeof password !== 'string' || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const [rows] = await pool.execute(
      `SELECT u.id, u.name, u.email, u.password_hash, u.is_active, r.name AS role
         FROM users u JOIN roles r ON r.id = u.role_id
        WHERE u.email = ?`,
      [cleanEmail]
    );
    const user = rows[0];

    // Always run a comparison so timing does not reveal whether the email exists.
    const hash = user ? user.password_hash : '$2b$10$invalidinvalidinvalidinvalidinvalidinvalidinvalidinva';
    const ok = await bcrypt.compare(password, hash);

    if (!user || !ok || !user.is_active) {
      await audit({
        userId: user ? user.id : null,
        eventType: 'LOGIN_FAILED',
        description: 'Failed sign-in attempt (bad credentials or inactive account)',
        req,
      });
      // Single generic message prevents account enumeration.
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const safeUser = { id: user.id, name: user.name, email: user.email, role: user.role };

    await audit({
      userId: user.id,
      eventType: 'LOGIN_SUCCESS',
      description: `${user.role} signed in`,
      req,
    });

    return res.json({ message: 'Signed in.', token: signToken(safeUser), user: safeUser });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/auth/logout - stateless JWT: client discards the token. */
async function logout(req, res) {
  if (req.user) {
    await audit({
      userId: req.user.id,
      eventType: 'LOGOUT',
      description: 'User signed out',
      req,
    });
  }
  return res.json({ message: 'Signed out.' });
}

/** GET /api/auth/me */
async function me(req, res, next) {
  try {
    const [rows] = await pool.execute(
      `SELECT u.id, u.name, u.email, u.phone, u.address, r.name AS role, u.created_at
         FROM users u JOIN roles r ON r.id = u.role_id
        WHERE u.id = ?`,
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'User not found.' });
    return res.json({ user: rows[0] });
  } catch (err) {
    return next(err);
  }
}

module.exports = { register, login, logout, me };
