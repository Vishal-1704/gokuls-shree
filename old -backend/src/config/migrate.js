const db = require('./database');

const createTables = async () => {
  const queries = [
    // Students table
    `CREATE TABLE IF NOT EXISTS students (
      id SERIAL PRIMARY KEY,
      registration_number VARCHAR(50) UNIQUE NOT NULL,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255),
      phone VARCHAR(20),
      password_hash VARCHAR(255) NOT NULL,
      course_id INTEGER,
      session_year VARCHAR(20),
      photo_url TEXT,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Courses table
    `CREATE TABLE IF NOT EXISTS courses (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      category VARCHAR(50) NOT NULL,
      duration VARCHAR(50),
      eligibility VARCHAR(255),
      description TEXT,
      image_url TEXT,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Results table
    `CREATE TABLE IF NOT EXISTS results (
      id SERIAL PRIMARY KEY,
      student_id INTEGER REFERENCES students(id),
      exam_name VARCHAR(255) NOT NULL,
      exam_date DATE,
      total_marks INTEGER,
      obtained_marks INTEGER,
      percentage DECIMAL(5,2),
      grade VARCHAR(10),
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Admit Cards table
    `CREATE TABLE IF NOT EXISTS admit_cards (
      id SERIAL PRIMARY KEY,
      student_id INTEGER REFERENCES students(id),
      exam_name VARCHAR(255) NOT NULL,
      exam_date DATE,
      exam_venue VARCHAR(255),
      reporting_time TIME,
      is_downloaded BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Notices/Announcements table
    `CREATE TABLE IF NOT EXISTS notices (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      content TEXT,
      category VARCHAR(50),
      attachment_url TEXT,
      is_active BOOLEAN DEFAULT true,
      published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Gallery table
    `CREATE TABLE IF NOT EXISTS gallery (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255),
      type VARCHAR(20) NOT NULL,
      url TEXT NOT NULL,
      thumbnail_url TEXT,
      category VARCHAR(50),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Downloads table
    `CREATE TABLE IF NOT EXISTS downloads (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      file_url TEXT NOT NULL,
      file_type VARCHAR(50),
      file_size VARCHAR(20),
      download_count INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Franchises/Centers table
    `CREATE TABLE IF NOT EXISTS franchises (
      id SERIAL PRIMARY KEY,
      center_code VARCHAR(50) UNIQUE NOT NULL,
      name VARCHAR(255) NOT NULL,
      address TEXT,
      city VARCHAR(100),
      state VARCHAR(100),
      phone VARCHAR(20),
      email VARCHAR(255),
      is_verified BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    // Create indexes for performance
    `CREATE INDEX IF NOT EXISTS idx_students_reg ON students(registration_number)`,

    // NEW TABLES FOR FULL SYNC

    // Fee Reports
    `CREATE TABLE IF NOT EXISTS fee_reports (
            id SERIAL PRIMARY KEY,
            reg_no VARCHAR(50),
            student_name VARCHAR(255),
            course VARCHAR(100),
            amount DECIMAL(10,2),
            payment_date VARCHAR(50),
            payment_mode VARCHAR(50),
            txn_id VARCHAR(100),
            remarks TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,

    // Branch Wallet
    `CREATE TABLE IF NOT EXISTS branch_wallet (
            id SERIAL PRIMARY KEY,
            branch_name VARCHAR(100),
            amount DECIMAL(10,2),
            txn_date VARCHAR(50),
            txn_type VARCHAR(50),
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,

    // Web Pages (CMS)
    `CREATE TABLE IF NOT EXISTS web_pages (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255),
            image_url TEXT,
            content TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,

    // Albums (Photos & Videos)
    `CREATE TABLE IF NOT EXISTS albums (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255),
            type VARCHAR(20), -- 'photo' or 'video'
            url VARCHAR(255),
            item_count INTEGER,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`,

    // Alter Downloads for Subject/Program support (if not exists technique via do block or just safe generic column adds if supported, but simple ADD COLUMN IF NOT EXISTS is best for PG)
    `ALTER TABLE downloads ADD COLUMN IF NOT EXISTS program VARCHAR(100)`,
    `ALTER TABLE downloads ADD COLUMN IF NOT EXISTS subject VARCHAR(100)`,

    // Alter Results for detailed marks
    `ALTER TABLE results ADD COLUMN IF NOT EXISTS total_questions INTEGER`,
    `ALTER TABLE results ADD COLUMN IF NOT EXISTS attempted INTEGER`,
    `ALTER TABLE results ADD COLUMN IF NOT EXISTS correct INTEGER`,
    `ALTER TABLE results ADD COLUMN IF NOT EXISTS wrong INTEGER`,

    // Relax Admit Card data types for unstructured scraping
    `ALTER TABLE admit_cards ALTER COLUMN reporting_time TYPE VARCHAR(100)`,
    `ALTER TABLE admit_cards ALTER COLUMN exam_date TYPE VARCHAR(100)`
  ];

  console.log('🔄 Running database migrations...');

  for (const query of queries) {
    try {
      await db.query(query);
      console.log('✅ Migration step completed');
    } catch (error) {
      console.error('❌ Migration error:', error.message);
    }
  }

  console.log('🎉 Database migration completed!');
  process.exit(0);
};

createTables();
