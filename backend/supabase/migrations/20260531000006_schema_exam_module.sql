-- Create Exam Module Tables and Alter Exam Results for compatibility

CREATE TABLE IF NOT EXISTS paper_sets (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INTEGER DEFAULT 60,
    total_marks INTEGER DEFAULT 100,
    total_questions INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID
);

CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    paper_set_id INTEGER REFERENCES paper_sets(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    option_a VARCHAR(255),
    option_b VARCHAR(255),
    option_c VARCHAR(255),
    option_d VARCHAR(255),
    correct_option CHAR(1) CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    marks INTEGER DEFAULT 1,
    question_number INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exam_sessions (
    id SERIAL PRIMARY KEY,
    paper_set_id INTEGER REFERENCES paper_sets(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'started', -- started, in_progress, completed
    score INTEGER,
    total_questions INTEGER,
    correct_answers INTEGER,
    wrong_answers INTEGER
);

CREATE TABLE IF NOT EXISTS exam_answers (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES exam_sessions(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    selected_option CHAR(1),
    is_correct BOOLEAN,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issued_documents (
    id SERIAL PRIMARY KEY,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    document_type VARCHAR(50),
    document_url TEXT,
    document_hash VARCHAR(256),
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alter exam_results to support new exam module and admin results
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS session_id INTEGER REFERENCES exam_sessions(id) ON DELETE CASCADE;
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS percent_score NUMERIC(5,2);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS grade VARCHAR(5);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS result_status VARCHAR(10);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS subject_name VARCHAR(255);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS marks_obtained NUMERIC(10,2);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS exam_name VARCHAR(255);
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE exam_results ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMPTZ DEFAULT now();
