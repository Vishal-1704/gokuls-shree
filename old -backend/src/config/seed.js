const db = require('./database');
const bcrypt = require('bcryptjs');

const seedData = async () => {
    console.log('🌱 Seeding database with REAL data from gokulshreeschool.com...');

    try {
        // ============================================
        // DIPLOMA COURSES (from website)
        // ============================================
        const diplomaCourses = [
            // Certificates
            { title: 'Certificate In Computer Awareness (CCA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Internet Application (CIA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Typing Master (CTM)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Office Applications (COA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Office Automation (COA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Computer Fundamentals (CCF)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Information Technology (CIT)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Desk Top Publishing (CDTP)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Financial Accounting (CFA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Computer Hardware (CCH)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Information Technology Application (CITA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Web Design (CWD)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Tally (CTALLY)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Networking (CNET)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In C Language (CCL)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In C++ (CC++)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Hindi Typing (CHT)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In English Typing (CET)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Hindi & English Typing (CHET)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Flash Animation (CFA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In JAVA (CJAVA)', duration: '3 Months', eligibility: '12th Pass' },
            { title: 'Certificate In ORACLE (CORACLE)', duration: '3 Months', eligibility: '12th Pass' },
            { title: 'Certificate In Basic Computer (CBC)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In CPU Repairing (CCPUR)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In PC Assembling (CPCA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate in Computer Application (CCA)', duration: '3 Months', eligibility: '10th Pass' },
            { title: 'Certificate In Python (CIP)', duration: '3 Months', eligibility: '12th Pass' },
            // Diplomas
            { title: 'Diploma In Information Technology (DIT)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma In Computer Application (DCA)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma In Computer Programming (DCP)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in AutoCad (DAC)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma Course In Web Designing (DCWD)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma In Computer Science (DCS)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in Data Entry Operation (DDEO)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma In Professional Computer Accounting (DPCA)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma In Typing Master (DTM)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma In MS-OFFICE (DMSO)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma in Financial Accounting (DFA)', duration: '6 Months', eligibility: '12th Pass' },
            // Advanced Diplomas
            { title: 'Advance Diploma In Computer Application (ADCA)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Office Automation & Computer Programming (ADOACP)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Information Technology (ADIT)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Desk Top Publishing (ADDTP)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Secretarial Practice & Publishing (ADSPP)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Computer Hardware & Networking (ADCHN)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Information Technology Application (ADITA)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Office Publication (ADOP)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Design & Integration (ADDI)', duration: '1 Year', eligibility: '12th Pass' },
            // Master & PG Diplomas
            { title: 'Master Diploma In Financial Accounting (MDFA)', duration: '18 Months', eligibility: 'Graduation' },
            { title: 'Master Diploma In Computer Programming (MDCP)', duration: '18 Months', eligibility: 'Graduation' },
            { title: 'Master Diploma In Data Entry Operation (MDEO)', duration: '18 Months', eligibility: 'Graduation' },
            { title: 'PGDCA (Post Graduation Diploma in Computer Application)', duration: '1 Year', eligibility: 'Graduation' },
            { title: 'PGDBA (Post Graduation Diploma in Business Administration)', duration: '1 Year', eligibility: 'Graduation' },
        ];

        // ============================================
        // VOCATIONAL COURSES (from website)
        // ============================================
        const vocationalCourses = [
            { title: 'Certificate in Mobile Repairing Course (CMRC)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Certificate in AC Repairing & Maintenance Course (CARM)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Certificate in Color T.V., CD & DVD Repairing Course (CTCDR)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma in Fashion Designing (DFD)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Textile Designing (DTD)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Interior Designing (DID)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Beautician (DIB)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma in Dress Designing (DDD)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Advanced Diploma in Cutting & Tailoring (ADACT)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Computer Aided Design (DCAD)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Advance Diploma in Fashion Designing (ADFD)', duration: '18 Months', eligibility: '12th Pass' },
            { title: 'Advance Diploma in Textile Designing (ADTD)', duration: '18 Months', eligibility: '12th Pass' },
            { title: 'Advance Diploma in Beautician (ADB)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Retail Management (DRM)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in Real Estate Management (DREM)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in Refrigeration & Air Conditioner Course (DRA)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Electronic Equipment (DEE)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Advance Diploma in Dress Designing (ADDD)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Diploma in Rural Development (DRD)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in NGO Management (DNM)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in Green House Management (DGHM)', duration: '6 Months', eligibility: '12th Pass' },
            { title: 'Diploma in Dance and Music (DDM)', duration: '1 Year', eligibility: '10th Pass' },
            { title: 'Diploma in Laundry Services (DLS)', duration: '6 Months', eligibility: '10th Pass' },
            { title: 'Diploma in Preservation of Fruit & Vegetables (DPFV)', duration: '6 Months', eligibility: '10th Pass' },
        ];

        // ============================================
        // YOGA COURSES (from website)
        // ============================================
        const yogaCourses = [
            { title: 'Diploma In Yoga Teacher Training (DYTT)', duration: '1 Year', eligibility: '12th Pass' },
            { title: 'Advance Diploma In Yoga Teacher Training (ADYTT)', duration: '18 Months', eligibility: '12th Pass' },
            { title: 'Post Graduate Diploma In Yoga (PGDY)', duration: '1 Year', eligibility: 'Graduation' },
        ];

        // ============================================
        // UNIVERSITY COURSES (from website)
        // ============================================
        const universityCourses = [
            { title: 'Bachelor of Arts (B.A.)', duration: '3 Years', eligibility: '12th Pass' },
            { title: 'Bachelor of Computer Application (BCA)', duration: '3 Years', eligibility: '12th Pass' },
            { title: 'Bachelor of Business Administration (BBA)', duration: '3 Years', eligibility: '12th Pass' },
            { title: 'Bachelor of Science (B.Sc)', duration: '3 Years', eligibility: '12th Pass (Science)' },
            { title: 'Master of Information Technology (M.Sc.IT)', duration: '2 Years', eligibility: 'Graduation' },
            { title: 'Master of Science (M.Sc)', duration: '2 Years', eligibility: 'B.Sc' },
            { title: 'Master of Arts (MA)', duration: '2 Years', eligibility: 'B.A.' },
            { title: 'Post Graduate Diploma in Computer Application (PGDCA)', duration: '1 Year', eligibility: 'Graduation' },
            { title: 'Post Graduate Diploma in Human Resource Management (PGDHRM)', duration: '1 Year', eligibility: 'Graduation' },
        ];

        // Insert all courses
        const allCourses = [
            ...diplomaCourses.map(c => ({ ...c, category: 'Diploma' })),
            ...vocationalCourses.map(c => ({ ...c, category: 'Vocational' })),
            ...yogaCourses.map(c => ({ ...c, category: 'Yoga' })),
            ...universityCourses.map(c => ({ ...c, category: 'University' })),
        ];

        console.log(`📚 Inserting ${allCourses.length} courses...`);
        for (const course of allCourses) {
            await db.query(
                `INSERT INTO courses (title, category, duration, eligibility) 
         VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING`,
                [course.title, course.category, course.duration, course.eligibility]
            );
        }
        console.log('✅ Courses seeded');

        // Seed Demo Student
        const hashedPassword = await bcrypt.hash('password', 10);
        await db.query(
            `INSERT INTO students (registration_number, name, email, phone, password_hash, course_id, session_year)
       VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (registration_number) DO NOTHING`,
            ['12345', 'Demo Student', 'demo@gokulshree.com', '9876543210', hashedPassword, 1, '2025-26']
        );
        console.log('✅ Demo student created (RegNo: 12345, Password: password)');

        // Seed Notices
        const notices = [
            { title: 'CCC, BCC & O LEVEL - ADMISSION OPEN', category: 'admission' },
            { title: 'New Session 2025-26 Registration Started', category: 'admission' },
            { title: 'O-Level Examination Schedule Released', category: 'exam' },
            { title: 'ADCA Result Declared - Check Now', category: 'result' },
            { title: 'Certificate Distribution Program - 15th Feb', category: 'event' },
            { title: 'Python Programming Workshop - Register Now', category: 'event' },
        ];

        for (const notice of notices) {
            await db.query(
                `INSERT INTO notices (title, category) VALUES ($1, $2)`,
                [notice.title, notice.category]
            );
        }
        console.log('✅ Notices seeded');

        // Seed Downloads
        const downloads = [
            { title: 'Admission Form 2025-26', description: 'Download admission form for new students', file_type: 'PDF' },
            { title: 'Course Prospectus', description: 'Complete course details and fee structure', file_type: 'PDF' },
            { title: 'Exam Guidelines', description: 'Rules and regulations for examinations', file_type: 'PDF' },
            { title: 'Sample Question Papers', description: 'Previous year question papers', file_type: 'ZIP' },
            { title: 'Student ID Card Form', description: 'Form for new ID card request', file_type: 'PDF' },
        ];

        for (const download of downloads) {
            await db.query(
                `INSERT INTO downloads (title, description, file_url, file_type) VALUES ($1, $2, $3, $4)`,
                [download.title, download.description, '#', download.file_type]
            );
        }
        console.log('✅ Downloads seeded');

        console.log('🎉 Database seeding completed with REAL website data!');
    } catch (error) {
        console.error('❌ Seeding error:', error.message);
    }

    process.exit(0);
};

seedData();
