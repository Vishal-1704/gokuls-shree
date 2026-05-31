const { Client } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const inspectRLS = async () => {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('❌ DATABASE_URL is not set in backend/.env');
    process.exit(1);
  }

  console.log(`Connecting to database to check RLS status...\n`);

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    const res = await client.query(`
      SELECT relname AS table_name, relrowsecurity AS rls_enabled
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relkind = 'r'
      ORDER BY table_name;
    `);

    console.log('Tables and RLS Status:');
    console.log('======================');
    res.rows.forEach(row => {
      console.log(`${row.table_name.padEnd(30)} | RLS Enabled: ${row.rls_enabled ? '✅ YES' : '❌ NO'}`);
    });

    console.log('\nExisting RLS Policies:');
    console.log('======================');
    const policiesRes = await client.query(`
      SELECT tablename, policyname, cmd, roles, qual, with_check
      FROM pg_policies
      WHERE schemaname = 'public'
      ORDER BY tablename, policyname;
    `);
    policiesRes.rows.forEach(row => {
      console.log(`Table: ${row.tablename.padEnd(25)} | Policy: ${row.policyname.padEnd(30)} | Cmd: ${row.cmd.padEnd(6)} | Roles: ${row.roles}`);
    });

    console.log('\nColumns of tables with RLS disabled:');
    console.log('====================================');
    for (const row of res.rows) {
      if (!row.rls_enabled) {
        const columnsRes = await client.query(`
          SELECT column_name, data_type 
          FROM information_schema.columns 
          WHERE table_schema = 'public' AND table_name = $1
          ORDER BY ordinal_position;
        `, [row.table_name]);
        const cols = columnsRes.rows.map(c => `${c.column_name} (${c.data_type})`).join(', ');
        console.log(`Table: ${row.table_name.padEnd(25)} | Columns: ${cols}`);
      }
    }

  } catch (err) {
    console.error('Error querying schema:', err.message);
  } finally {
    await client.end();
  }
};

inspectRLS();
