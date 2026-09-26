-- New courses + their subjects, and subjects for the one existing course
-- (Certificate In Basic Computer, id 61) that had none.
--
-- Deliberately does NOT touch existing courses' fee/name/other columns —
-- DCA(26)/ADCA(36)/Tally(50)/CHET(57)/ADB(82)/CCA(96) already have real
-- fees and, except CBC, real subjects tied to live student records; this
-- migration only adds new rows, never updates existing ones.
--
-- Fee ratio (superadmin-approved): 1 Year=1000, 6 Months=500, 3 Months=250,
-- 2 Months=170, 1 Month=85 — proportional to the 1yr/6mo anchor points.

-- ── New courses ──────────────────────────────────────────────────────────
INSERT INTO public.courses (name, short_name, duration, fee, category, total_marks, pass_marks)
SELECT * FROM (VALUES
  ('Diploma Course in Web Designing',  'DCWD', '6 Months', 500.00,  'Computer',    100, 40),
  ('Certificate in C Language',        'CC',   '2 Months', 170.00,  'Programming', 100, 40),
  ('Certificate in C++',               'CPP',  '2 Months', 170.00,  'Programming', 100, 40),
  ('Certificate in Python',            'PY',   '2 Months', 170.00,  'Programming', 100, 40),
  ('Certificate in Java',              'JAVA', '2 Months', 170.00,  'Programming', 100, 40),
  ('Tally with GST & Taxation',        'TGST', '3 Months', 250.00,  'Accounting',  100, 40),
  ('Diploma in AutoCAD',               'DCAY', '6 Months', 500.00,  'AutoCAD',     100, 40),
  ('Diploma in Beautician',            'DIB',  '3 Months', 250.00,  'Beautician',  100, 40)
) AS v(name, short_name, duration, fee, category, total_marks, pass_marks)
WHERE NOT EXISTS (SELECT 1 FROM public.courses c WHERE c.name = v.name);

