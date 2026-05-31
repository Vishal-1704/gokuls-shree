const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const runMigration = async () => {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('❌ DATABASE_URL is not set in backend/.env. Cannot run migration automatically.');
    console.log('👉 Please copy the contents of "backend/migrations/003_super_admin_permissions.sql" and run it in the Supabase SQL Editor.');
    process.exit(1);
  }

  console.log('🔄 Connecting to PostgreSQL database to apply migration...');
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('📦 Connected successfully. Reading SQL file...');
    
    const sqlPath = path.join(__dirname, '003_super_admin_permissions.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('🚀 Running 003_super_admin_permissions.sql...');
    await client.query(sql);
    console.log('🎉 Migration applied successfully!');
  } catch (err) {
    console.error('❌ Failed to run migration:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
};

runMigration();
