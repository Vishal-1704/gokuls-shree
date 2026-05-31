const { Client } = require('pg');
require('dotenv').config();

const queryStudent = async () => {
  const connectionString = process.env.DATABASE_URL || 'postgresql://postgres.azxgjuzohwdemwbtxnxl:GokulShreeSchool2026!@aws-1-ap-south-1.pooler.supabase.com:5432/postgres';
  console.log(`Connecting to database to query students table...\n`);

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    const res = await client.query(`
      SELECT * FROM students LIMIT 1;
    `);

    console.log('Result Row keys:');
    if (res.rows.length > 0) {
      console.log(Object.keys(res.rows[0]));
      console.log('Row values:', res.rows[0]);
    } else {
      console.log('No rows found in students table');
    }
  } catch (err) {
    console.error('Error querying:', err.message);
  } finally {
    await client.end();
  }
};

queryStudent();
