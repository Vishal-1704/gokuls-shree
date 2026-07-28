const { Pool } = require('pg');
require('dotenv').config();

// Support both individual env vars and DATABASE_URL (for cloud hosting)
const getPoolConfig = () => {
  // If DATABASE_URL is set (Render, Neon, etc.), use it
  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false, // Required for Neon/Render
      },
      max: 10, // Lower for free tier
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    };
  }

  // Otherwise use individual env vars (local development)
  return {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  };
};

const pool = new Pool(getPoolConfig());

// Test connection
pool.on('connect', () => {
  console.log('📦 Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  // Don't exit in production, just log
  if (process.env.NODE_ENV !== 'production') {
    process.exit(-1);
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
  pool,
};
