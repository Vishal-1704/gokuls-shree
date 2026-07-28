const db = require('./database');

const updateTables = async () => {
    const queries = [
        // Add Father/Mother Name and basic info to students
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS father_name VARCHAR(255)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS mother_name VARCHAR(255)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS dob DATE`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS gender VARCHAR(20)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS category VARCHAR(50)`,

        // Add Address info
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS address TEXT`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS district VARCHAR(100)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS state VARCHAR(100)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS pincode VARCHAR(20)`,

        // Add Academic info
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS batch VARCHAR(100)`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS doj DATE`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS fee_total DECIMAL(10,2) DEFAULT 0.00`,
        `ALTER TABLE students ADD COLUMN IF NOT EXISTS fee_paid DECIMAL(10,2) DEFAULT 0.00`
    ];

    console.log('🔄 Running V2 database migrations...');

    for (const query of queries) {
        try {
            await db.query(query);
            console.log('✅ Column added successfully');
        } catch (error) {
            console.error('❌ Migration error:', error.message);
        }
    }

    console.log('🎉 V2 Migration completed!');
    process.exit(0);
};

updateTables();
