-- Exam Module Schema

CREATE TABLE IF NOT EXISTS paper_sets (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INTEGER DEFAULT 60,
    total_marks INTEGER DEFAULT 100,
    total_questions INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER -- references staff/admin
);

CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    paper_set_id INTEGER REFERENCES paper_sets(id),
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
    paper_set_id INTEGER REFERENCES paper_sets(id),
    student_id INTEGER, -- references students table (if integer ID) or auth.users? Application seems to treat as string sometimes? 
    -- The error log said: "Key is not present in table students". Students table has 'id' (integer) and 'registration_number' (varchar).
    -- ExamRepository uses studentId as string in startExamSession, but schema usually implies int fk.
    -- Let's check students schema again. debug_schema_columns said students.id is integer.
    -- However, the user's error "Key is not present in table students" was for 'issued_documents'.
    -- The ExamRepository uses 'student_id' in queries.
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
    session_id INTEGER REFERENCES exam_sessions(id),
    question_id INTEGER REFERENCES questions(id),
    selected_option CHAR(1),
    is_correct BOOLEAN,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exam_results (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES exam_sessions(id),
    percent_score NUMERIC(5,2),
    grade VARCHAR(5),
    result_status VARCHAR(10), -- PASS/FAIL
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Missing table for document generation history (from previous context error)
CREATE TABLE IF NOT EXISTS issued_documents (
    id SERIAL PRIMARY KEY,
    student_id INTEGER, -- Let's assume referring to students.id
    document_type VARCHAR(50),
    document_url TEXT,
    document_hash VARCHAR(256),
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
