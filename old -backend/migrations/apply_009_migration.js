const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const runMigration = async () => {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('❌ DATABASE_URL is not set in backend/.env. Cannot run migration automatically.');
    process.exit(1);
  }

  console.log('🔄 Connecting to PostgreSQL database to apply migration 009...');
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('📦 Connected successfully. Reading 009 SQL file...');
    
    const sqlPath = path.join(__dirname, '009_fix_rls_and_missing_tables.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('🚀 Running 009_fix_rls_and_missing_tables.sql...');
    await client.query(sql);
    console.log('🎉 Migration 009 applied successfully!');
  } catch (err) {
    console.error('❌ Failed to run migration:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
};

runMigration();
