/**
 * SecureMart - Audit logging utility.
 *
 * Records security-relevant events into audit_logs.
 * SAFETY RULE: never store passwords, tokens, hashes or personal payloads -
 * only the event type, a short description, who acted, and request origin.
 */
const { pool } = require('../config/db');

/**
 * @param {object}  opts
 * @param {number}  [opts.userId]   acting user id (null for anonymous)
 * @param {string}  opts.eventType  e.g. LOGIN_SUCCESS, ORDER_CREATED
 * @param {string}  [opts.description] short human readable summary
 * @param {object}  [opts.req]      express request (for IP / user-agent)
 * @returns {Promise<void>} never throws - logging must not break a request
 */
async function audit({ userId = null, eventType, description = '', req = null }) {
  try {
    const ip = req ? (req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '') : '';
    const ua = req ? String(req.headers['user-agent'] || '').slice(0, 255) : '';
    await pool.execute(
      `INSERT INTO audit_logs (user_id, event_type, description, ip_address, user_agent)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, String(eventType).slice(0, 60), String(description).slice(0, 255), String(ip).slice(0, 45), ua]
    );
  } catch (err) {
    // Logging failures must never surface to the client.
    // eslint-disable-next-line no-console
    console.error('[audit] failed to record event:', err.message);
  }
}

module.exports = { audit };
