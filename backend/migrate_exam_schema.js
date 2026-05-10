require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function migrate() {
    console.log('🔄 Running Exam Module migration...');

    try {
        const sqlPath = path.join(__dirname, 'schema_exam_module.sql');
        if (!fs.existsSync(sqlPath)) {
            throw new Error(`SQL file not found at ${sqlPath}`);
        }
        const sql = fs.readFileSync(sqlPath, 'utf8');
        console.log(`📖 Read SQL file (${sql.length} bytes)`);

        await pool.query(sql);

        console.log('✅ Exam Module tables created successfully!');
    } catch (error) {
        console.error('❌ Migration failed:', error);
    } finally {
        await pool.end();
    }
}

migrate();
