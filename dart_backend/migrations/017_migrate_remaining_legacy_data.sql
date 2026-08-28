-- 017_migrate_remaining_legacy_data.sql
-- Migrating marksheets, fees, emp, admin_login from legacy DB


DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0300722';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (26, s_id, 36, 'GOKUL0300722', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 947, 94.70, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'MSB0091021';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (3, s_id, 36, 'MSB0091021', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 75, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Tally Erp9", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 887, 88.70, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'MSB0101021';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (6, s_id, 36, 'MSB0101021', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 62, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "OS ( Dos, Windows)", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 65, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 51, "practical": 0, "viva": 0, "total_marks": 100, "grade": "D"}, {"name": "Programming In C", "theory": 42, "practical": 0, "viva": 0, "total_marks": 100, "grade": "F"}, {"name": "Page Maker", "theory": 73, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Internet Technology & E-Mail", "theory": 87, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 61, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Project & Practical.", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}]}', 1000, 669, 66.90, 'C', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0181121';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (25, s_id, 26, 'GOKUL0181121', '{"subjects": [{"name": "Computer Fundamental", "theory": 77, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Ms-Office", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet & Multimedia", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Coreldraw, Photoshop, Pagemaker", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 600, 550, 91.67, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0550323';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (37, s_id, 36, 'GOKUL0550323', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 967, 96.70, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0541122';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (36, s_id, 57, 'GOKUL0541122', '{"subjects": [{"name": "English Typing  ( Avg. Speed 38 WPM )", "theory": 100, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Hindi Typing ( Avg. Speed 32 WPM )", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 200, 190, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0560323';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (72, s_id, 57, 'GOKUL0560323', '{"subjects": [{"name": "English Typing  ( Avg. Speed 38 WPM )", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Hindi Typing ( Avg. Speed 32 WPM )", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 200, 195, 97.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0570423';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (40, s_id, 36, 'GOKUL0570423', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 932, 93.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0630823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (54, s_id, 96, 'GOKUL0630823', '{"subjects": [{"name": "Advanced Computer Architecture", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer Graphics and Multimedia", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Software Engineering", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer Networks", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Advanced Operating System", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Web Designing", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 600, 575, 95.83, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0580423';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (43, s_id, 82, 'GOKUL0580423', '{"subjects": [{"name": "MAKE-UP", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HAIR DRESSING", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "ADVANCE MEHENDI", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "SKIN CARE", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HAIR CARE", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "ADVANCE BLEACH", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "BODY MASSAGE", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "SPA THERAPY", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "BODY WAX", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "PERSONALITY DEVELOPMENT", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 932, 93.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0191121';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (47, s_id, 26, 'GOKUL0191121', '{"subjects": [{"name": "Computer Fundamental", "theory": 85, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Ms-Office", "theory": 83, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet & Multimedia", "theory": 73, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Coreldraw, Photoshop, Pagemaker", "theory": 65, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Project & Practical", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}]}', 600, 454, 75.67, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0590423';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (49, s_id, 57, 'GOKUL0590423', '{"subjects": [{"name": "English Typing  ( Avg. Speed 38 WPM )", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Hindi Typing ( Avg. Speed 32 WPM )", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 200, 185, 92.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0600423';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (52, s_id, 26, 'GOKUL0600423', '{"subjects": [{"name": "Computer Fundamental", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Ms-Office", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet & Multimedia", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 87, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Coreldraw, Photoshop, Pagemaker", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 600, 523, 87.17, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0640823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (55, s_id, 96, 'GOKUL0640823', '{"subjects": [{"name": "Advanced Computer Architecture", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer Graphics and Multimedia", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Software Engineering", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer Networks", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Advanced Operating System", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Web Designing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 600, 570, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0650823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (56, s_id, 36, 'GOKUL0650823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 961, 96.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0660823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (58, s_id, 36, 'GOKUL0660823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 955, 95.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0670823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (59, s_id, 36, 'GOKUL0670823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 950, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0680823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (60, s_id, 36, 'GOKUL0680823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 953, 95.30, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0690823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (61, s_id, 36, 'GOKUL0690823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 950, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0700823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (62, s_id, 36, 'GOKUL0700823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 952, 95.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0710823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (63, s_id, 36, 'GOKUL0710823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 955, 95.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0720823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (64, s_id, 36, 'GOKUL0720823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 952, 95.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0730823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (65, s_id, 36, 'GOKUL0730823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 949, 94.90, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0740823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (66, s_id, 36, 'GOKUL0740823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 957, 95.70, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0750823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (67, s_id, 36, 'GOKUL0750823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 955, 95.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0760823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (68, s_id, 36, 'GOKUL0760823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 950, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0770823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (69, s_id, 36, 'GOKUL0770823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 953, 95.30, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0780823';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (70, s_id, 36, 'GOKUL0780823', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 953, 95.30, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL79';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (71, s_id, 36, 'GOKUL79', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 950, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0230122';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (74, s_id, 36, 'GOKUL0230122', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 75, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 79, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 77, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 83, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 81, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 815, 81.50, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'SKILLMAX0171121';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (75, s_id, 36, 'SKILLMAX0171121', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 947, 94.70, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0280722';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (76, s_id, 36, 'GOKUL0280722', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 925, 92.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0801023';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (79, s_id, 57, 'GOKUL0801023', '{"subjects": [{"name": "English Typing  ( Avg. Speed 38 WPM )", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Hindi Typing ( Avg. Speed 32 WPM )", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 200, 194, 97.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0521122';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (80, s_id, 36, 'GOKUL0521122', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 969, 96.90, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0220122';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (81, s_id, 36, 'GOKUL0220122', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 73, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Internet Technology & E-Mail", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}]}', 1000, 810, 81.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0851223 ';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (83, s_id, 36, 'GOKUL0851223 ', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 958, 95.80, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0861223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (84, s_id, 36, 'GOKUL0861223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 960, 96.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0871223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (85, s_id, 36, 'GOKUL0871223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 963, 96.30, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0881223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (86, s_id, 36, 'GOKUL0881223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 950, 95.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0891223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (87, s_id, 36, 'GOKUL0891223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 960, 96.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0901223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (89, s_id, 36, 'GOKUL0901223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 956, 95.60, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0911223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (90, s_id, 36, 'GOKUL0911223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 927, 92.70, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0921223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (91, s_id, 36, 'GOKUL0921223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 932, 93.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0931223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (92, s_id, 36, 'GOKUL0931223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 931, 93.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0941223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (93, s_id, 36, 'GOKUL0941223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 934, 93.40, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0951223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (94, s_id, 36, 'GOKUL0951223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 951, 95.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0961223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (95, s_id, 36, 'GOKUL0961223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 91, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 951, 95.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0971223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (96, s_id, 36, 'GOKUL0971223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 945, 94.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0981223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (97, s_id, 36, 'GOKUL0981223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 951, 95.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0991223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (98, s_id, 36, 'GOKUL0991223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 85, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 89, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 87, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 87, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 913, 91.30, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1001223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (99, s_id, 36, 'GOKUL1001223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 935, 93.50, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL42';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (100, s_id, 36, 'GOKUL42', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 971, 97.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL50';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (102, s_id, 36, 'GOKUL50', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 971, 97.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL46';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (103, s_id, 36, 'GOKUL46', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 971, 97.10, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1031223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (104, s_id, 36, 'GOKUL1031223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 99, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 960, 96.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1040224';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (105, s_id, 36, 'GOKUL1040224', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 95, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 93, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 97, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 952, 95.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004134';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (119, s_id, 36, 'GOKUL004134', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 878, 87.80, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1011223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (116, s_id, 36, 'GOKUL1011223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Programming In C", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 934, 93.40, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0841123';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (117, s_id, 36, 'GOKUL0841123', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 910, 91.00, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004136';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (118, s_id, 36, 'GOKUL004136', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 870, 87.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0041330924';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (120, s_id, 36, 'GOKUL0041330924', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 890, 89.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0041320924';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (121, s_id, 36, 'GOKUL0041320924', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 902, 90.20, 'A+', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004131';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (122, s_id, 36, 'GOKUL004131', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 878, 87.80, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004130';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (123, s_id, 36, 'GOKUL004130', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 856, 85.60, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004129';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (124, s_id, 36, 'GOKUL004129', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 852, 85.20, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004128';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (125, s_id, 36, 'GOKUL004128', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 65, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Computer English  Typing", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 98, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 863, 86.30, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004127';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (126, s_id, 36, 'GOKUL004127', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 65, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Programming In C", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 851, 85.10, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004125';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (127, s_id, 36, 'GOKUL004125', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 66, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "OS ( Dos, Windows)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 850, 85.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004124';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (128, s_id, 36, 'GOKUL004124', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Tally Erp9", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Programming In C", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 856, 85.60, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004123';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (129, s_id, 36, 'GOKUL004123', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "OS ( Dos, Windows)", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Tally Erp9", "theory": 62, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Programming In C", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 836, 83.60, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0041501224';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (131, s_id, 36, 'GOKUL0041501224', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 874, 87.40, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0041431024';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (132, s_id, 36, 'GOKUL0041431024', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 866, 86.60, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0041421024';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (133, s_id, 36, 'GOKUL0041421024', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "OS ( Dos, Windows)", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Page Maker", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "HTML", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 860, 86.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL004141';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (134, s_id, 36, 'GOKUL004141', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "OS ( Dos, Windows)", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 850, 85.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1391024';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (135, s_id, 50, 'GOKUL1391024', '{"subjects": [{"name": "Tally Prime with GST ", "theory": 52, "practical": 0, "viva": 0, "total_marks": 100, "grade": "D"}]}', 100, 52, 52.00, 'D', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1200924';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (136, s_id, 50, 'GOKUL1200924', '{"subjects": [{"name": "Tally Prime with GST ", "theory": 54, "practical": 0, "viva": 0, "total_marks": 100, "grade": "D"}]}', 100, 54, 54.00, 'D', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1441024';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (137, s_id, 50, 'GOKUL1441024', '{"subjects": [{"name": "Tally Prime with GST ", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}]}', 100, 72, 72.00, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1461124';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (138, s_id, 50, 'GOKUL1461124', '{"subjects": [{"name": "Tally Prime with GST ", "theory": 62, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}]}', 100, 62, 62.00, 'C', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL0831023';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (139, s_id, 36, 'GOKUL0831023', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 0, "practical": 0, "viva": 0, "total_marks": 100, "grade": "F"}, {"name": "Tally Erp9", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 776, 77.60, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1021223';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (140, s_id, 36, 'GOKUL1021223', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 860, 86.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1540625';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (142, s_id, 50, 'GOKUL1540625', '{"subjects": [{"name": "Tally Prime with GST ", "theory": 57, "practical": 0, "viva": 0, "total_marks": 100, "grade": "D"}]}', 100, 57, 57.00, 'D', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1481124';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (143, s_id, 36, 'GOKUL1481124', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Tally Erp9", "theory": 70, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 772, 77.20, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1100524';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (144, s_id, 36, 'GOKUL1100524', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 75, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 85, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 830, 83.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1130624';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (145, s_id, 36, 'GOKUL1130624', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Page Maker", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "HTML", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 806, 80.60, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1530625';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (146, s_id, 36, 'GOKUL1530625', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 70, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Tally Erp9", "theory": 66, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Programming In C", "theory": 80, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 74, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 782, 78.20, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GOKUL1140824';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (147, s_id, 36, 'GOKUL1140824', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "OS ( Dos, Windows)", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Computer English  Typing", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 64, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Programming In C", "theory": 70, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Page Maker", "theory": 68, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Internet Technology & E-Mail", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 66, "practical": 0, "viva": 0, "total_marks": 100, "grade": "C"}, {"name": "Project & Practical.", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 768, 76.80, 'B', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GO100110020241760126';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (148, s_id, 36, 'GO100110020241760126', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "OS ( Dos, Windows)", "theory": 92, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Computer English  Typing", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Tally Erp9", "theory": 82, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Programming In C", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 90, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "Internet Technology & E-Mail", "theory": 76, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Project & Practical.", "theory": 96, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}]}', 1000, 850, 85.00, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = 'GO100110020241750126';
    IF s_id IS NOT NULL THEN
        INSERT INTO marksheets (legacy_id, student_id, course_id, roll_no, marks, total_marks, obtained_marks, percentage, grade, result, exam_date, issue_date, status)
        VALUES (149, s_id, 36, 'GO100110020241750126', '{"subjects": [{"name": "Computer Concept & Fundamentals", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "OS ( Dos, Windows)", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Computer English  Typing", "theory": 94, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A+"}, {"name": "MS Office(Word, Adv.Excel, Access, PowerPoint)", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Tally Erp9", "theory": 78, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "Programming In C", "theory": 88, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Page Maker", "theory": 86, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Internet Technology & E-Mail", "theory": 72, "practical": 0, "viva": 0, "total_marks": 100, "grade": "B"}, {"name": "HTML", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}, {"name": "Project & Practical.", "theory": 84, "practical": 0, "viva": 0, "total_marks": 100, "grade": "A"}]}', 1000, 838, 83.80, 'A', 'PASS', NULL, NULL, 1)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '9';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (1, s_id, 6.0, 6.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '12';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (3, s_id, 8.0, 8.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '25';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (7, s_id, 18.0, 18.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '8';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (5, s_id, 5.0, 5.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '26';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (8, s_id, 19.0, 19.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '27';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (9, s_id, 20.0, 20.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '25';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (10, s_id, 18.0, 18.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '28';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (11, s_id, 21.0, 21.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '27';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (12, s_id, 20.0, 20.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '26';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (13, s_id, 19.0, 19.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '25';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (14, s_id, 18.0, 18.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '35';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (15, s_id, 28.0, 28.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '35';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (16, s_id, 28.0, 28.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '36';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (17, s_id, 29.0, 29.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '46';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (18, s_id, 38.0, 38.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '51';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (19, s_id, 43.0, 43.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '52';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (20, s_id, 44.0, 44.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '53';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (21, s_id, 45.0, 45.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (38, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '24';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (23, s_id, 17.0, 17.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '24';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (24, s_id, 17.0, 17.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (25, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (26, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (27, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (28, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (29, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '40';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (30, s_id, 32.0, 32.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '56';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (31, s_id, 48.0, 48.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '44';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (32, s_id, 36.0, 36.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (33, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (34, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (35, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (36, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '51';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (37, s_id, 43.0, 43.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (39, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (40, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (41, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (42, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (43, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (44, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (45, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '51';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (46, s_id, 43.0, 43.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '51';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (47, s_id, 43.0, 43.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '56';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (48, s_id, 48.0, 48.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (49, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (50, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (51, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (52, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (53, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (54, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (55, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (56, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '63';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (57, s_id, 55.0, 55.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '64';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (58, s_id, 56.0, 56.0, NULL, '57', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (59, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '65';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (60, s_id, 57.0, 57.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (61, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (62, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (63, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (64, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (65, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (66, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (67, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (68, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (69, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (70, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (71, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (72, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (73, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (74, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '50';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (76, s_id, 42.0, 42.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '60';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (77, s_id, 52.0, 52.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '54';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (78, s_id, 46.0, 46.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '24';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (79, s_id, 17.0, 17.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '28';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (80, s_id, 21.0, 21.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '24';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (81, s_id, 17.0, 17.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (82, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (87, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '51';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (84, s_id, 43.0, 43.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (86, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (88, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '58';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (89, s_id, 50.0, 50.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '119';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (90, s_id, 110.0, 110.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '119';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (91, s_id, 110.0, 110.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '114';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (92, s_id, 105.0, 105.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '114';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (93, s_id, 105.0, 105.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '121';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (94, s_id, 112.0, 112.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '121';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (95, s_id, 112.0, 112.0, NULL, '26', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '106';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (96, s_id, 97.0, 97.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '113';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (97, s_id, 104.0, 104.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '112';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (98, s_id, 103.0, 103.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '125';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (99, s_id, 115.0, 115.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '125';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (100, s_id, 115.0, 115.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '131';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (101, s_id, 120.0, 120.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '134';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (102, s_id, 122.0, 122.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '151';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (104, s_id, 139.0, 139.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '148';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (105, s_id, 136.0, 136.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '146';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (106, s_id, 134.0, 134.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '145';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (107, s_id, 133.0, 133.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '144';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (108, s_id, 132.0, 132.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '143';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (109, s_id, 131.0, 131.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '142';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (110, s_id, 130.0, 130.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '141';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (111, s_id, 129.0, 129.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '140';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (112, s_id, 128.0, 128.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '139';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (113, s_id, 127.0, 127.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '138';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (114, s_id, 126.0, 126.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '137';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (115, s_id, 125.0, 125.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '136';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (116, s_id, 124.0, 124.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '135';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (117, s_id, 123.0, 123.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (134, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '156';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (119, s_id, 144.0, 144.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '151';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (120, s_id, 139.0, 139.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '157';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (121, s_id, 145.0, 145.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '156';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (122, s_id, 144.0, 144.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '131';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (123, s_id, 120.0, 120.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '158';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (124, s_id, 146.0, 146.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '158';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (125, s_id, 146.0, 146.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '151';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (126, s_id, 139.0, 139.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '162';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (127, s_id, 150.0, 150.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '155';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (128, s_id, 143.0, 143.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '154';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (129, s_id, 142.0, 142.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '153';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (130, s_id, 141.0, 141.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '152';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (131, s_id, 140.0, 140.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '152';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (132, s_id, 140.0, 140.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '152';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (133, s_id, 140.0, 140.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (135, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (136, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (137, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (138, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '128';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (139, s_id, 117.0, 117.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '128';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (140, s_id, 117.0, 117.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '128';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (141, s_id, 117.0, 117.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '111';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (142, s_id, 102.0, 102.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '92';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (143, s_id, 83.0, 83.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '156';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (144, s_id, 144.0, 144.0, NULL, '50', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '119';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (145, s_id, 110.0, 110.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '122';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (146, s_id, 113.0, 113.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '167';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (147, s_id, 153.0, 153.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '122';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (148, s_id, 113.0, 113.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '128';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (149, s_id, 117.0, 117.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '123';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (150, s_id, 114.0, 114.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '128';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (151, s_id, 117.0, 117.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '191';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (152, s_id, 176.0, 176.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

DO $$
DECLARE
    s_id INT;
BEGIN
    SELECT id INTO s_id FROM students WHERE reg_no = '190';
    IF s_id IS NOT NULL THEN
        INSERT INTO fee_payments (legacy_id, student_id, amount, net_pay, payment_date, description, payment_mode)
        VALUES (153, s_id, 175.0, 175.0, NULL, '36', 'CASH')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;