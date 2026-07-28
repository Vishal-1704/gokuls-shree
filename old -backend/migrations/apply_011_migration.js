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

  console.log('🔄 Connecting to PostgreSQL database to apply migration 011...');
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('📦 Connected successfully. Reading 011 SQL file...');
    
    const sqlPath = path.join(__dirname, '011_recreate_views_security_invoker.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('🚀 Running 011_recreate_views_security_invoker.sql...');
    await client.query(sql);
    console.log('🎉 Migration 011 applied successfully!');
  } catch (err) {
    console.error('❌ Failed to run migration:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
};

runMigration();
