require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

async function checkColumns() {
    try {
        console.log(`Checking columns in ${process.env.DB_NAME}...`);

        const tables = ['paper_sets', 'issued_documents', 'students'];

        for (const table of tables) {
            const res = await pool.query(`
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = '${table}'
                ORDER BY ordinal_position;
            `);

            console.log(`\n📊 Columns in '${table}':`);
            if (res.rows.length === 0) {
                console.log('   (Table not found)');
            } else {
                res.rows.forEach(r => {
                    console.log(`   - ${r.column_name} (${r.data_type})`);
                });
            }
        }

    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

checkColumns();