-- ── Subjects for the new courses ─────────────────────────────────────────
-- Matched by course name (just inserted above), so this is safe to re-run.
WITH course_ids AS (
  SELECT id, name FROM public.courses WHERE name IN (
    'Diploma Course in Web Designing', 'Certificate in C Language', 'Certificate in C++',
    'Certificate in Python', 'Certificate in Java', 'Tally with GST & Taxation',
    'Diploma in AutoCAD', 'Diploma in Beautician'
  )
),
new_subjects(course_name, subject_name, code) AS (
  VALUES
    ('Diploma Course in Web Designing', 'Computer Concepts & Fundamentals', 'DCWD01'),
    ('Diploma Course in Web Designing', 'Operating System (DOS, Windows)',  'DCWD02'),
    ('Diploma Course in Web Designing', 'Basic DTP',                        'DCWD03'),
    ('Diploma Course in Web Designing', 'HTML, DHTML',                     'DCWD04'),
    ('Diploma Course in Web Designing', 'CSS, JavaScript',                 'DCWD05'),
    ('Diploma Course in Web Designing', 'Internet & E-Mail',               'DCWD06'),
    ('Diploma Course in Web Designing', 'Project & Practical',             'DCWD07'),

    ('Certificate in C Language', 'Introduction to C',                     'CC01'),
    ('Certificate in C Language', 'Basic Syntax and Structure',            'CC02'),
    ('Certificate in C Language', 'Data Types and Variables',              'CC03'),
    ('Certificate in C Language', 'Operators and Expressions',             'CC04'),
    ('Certificate in C Language', 'Control Flow Structures',               'CC05'),
    ('Certificate in C Language', 'Functions and Modular Programming',     'CC06'),
    ('Certificate in C Language', 'Arrays and Strings',                    'CC07'),
    ('Certificate in C Language', 'Pointers and Memory Management',        'CC08'),

    ('Certificate in C++', 'Introduction to C++',                         'CPP01'),
    ('Certificate in C++', 'Syntax',                                      'CPP02'),
    ('Certificate in C++', 'Variables',                                   'CPP03'),
    ('Certificate in C++', 'Data Types',                                  'CPP04'),
    ('Certificate in C++', 'Arrays, Strings & Introduction to Sorting',   'CPP05'),
    ('Certificate in C++', 'Conditional Statements and Loops',            'CPP06'),
    ('Certificate in C++', 'Structures, Pointers and File Handling',      'CPP07'),

    ('Certificate in Python', 'Introduction to Python',                   'PY01'),
    ('Certificate in Python', 'Introduction to Script',                   'PY02'),
    ('Certificate in Python', 'Environment Setup',                        'PY03'),
    ('Certificate in Python', 'Writing First Program in Python',          'PY04'),
    ('Certificate in Python', 'Basics',                                   'PY05'),
    ('Certificate in Python', 'Datatypes',                                'PY06'),
    ('Certificate in Python', 'Operators',                                'PY07'),
    ('Certificate in Python', 'Input and Output',                         'PY08'),
    ('Certificate in Python', 'Control Statements',                       'PY09'),
    ('Certificate in Python', 'Arrays in Python',                         'PY10'),
    ('Certificate in Python', 'Strings and Characters',                   'PY11'),
    ('Certificate in Python', 'Functions',                                'PY12'),

    ('Certificate in Java', 'Java Introduction',                          'JAVA01'),
    ('Certificate in Java', 'Java Basics & Introduction to Eclipse',      'JAVA02'),
    ('Certificate in Java', 'Operators & Expressions',                   'JAVA03'),
    ('Certificate in Java', 'Control Statements',                        'JAVA04'),
    ('Certificate in Java', 'Java Object-Oriented Programming',          'JAVA05'),
    ('Certificate in Java', 'Inheritance',                               'JAVA06'),
    ('Certificate in Java', 'Exception Handling',                        'JAVA07'),
    ('Certificate in Java', 'Interfaces',                                'JAVA08'),

    ('Tally with GST & Taxation', 'User Interface and Company Management', 'TGST01'),
    ('Tally with GST & Taxation', 'Masters — Ledgers',                     'TGST02'),
    ('Tally with GST & Taxation', 'Masters — Groups',                     'TGST03'),
    ('Tally with GST & Taxation', 'Bill-wise Debtors and Creditors Ledger','TGST04'),
    ('Tally with GST & Taxation', 'Payment Voucher',                      'TGST05'),
    ('Tally with GST & Taxation', 'Day Book in Tally',                    'TGST06'),
    ('Tally with GST & Taxation', 'Pre-Allocation of Bills',              'TGST07'),
    ('Tally with GST & Taxation', 'Receipt Voucher',                      'TGST08'),
    ('Tally with GST & Taxation', 'Contra and Journal Voucher',           'TGST09'),
    ('Tally with GST & Taxation', 'Cheque Printing in Tally ERP',         'TGST10'),
    ('Tally with GST & Taxation', 'Masters — Inventory',                  'TGST11'),
    ('Tally with GST & Taxation', 'Purchase Voucher with GST',            'TGST12'),
    ('Tally with GST & Taxation', 'Sales Voucher with GST',               'TGST13'),
    ('Tally with GST & Taxation', 'GST Returns and Payment',              'TGST14'),
    ('Tally with GST & Taxation', 'Billing Features in Tally',            'TGST15'),
    ('Tally with GST & Taxation', 'Purchase Order Processing',            'TGST16'),

    ('Diploma in AutoCAD', 'Computer Concepts & Fundamentals',             'CAD01'),
    ('Diploma in AutoCAD', 'OS (DOS, Windows)',                            'CAD02'),
    ('Diploma in AutoCAD', 'Introduction',                                 'CAD03'),
    ('Diploma in AutoCAD', 'Drawing Object',                               'CAD04'),
    ('Diploma in AutoCAD', 'Drawing With Template',                        'CAD05'),
    ('Diploma in AutoCAD', '2D & 3D Commands',                            'CAD06'),
    ('Diploma in AutoCAD', 'Project & Practical',                         'CAD07'),

    ('Diploma in Beautician', 'Threading',                                'DIB01'),
    ('Diploma in Beautician', 'Stage Makeup',                             'DIB02'),
    ('Diploma in Beautician', 'Hair Styles',                              'DIB03'),
    ('Diploma in Beautician', 'Dandruff Treatment',                       'DIB04'),
    ('Diploma in Beautician', 'Cutting',                                  'DIB05'),
    ('Diploma in Beautician', 'Deep U',                                   'DIB06'),
    ('Diploma in Beautician', 'Light Makeup',                             'DIB07'),
    ('Diploma in Beautician', 'Home Made Bleach',                         'DIB08')
)
INSERT INTO public.subjects (course_id, name, code)
SELECT ci.id, ns.subject_name, ns.code
FROM new_subjects ns
JOIN course_ids ci ON ci.name = ns.course_name
WHERE NOT EXISTS (
  SELECT 1 FROM public.subjects s WHERE s.course_id = ci.id AND s.name = ns.subject_name
);

-- ── Subjects for the one existing course with none (CBC, id 61) ─────────
INSERT INTO public.subjects (course_id, name, code)
SELECT 61, v.name, v.code
FROM (VALUES
  ('Fundamental of Computer', 'CBC01'),
  ('Paint',                   'CBC02')
) AS v(name, code)
WHERE EXISTS (SELECT 1 FROM public.courses WHERE id = 61)
  AND NOT EXISTS (SELECT 1 FROM public.subjects WHERE course_id = 61 AND name = v.name);
