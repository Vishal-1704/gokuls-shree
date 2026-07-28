-- Add UNIQUE constraints/indexes on legacy_id for all tables to allow clean upsert operations

ALTER TABLE branches ADD CONSTRAINT uq_branches_legacy_id UNIQUE (legacy_id);
ALTER TABLE courses ADD CONSTRAINT uq_courses_legacy_id UNIQUE (legacy_id);
ALTER TABLE subjects ADD CONSTRAINT uq_subjects_legacy_id UNIQUE (legacy_id);
ALTER TABLE students ADD CONSTRAINT uq_students_legacy_id UNIQUE (legacy_id);
ALTER TABLE fee_payments ADD CONSTRAINT uq_fee_payments_legacy_id UNIQUE (legacy_id);
ALTER TABLE student_attendance ADD CONSTRAINT uq_student_attendance_legacy_id UNIQUE (legacy_id);
ALTER TABLE marksheets ADD CONSTRAINT uq_marksheets_legacy_id UNIQUE (legacy_id);
ALTER TABLE exam_categories ADD CONSTRAINT uq_exam_categories_legacy_id UNIQUE (legacy_id);
ALTER TABLE exam_results ADD CONSTRAINT uq_exam_results_legacy_id UNIQUE (legacy_id);
ALTER TABLE admit_cards ADD CONSTRAINT uq_admit_cards_legacy_id UNIQUE (legacy_id);
ALTER TABLE notices ADD CONSTRAINT uq_notices_legacy_id UNIQUE (legacy_id);
ALTER TABLE downloads ADD CONSTRAINT uq_downloads_legacy_id UNIQUE (legacy_id);
