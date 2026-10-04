/**
 * SecureMart - Lightweight input validation helpers.
 *
 * Provides reusable checks so every controller applies the same rules
 * (length limits, format checks) before data reaches SQL or the client.
 */

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function isValidEmail(v) {
  return typeof v === 'string' && v.length <= 160 && EMAIL_RE.test(v.trim());
}

/**
 * Password policy (laboratory rules, documented in README):
 *  - 8..72 characters
 *  - at least one letter and one digit
 */
function isValidPassword(v) {
  if (typeof v !== 'string' || v.length < 8 || v.length > 72) return false;
  return /[A-Za-z]/.test(v) && /\d/.test(v);
}

/** Coerce to a positive integer id, or null when invalid. */
function toId(v) {
  const n = Number(v);
  return Number.isInteger(n) && n > 0 ? n : null;
}

/** Clamp a cart/order quantity to a sane range. */
function toQty(v, fallback = 1) {
  const n = Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(Math.max(Math.trunc(n), 1), 999);
}

/** Basic money coercion for prices coming from client input. */
function toMoney(v, fallback = 0) {
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0) return fallback;
  return Math.round(n * 100) / 100;
}

module.exports = { isNonEmptyString, isValidEmail, isValidPassword, toId, toQty, toMoney };
