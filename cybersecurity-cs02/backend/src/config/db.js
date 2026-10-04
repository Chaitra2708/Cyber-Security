/**
 * SecureMart - Database configuration & connection pool
 * Loads .env and exposes a shared mysql2 promise pool.
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

const config = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME || 'securemart_db',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
};

// Connection pool: reuses sockets, limits concurrency, survives dropped links.
const pool = mysql.createPool({
  ...config,
  waitForConnections: true,
  connectionLimit: 10,
  namedPlaceholders: false,
  // Do not leak internals in errors; the central error handler stays generic.
  debug: false,
});

/** Verify connectivity at boot so misconfiguration fails fast and clearly. */
async function verifyConnection() {
  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.query('SELECT 1 AS ok');
    return rows[0].ok === 1;
  } finally {
    conn.release();
  }
}

module.exports = { pool, config, verifyConnection };
