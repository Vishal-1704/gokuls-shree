const db = require('../config/database');
const axios = require('axios');
const cheerio = require('cheerio');
const FormData = require('form-data');
const { CookieJar } = require('tough-cookie');
const { wrapper } = require('axios-cookiejar-support');

class SyncService {
    constructor() {
        this.baseUrl = 'https://www.gokulshreeschool.com/new';
        this.jar = new CookieJar();
        this.client = wrapper(axios.create({
            baseURL: this.baseUrl,
            jar: this.jar,
            withCredentials: true,
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        }));
        this.isLoggedIn = false;
    }

    /**
     * authentication with the PHP backend
     */
    async login() {
        try {
            console.log('🔄 Attempting to log in to PHP Admin Panel...');

            // 1. Get the login page to initialize cookies/session
            await this.client.get('/index.php');

            // 2. Prepare login payload
            const formData = new URLSearchParams();
            formData.append('loginid', process.env.PHP_ADMIN_USER);
            formData.append('password', process.env.PHP_ADMIN_PASSWORD);
            formData.append('Submit2', 'Login'); // Correct button name from debug

            const response = await this.client.post('/login.php', formData.toString(), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            });

            // Check if login was successful (usually a redirect to dashboard)
            if (response.request.res.responseUrl.includes('dashboard.php')) {
                console.log('✅ PHP Login Successful');
                this.isLoggedIn = true;
                return true;
            } else {
                console.error('❌ PHP Login Failed: Still on login page');
                return false;
            }
        } catch (error) {
            console.error('❌ Login Error:', error.message);
            return false;
        }
    }

    /**
     * Generic method to fetch a page (auto-login if needed)
     */
    async fetchPage(endpoint) {
        if (!this.isLoggedIn) {
            const success = await this.login();
            if (!success) throw new Error('Cannot login to PHP backend');
        }

        try {
            const response = await this.client.get(endpoint);
            return cheerio.load(response.data);
        } catch (error) {
            console.error(`❌ Failed to fetch ${endpoint}:`, error.message);
            throw error;
        }
    }

    // ==========================================
    // MODULE 1: STUDENTS (Tab 8 in Sidebar)
    // ==========================================

    // ==========================================
    // MODULE: DASHBOARD
    // ==========================================
    async getDashboardStats() {
        console.log('🔄 Syncing Dashboard...');
        const $ = await this.fetchPage('/dashboard.php');

        const stats = [];
        $('.small-box').each((i, el) => {
            stats.push({
                label: $(el).find('.inner p').text().trim(),
                value: $(el).find('.inner h3').text().trim(),
                link: $(el).find('.small-box-footer').attr('href')
            });
        });

        console.log(`✅ Dashboard: Found ${stats.length} widgets`);
        return stats;
    }

    // ==========================================
    // MODULE: PROFILE
    // ==========================================
    async getProfile() {
        console.log('🔄 Syncing Admin Profile...');
        const $ = await this.fetchPage('/profile.php');

        const getText = (label) => {
            // Find td containing label, get next td
            const el = $(`td:contains("${label}")`).last();
            return el.next().text().trim();
        };

        const profile = {
            centreCode: getText('Centre Code'),
            centreName: getText('Centre Name'),
            directorName: getText("Director's Name"),
            email: getText('E-MAIL')
        };

        return profile;
    }

    // ==========================================
    // MODULE: STAFF / EMPLOYEES
    // ==========================================
    async getStaff() {
        console.log('🔄 Syncing Staff...');
        const $ = await this.fetchPage('/emp.php');

        const staffList = [];
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;

            // Skip Header
            if ($(tds[0]).text().includes('Emp ID')) return;

            staffList.push({
                empId: $(tds[0]).text().trim(),
                name: $(tds[1]).text().trim(),
                phone: $(tds[2]).text().trim(),
                salary: $(tds[3]).text().trim(),
                department: $(tds[4]).text().trim()
            });
        });

        console.log(`✅ Found ${staffList.length} staff members`);
        return staffList;
    }

    // ==========================================
    // MODULE: COURSES
    // ==========================================
    async getCourses() {
        console.log('🔄 Syncing Courses...');
        const $ = await this.fetchPage('/courses.php');

        const courses = [];
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;

            // Skip Header
            if ($(tds[1]).text().includes('Course Name')) return;

            // Extract Name and Image
            const nameEl = $(tds[1]);
            const name = nameEl.find('span').text().trim() || nameEl.text().trim();
            const image = nameEl.find('img').attr('src');

            // Fee and Duration
            const fee = $(tds[2]).find('span').text().trim();
            const duration = $(tds[3]).find('span').text().trim();

            if (name) {
                courses.push({
                    name: name,
                    fee: fee,
                    duration: duration,
                    image: image
                });
            }
        });

        console.log(`✅ Found ${courses.length} courses`);
        return courses;
    }

    // ==========================================
    // MODULE: MARKSHEETS
    // ==========================================
    async getMarksheets() {
        console.log('🔄 Syncing Marksheets (PAGINATED)...');

        const allMarksheets = [];
        let start = 0;
        const pageSize = 50;
        let hasMore = true;

        while (hasMore) {
            console.log(`   📄 Fetching marksheets starting at ${start}...`);
            const $ = await this.fetchPage(`/marksheet_list.php?start=${start}&pagecounter=${pageSize}`);

            let pageCount = 0;

            // Iterate main table rows
            $('table tr').each((i, el) => {
                const tds = $(el).find('td');
                if (tds.length < 5) return;

                // RegNo and Name
                // Cell content: <strong>REGNO</strong> - Name
                const regCell = $(tds[1]).text().trim();
                if (!regCell.includes('-')) return;

                const [regNo, ...nameParts] = regCell.split('-');
                const studentName = nameParts.join('-').trim();
                const course = $(tds[2]).text().trim().split('\n')[0]; // Remove extra newlines

                // Find Modal ID
                const validRegNo = regNo.trim();
                const modalButton = $(tds[3]).find('button');
                const targetModalId = modalButton.attr('data-target'); // e.g., #exampleModal149

                if (targetModalId) {
                    const modal = $(targetModalId);
                    const subjects = [];

                    // Scrape subject table inside modal
                    modal.find('table tr').each((j, tr) => {
                        const inputs = $(tr).find('input[name^="theory"]');
                        if (inputs.length > 0) {
                            const subName = $(tr).find('td').eq(1).text().trim();
                            const marks = inputs.val();
                            if (subName && marks) {
                                subjects.push({ subject: subName, marks: marks });
                            }
                        }
                    });

                    // Scrape Meta Data from Modal (Session, DOJ, etc)
                    const session = modal.find('input[name="csession"]').val();
                    const issueDate = modal.find('input[name="doj"]').val();
                    const marksheetNo = modal.find('input[name="mslno"]').val();
                    const certificateNo = modal.find('input[name="cslno"]').val();

                    allMarksheets.push({
                        regNo: validRegNo,
                        studentName: studentName,
                        course: course,
                        session: session,
                        issueDate: issueDate,
                        marksheetNo: marksheetNo,
                        certificateNo: certificateNo,
                        subjects: subjects
                    });
                    pageCount++;
                }
            });

            console.log(`   ✅ Page ${start / pageSize + 1}: Found ${pageCount} marksheets`);

            if (pageCount === 0) {
                hasMore = false;
            } else {
                start += pageSize;
                if (start > 2500) hasMore = false;
            }
        }

        console.log(`✅ Total: Found ${allMarksheets.length} marksheets`);
        return allMarksheets;
    }

    // ==========================================
    // MODULE: FEE MANAGEMENT
    // ==========================================

    // 1. Fee Report (Transactions)
    async getFeeReports() {
        console.log('🔄 Syncing Fee Reports...');
        const $ = await this.fetchPage('/membersfee.php');
        const fees = [];

        // Rows are alternating colors, select all rows in the main table
        // The table with "Form No." header
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 7) return;
            const linkText = $(tds[1]).text().trim();
            if (linkText === 'Form No.' || linkText.includes('Student Name')) return;

            fees.push({
                formNo: $(tds[1]).text().trim(),
                studentName: $(tds[2]).text().trim(),
                course: $(tds[3]).text().trim(),
                batch: $(tds[4]).text().trim(),
                amount: $(tds[5]).text().trim(),
                chequeNo: $(tds[6]).text().trim(),
                date: $(tds[7]).text().trim()
            });
        });

        console.log(`✅ Found ${fees.length} fee records`);
        return fees;
    }

    // 2. Branch Wallet
    async getBranchWallet() {
        console.log('🔄 Syncing Branch Wallet...');
        const $ = await this.fetchPage('/branchfee.php');
        const wallet = [];

        // Extract Net Payment header
        const netPayment = $('.box-title strong').text().trim();
        console.log(`💰 Net Branch Payment: ${netPayment}`);

        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 6) return;
            if ($(tds[0]).text().includes('SN')) return;

            wallet.push({
                branch: $(tds[1]).text().trim(),
                amount: $(tds[2]).text().trim(),
                date: $(tds[3]).text().trim(),
                description: $(tds[4]).text().trim(),
                mode: $(tds[5]).text().trim()
            });
        });

        console.log(`✅ Found ${wallet.length} wallet transactions`);
        return { netPayment, transactions: wallet };
    }

    // 3. Dues Report
    async getDuesReports() {
        console.log('🔄 Syncing Student Dues...');
        const $ = await this.fetchPage('/next-installment-date-report.php');
        const dues = [];

        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 8) return;
            if ($(tds[0]).text().includes('SID')) return;

            dues.push({
                sid: $(tds[0]).text().trim(),
                name: $(tds[1]).text().trim(),
                contact: $(tds[2]).text().trim(),
                course: $(tds[3]).text().trim(),
                totalPaid: $(tds[4]).text().trim(),
                dueAmount: $(tds[5]).text().trim(),
                dueDate: $(tds[6]).text().trim(),
                remarks: $(tds[7]).text().trim()
            });
        });

        console.log(`✅ Found ${dues.length} due records`);
        return dues;
    }

    // ==========================================
    // MODULE: EXAMS & RESULTS
    // ==========================================

    // 1. Admit Cards
    async getAdmitCards() {
        console.log('🔄 Syncing Admit Cards...');
        const $ = await this.fetchPage('/admitcard_list.php');
        const cards = [];

        // Iterate main table rows
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;

            // RegNo & Name cell often has formatting: "<strong>REG</strong> - Name<br>Course..."
            const regCell = $(tds[1]);
            const regNo = regCell.find('strong').text().trim();

            // If no regNo, skip (header or garbage)
            if (!regNo) return;

            // Extract Name (text after hyphen)
            const fullText = regCell.text().replace(/\n/g, ' ').trim();
            const nameMatch = fullText.match(/- (.*?)Advance/);
            const name = nameMatch ? nameMatch[1].trim() : '';

            // Modal Scrape
            const modalButton = $(tds[2]).find('button');
            const targetModalId = modalButton.attr('data-target');

            let cardDetails = {};
            if (targetModalId) {
                const modal = $(targetModalId);
                cardDetails = {
                    cardNo: modal.find('input[name="cardno"]').val(),
                    examCentreCode: modal.find('input[name="pexam_address"]').val(),
                    examCentreAddress: modal.find('input[name="texam_address"]').val(),
                    examDate: modal.find('input[name="texam_date"]').val(),
                    examTime: modal.find('input[name="texam_time"]').val(),
                    issueDate: modal.find('input[name="doj"]').val()
                };
            }

            cards.push({
                regNo,
                studentName: name,
                ...cardDetails
            });
        });

        console.log(`✅ Found ${cards.length} admit cards`);
        return cards;
    }

    // 2. Online Exam Results
    async getOnlineExamResults() {
        console.log('🔄 Syncing Online Exam Results...');
        const $ = await this.fetchPage('/result.php');
        const results = [];

        // Table with background colors
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 11) return;
            if ($(tds[0]).text().includes('Sn')) return;

            results.push({
                studentName: $(tds[1]).text().trim(),
                date: $(tds[2]).text().trim(),
                testName: $(tds[3]).text().trim(),
                totalQuestions: $(tds[4]).text().trim(),
                attempted: $(tds[5]).text().trim(),
                correct: $(tds[7]).text().trim(),
                wrong: $(tds[8]).text().trim(),
                totalMarks: $(tds[10]).text().trim()
            });
        });

        console.log(`✅ Found ${results.length} exam results`);
        return results;
    }

    // ==========================================
    // MODULE: STUDY MATERIALS
    // ==========================================

    async getStudyMaterials() {
        console.log('🔄 Syncing Study Materials...');
        const $ = await this.fetchPage('/download.php');
        const materials = [];

        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const program = $(tds[3]).text().trim();
            const subject = $(tds[4]).text().trim();

            // PDF is in a modal iframe
            const modalButton = $(tds[5]).find('button');
            const targetModalId = modalButton.attr('data-target');
            let fileUrl = '';

            if (targetModalId) {
                const modal = $(targetModalId);
                const iframeSrc = modal.find('iframe').attr('src');
                if (iframeSrc) {
                    fileUrl = iframeSrc; // likely relative path "file/..."
                }
            }

            if (title) {
                materials.push({
                    title,
                    program,
                    subject,
                    fileUrl
                });
            }
        });

        console.log(`✅ Found ${materials.length} study materials`);
        return materials;
    }

    async getSyllabus() {
        console.log('🔄 Syncing Syllabus...');
        const $ = await this.fetchPage('/module.php');
        const syllabus = [];

        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const program = $(tds[3]).text().trim();
            const subject = $(tds[4]).text().trim();

            // PDF in modal
            const modalButton = $(tds[5]).find('button');
            const targetModalId = modalButton.attr('data-target');
            let fileUrl = '';

            if (targetModalId) {
                const modal = $(targetModalId);
                const iframeSrc = modal.find('iframe').attr('src');
                if (iframeSrc) fileUrl = iframeSrc;
            }

            if (title) {
                syllabus.push({ title, program, subject, fileUrl });
            }
        });

        console.log(`✅ Found ${syllabus.length} syllabus items`);
        return syllabus;
    }

    // ==========================================
    // MODULE: WEBSITE CMS
    // ==========================================

    async getWebPages() {
        console.log('🔄 Syncing Web Pages...');
        const $ = await this.fetchPage('/page_list.php?country=0');
        const pages = [];

        $('.textli').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 3) return;

            const title = $(tds[1]).text().trim();
            const imgElement = $(tds[2]).find('img');
            const image = imgElement.length ? imgElement.attr('src') : 'No Image';

            pages.push({ title, image });
        });

        console.log(`✅ Found ${pages.length} web pages`);
        return pages;
    }

    async getBanners() {
        console.log('🔄 Syncing Banners...');
        const $ = await this.fetchPage('/banner_list.php?type=1');
        const banners = [];

        // Banners are in nested tables. Look for images directly in the specific structure or by URL pattern.
        $('img[src^="banner/ori/"]').each((i, el) => {
            const src = $(el).attr('src');
            if (src) {
                banners.push({ imageUrl: src });
            }
        });

        console.log(`✅ Found ${banners.length} banners`);
        return banners;
    }

    async getPhotoAlbums() {
        console.log('🔄 Syncing Photo Albums...');
        const $ = await this.fetchPage('/photo_list.php?country=0');
        const albums = [];

        $('.textli').each((i, el) => {
            const tds = $(el).find('td');
            // Expected cols: SNo, Name, Link, Count, Action
            if (tds.length < 3) return;

            const nameLink = $(tds[1]).find('a');
            const albumName = nameLink.text().trim();
            const albumUrl = nameLink.attr('href'); // photo.php?pid=XX

            // Extract count if present (4th column usually)
            const count = $(tds[3]).text().trim();

            if (albumName) {
                albums.push({ albumName, albumUrl, count });
            }
        });

        console.log(`✅ Found ${albums.length} photo albums`);
        return albums;
    }

    async getVideoAlbums() {
        console.log('🔄 Syncing Video Albums...');
        const $ = await this.fetchPage('/video_list.php?country=0');
        const albums = [];

        $('.textli').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 3) return;

            const nameLink = $(tds[1]).find('a');
            const albumName = nameLink.text().trim();
            const albumUrl = nameLink.attr('href'); // video_panel.php?pid=XX

            const count = $(tds[4]).text().trim(); // 5th column based on HTML view

            if (albumName) {
                albums.push({ albumName, albumUrl, count });
            }
        });

        console.log(`✅ Found ${albums.length} video albums`);
        return albums;
    }

    async getNews() {
        console.log('🔄 Syncing News...');
        const $ = await this.fetchPage('/news_list.php?country=0');
        const news = [];

        // Rows have bgcolor attributes
        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 3) return;

            // Skip header row if it matches bgcolor check (headers usually don't have bg color like rows or different)
            // Header had bgcolor="#153450" and Strong tags
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const link = $(tds[2]).find('a').attr('href');

            if (title) {
                news.push({ title, fileUrl: link || '' });
            }
        });

        console.log(`✅ Found ${news.length} news items`);
        return news;
    }

    async getSiteSettings() {
        console.log('🔄 Syncing Site Settings...');
        const $ = await this.fetchPage('/site_setting.php');

        const settings = {};
        $('form input, form textarea').each((i, el) => {
            const key = $(el).attr('name');
            const val = $(el).val();
            if (key) settings[key] = val;
        });

        console.log('✅ Site Settings:', settings);
        return settings;
    }

    // ==========================================
    // PERSISTENCE METHODS
    // ==========================================

    async saveFeeReports(reports) {
        if (!reports.length) return;
        console.log('💾 Saving Fee Reports...');
        for (const r of reports) {
            await db.query(
                `INSERT INTO fee_reports (reg_no, student_name, course, amount, payment_date, payment_mode, txn_id)
                 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [r.regNo, r.name, r.course, parseFloat(r.amount) || 0, r.date, r.payMode, r.txnId]
            );
        }
    }

    async saveBranchWallet(entries) {
        if (!entries.length) return;
        console.log('💾 Saving Branch Wallet...');
        for (const e of entries) {
            await db.query(
                `INSERT INTO branch_wallet (branch_name, amount, txn_date, txn_type, description)
                 VALUES ($1, $2, $3, $4, $5)`,
                [e.branch, parseFloat(e.amount) || 0, e.date, 'DEBIT', e.description]
            );
        }
    }

    async saveAdmitCards(cards) {
        if (!cards.length) return;
        console.log('💾 Saving Admit Cards...');
        for (const c of cards) {
            // Find student ID by RegNo
            const res = await db.query('SELECT id FROM students WHERE registration_number = $1', [c.regNo]);
            const studentId = res.rows[0]?.id || null;

            await db.query(
                `INSERT INTO admit_cards (student_id, exam_name, exam_date, exam_venue, reporting_time)
                 VALUES ($1, $2, $3, $4, $5)`,
                [studentId, 'Term Exam', c.examDate, c.examCentreAddress, c.examTime]
            );
        }
    }

    async saveOnlineResults(results) {
        if (!results.length) return;
        console.log('💾 Saving Online Results...');
        for (const r of results) {
            await db.query(
                `INSERT INTO results (exam_name, exam_date, total_marks, obtained_marks, correct, wrong, total_questions, attempted)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                [r.testName, r.date, parseInt(r.totalMarks) || 0, 0, parseInt(r.correct), parseInt(r.wrong), parseInt(r.totalQuestions), parseInt(r.attempted)]
            );
        }
    }

    async saveStudyMaterials(materials) {
        if (!materials.length) return;
        console.log('💾 Saving Study Materials...');
        for (const m of materials) {
            await db.query(
                `INSERT INTO downloads (title, file_url, program, subject)
                 VALUES ($1, $2, $3, $4)`,
                [m.title, m.fileUrl, m.program, m.subject]
            );
        }
    }

    async saveWebPages(pages) {
        if (!pages.length) return;
        console.log('💾 Saving Web Pages...');
        for (const p of pages) {
            await db.query(
                `INSERT INTO web_pages (title, image_url)
                 VALUES ($1, $2)`,
                [p.title, p.image]
            );
        }
    }

    async saveBanners(banners) {
        if (!banners.length) return;
        console.log('💾 Saving Banners...');
        for (const b of banners) {
            await db.query(
                `INSERT INTO gallery (url, type)
                 VALUES ($1, $2)`,
                [b.imageUrl, 'banner']
            );
        }
    }

    async saveAlbums(albums) {
        if (!albums.length) return;
        console.log('💾 Saving Albums...');
        for (const a of albums) {
            await db.query(
                `INSERT INTO albums (name, url, item_count, type)
                 VALUES ($1, $2, $3, $4)`,
                [a.albumName, a.albumUrl, parseInt(a.count) || 0, a.albumUrl.includes('video') ? 'video' : 'photo']
            );
        }
    }

    async saveNews(news) {
        if (!news.length) return;
        console.log('💾 Saving News...');
        for (const n of news) {
            await db.query(
                `INSERT INTO notices (title, attachment_url)
                 VALUES ($1, $2)`,
                [n.title, n.fileUrl]
            );
        }
    }

    // ==========================================
    // MODULE: MANAGE USER (Admin Users)
    // ==========================================
    async getUsers() {
        console.log('🔄 Syncing Admin Users...');
        const $ = await this.fetchPage('/user_list.php');
        const users = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 6) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const sno = $(tds[0]).text().trim();
            const username = $(tds[1]).text().trim();
            const name = $(tds[2]).text().trim();
            const branch = $(tds[3]).text().trim();
            const password = $(tds[4]).text().trim();
            const permission = $(tds[5]).text().trim();

            if (username) {
                users.push({ sno, username, name, branch, password, permission });
            }
        });

        console.log(`✅ Found ${users.length} admin users`);
        return users;
    }

    // ==========================================
    // MODULE: ONLINE CLASS (Video Classes, Youtube, Zoom)
    // ==========================================
    async getVideoClasses() {
        console.log('🔄 Syncing Video Classes...');
        const $ = await this.fetchPage('/video.php');
        const videos = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const course = $(tds[2]).text().trim();
            const link = $(tds[3]).find('a').attr('href') || '';

            if (title) {
                videos.push({ title, course, link, type: 'video_class' });
            }
        });

        console.log(`✅ Found ${videos.length} video classes`);
        return videos;
    }

    async getYoutubeLiveClasses() {
        console.log('🔄 Syncing Youtube Live Classes...');
        const $ = await this.fetchPage('/youtube_live_class.php');
        const classes = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const course = $(tds[2]).text().trim();
            const link = $(tds[3]).find('a').attr('href') || '';

            if (title) {
                classes.push({ title, course, link, type: 'youtube_live' });
            }
        });

        console.log(`✅ Found ${classes.length} Youtube live classes`);
        return classes;
    }

    async getZoomLiveClasses() {
        console.log('🔄 Syncing Zoom Live Classes...');
        const $ = await this.fetchPage('/zoom_live_class.php');
        const classes = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const title = $(tds[1]).text().trim();
            const meetingId = $(tds[2]).text().trim();
            const passcode = $(tds[3]).text().trim();
            const link = $(tds[4])?.find('a').attr('href') || '';

            if (title) {
                classes.push({ title, meetingId, passcode, link, type: 'zoom_live' });
            }
        });

        console.log(`✅ Found ${classes.length} Zoom live classes`);
        return classes;
    }

    // ==========================================
    // MODULE: INCOMES
    // ==========================================
    async getIncomeHeads() {
        console.log('🔄 Syncing Income Heads...');
        const $ = await this.fetchPage('/income_head.php');
        const heads = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 2) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const name = $(tds[1]).text().trim();
            if (name) heads.push({ name, type: 'income' });
        });

        console.log(`✅ Found ${heads.length} income heads`);
        return heads;
    }

    async getIncomes() {
        console.log('🔄 Syncing Incomes...');
        const $ = await this.fetchPage('/cashin.php?institute=0');
        const incomes = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;
            if ($(tds[0]).text().includes('S.No') || $(tds[0]).text().includes('Total')) return;

            const headName = $(tds[1]).text().trim();
            const amount = $(tds[2]).text().trim();
            const date = $(tds[3]).text().trim();
            const paymentMode = $(tds[4]).text().trim();

            if (headName && amount) {
                incomes.push({ headName, amount, date, paymentMode, type: 'income' });
            }
        });

        console.log(`✅ Found ${incomes.length} income records`);
        return incomes;
    }

    // ==========================================
    // MODULE: EXPENSES
    // ==========================================
    async getExpenseHeads() {
        console.log('🔄 Syncing Expense Heads...');
        const $ = await this.fetchPage('/head.php');
        const heads = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 2) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const name = $(tds[1]).text().trim();
            if (name) heads.push({ name, type: 'expense' });
        });

        console.log(`✅ Found ${heads.length} expense heads`);
        return heads;
    }

    async getExpenses() {
        console.log('🔄 Syncing Expenses...');
        const $ = await this.fetchPage('/cashout.php?institute=0');
        const expenses = [];

        $('tr[bgcolor]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;
            if ($(tds[0]).text().includes('S.No') || $(tds[0]).text().includes('Total')) return;

            const headName = $(tds[1]).text().trim();
            const amount = $(tds[2]).text().trim();
            const date = $(tds[3]).text().trim();
            const paymentMode = $(tds[4]).text().trim();

            if (headName && amount) {
                expenses.push({ headName, amount, date, paymentMode, type: 'expense' });
            }
        });

        console.log(`✅ Found ${expenses.length} expense records`);
        return expenses;
    }

    // ==========================================
    // MODULE: SUGGESTION BOX
    // ==========================================
    async getSuggestions() {
        console.log('🔄 Syncing Suggestions...');
        const $ = await this.fetchPage('/suggestions.php');
        const suggestions = [];

        $('tr[bgcolor], tr[style*="background"]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 5) return;
            if ($(tds[0]).text().includes('SN')) return;

            const date = $(tds[1]).text().trim();
            const suggestion = $(tds[2]).text().trim();
            const description = $(tds[3]).text().trim();
            const file = $(tds[4]).find('a').attr('href') || '';
            const centre = $(tds[5])?.text().trim() || '';

            if (suggestion) {
                suggestions.push({ date, suggestion, description, file, centre });
            }
        });

        console.log(`✅ Found ${suggestions.length} suggestions`);
        return suggestions;
    }

    // ==========================================
    // MODULE: STAFF/EMP - FULL SUBSECTIONS
    // ==========================================
    async getEmployeeDepartments() {
        console.log('🔄 Syncing Employee Departments...');
        const $ = await this.fetchPage('/emp_dep.php');
        const departments = [];

        $('tr[bgcolor], tr[style*="background"]').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 2) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const name = $(tds[1]).text().trim();
            if (name) departments.push({ name });
        });

        console.log(`✅ Found ${departments.length} employee departments`);
        return departments;
    }

    async getAttendanceReport() {
        console.log('🔄 Syncing Attendance Report...');
        const $ = await this.fetchPage('/attendance.php');
        const records = [];

        $('tr[bgcolor], tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No') || $(tds[0]).text().includes('Date')) return;

            const empName = $(tds[0]).text().trim();
            const date = $(tds[1]).text().trim();
            const status = $(tds[2]).text().trim(); // Present/Absent
            const inTime = $(tds[3]).text().trim();
            const outTime = $(tds[4])?.text().trim() || '';

            if (empName && date) {
                records.push({ empName, date, status, inTime, outTime });
            }
        });

        console.log(`✅ Found ${records.length} attendance records`);
        return records;
    }

    async getAdvanceReport() {
        console.log('🔄 Syncing Advance Report...');
        const $ = await this.fetchPage('/advance_list.php');
        const advances = [];

        $('tr[bgcolor], tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No')) return;

            const empName = $(tds[1]).text().trim();
            const amount = $(tds[2]).text().trim();
            const date = $(tds[3]).text().trim();
            const status = $(tds[4])?.text().trim() || '';

            if (empName && amount) {
                advances.push({ empName, amount, date, status });
            }
        });

        console.log(`✅ Found ${advances.length} advance records`);
        return advances;
    }

    // ==========================================
    // MODULE: ONLINE EXAM - FULL SUBSECTIONS
    // ==========================================
    async getPaperSets() {
        console.log('🔄 Syncing Paper Sets (PAGINATED)...');

        const allPapers = [];
        let start = 0;
        const pageSize = 10;
        let hasMore = true;

        while (hasMore) {
            console.log(`   📄 Fetching paper sets starting at ${start}...`);
            const $ = await this.fetchPage(`/paper_list.php?start=${start}&pagecounter=${pageSize}`);

            let pageCount = 0;

            $('tr[bgcolor], tr').each((i, el) => {
                const tds = $(el).find('td');
                if (tds.length < 4) return;
                if ($(tds[0]).text().includes('S.No')) return;

                const title = $(tds[1]).text().trim();
                const course = $(tds[2]).text().trim();
                const subject = $(tds[3]).text().trim();
                const totalQuestions = $(tds[4])?.text().trim() || '';
                const duration = $(tds[5])?.text().trim() || '';

                if (title) {
                    allPapers.push({ title, course, subject, totalQuestions, duration });
                    pageCount++;
                }
            });

            console.log(`   ✅ Page ${start / pageSize + 1}: Found ${pageCount} papers`);

            if (pageCount === 0) {
                hasMore = false;
            } else {
                start += pageSize;
                if (start > 500) hasMore = false;
            }
        }

        console.log(`✅ Total: Found ${allPapers.length} paper sets`);
        return allPapers;
    }

    async getQuestions() {
        console.log('🔄 Syncing Exam Questions...');
        const $ = await this.fetchPage('/product_list.php');
        const questions = [];

        $('tr[bgcolor], tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No') || $(tds[0]).text().includes('Question')) return;

            const question = $(tds[1]).text().trim();
            const optionA = $(tds[2])?.text().trim() || '';
            const optionB = $(tds[3])?.text().trim() || '';
            const optionC = $(tds[4])?.text().trim() || '';
            const optionD = $(tds[5])?.text().trim() || '';
            const correctAnswer = $(tds[6])?.text().trim() || '';

            if (question && question.length > 5) {
                questions.push({ question, optionA, optionB, optionC, optionD, correctAnswer });
            }
        });

        console.log(`✅ Found ${questions.length} exam questions`);
        return questions;
    }

    // ==========================================
    // MODULE: REPORT - FULL SUBSECTIONS
    // ==========================================
    async getStudentReport() {
        console.log('🔄 Syncing Student Report...');
        const $ = await this.fetchPage('/members.php');
        const report = [];

        $('tr[bgcolor], tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 4) return;
            if ($(tds[0]).text().includes('S.No') || $(tds[0]).text().includes('REG')) return;

            const regNo = $(tds[0]).text().trim().split(/\s+/)[0];
            const name = $(tds[1]).text().trim();
            const course = $(tds[2]).text().trim();
            const status = $(tds[3]).text().trim();

            if (regNo && regNo.length > 5) {
                report.push({ regNo, name, course, status });
            }
        });

        console.log(`✅ Found ${report.length} student report entries`);
        return report;
    }

    async getBalanceSheet() {
        console.log('🔄 Syncing Balance Sheet...');
        const $ = await this.fetchPage('/both_report.php');

        // Balance sheet usually has income vs expense summary
        let totalIncome = 0;
        let totalExpense = 0;
        let balance = 0;

        // Try to extract summary values
        $('strong, b, .total').each((i, el) => {
            const text = $(el).text().trim();
            if (text.includes('Income') || text.includes('Receipt')) {
                const match = text.match(/[\d,]+/);
                if (match) totalIncome = parseInt(match[0].replace(/,/g, '')) || 0;
            }
            if (text.includes('Expense') || text.includes('Payment')) {
                const match = text.match(/[\d,]+/);
                if (match) totalExpense = parseInt(match[0].replace(/,/g, '')) || 0;
            }
        });

        balance = totalIncome - totalExpense;

        console.log(`✅ Balance Sheet: Income=${totalIncome}, Expense=${totalExpense}, Balance=${balance}`);
        return { totalIncome, totalExpense, balance };
    }

    // ==========================================
    // MODULE: BRANCHES
    // ==========================================
    async getBranches() {
        console.log('🔄 Syncing Branches...');
        const $ = await this.fetchPage('/branch.php');

        const branches = [];
        $('table tr').each((i, el) => {
            const tds = $(el).find('td');
            if (tds.length < 3) return;

            // Look for details column (usually index 1)
            // But we need to check if it's the right table
            if ($(tds[0]).find('img').length === 0) return;

            // Extract using text content parsing
            // Structure: Name <br> Code : GOKUL <br> Address : ...
            const content = $(tds[1]).html() || '';
            const parts = content.split('<br>');

            // Extract raw text for safety
            const fullText = $(tds[1]).text();

            // Name is usually in strong tag at start
            const name = $(tds[1]).find('strong').first().text().trim();

            // Parsing code and address from text
            const codeMatch = fullText.match(/Code\s*:\s*([^A-ZAddr]+)/i);
            const addressMatch = fullText.match(/Address\s*:\s*(.+)$/i);

            // Fallback parsing if regex fails
            const code = codeMatch ? codeMatch[1].trim() : '';
            const address = addressMatch ? addressMatch[1].trim() : '';

            branches.push({
                name: name,
                code: code,
                address: address,
                image: $(tds[0]).find('img').attr('src')
            });
        });

        console.log(`✅ Found ${branches.length} branches`);
        return branches;
    }

    // MODULE 1: STUDENTS (Tab 8 in Sidebar)
    // ==========================================

    async getStudents() {
        console.log('🔄 Syncing Students (ENHANCED + PAGINATED)...');

        const allStudents = [];
        let start = 0;
        const pageSize = 50;
        let hasMore = true;

        while (hasMore) {
            console.log(`   📄 Fetching page starting at ${start}...`);
            const $ = await this.fetchPage(`/search_home.php?start=${start}&pagecounter=${pageSize}`);

            let pageStudents = 0;

            // Find all student rows (not header, not nested tables)
            $('div#suggesstion-box table.table tr').each((index, element) => {
                const tds = $(element).find('> td');
                if (tds.length < 6) return;

                const col0Text = $(tds[0]).text().trim();
                // Skip header row
                if (col0Text.includes('REG') || col0Text.includes('SNO')) return;

                // Parse RegNo and Password from first column
                // Format: "GO100110020241760126\n9335848463"
                const col0Lines = col0Text.split(/\s+/);
                const regNo = col0Lines[0];
                const password = col0Lines[1] || '';

                if (!regNo || regNo.length < 5) return;

                // Basic row data
                const name = $(tds[1]).find('strong').first().text().trim();
                const course = $(tds[2]).find('strong').text().trim();
                const contact = $(tds[3]).text().trim();

                // Fee status: "PAID" or "5700 Pay"
                const feeCell = $(tds[4]);
                const feeText = feeCell.text().trim();
                const isPaid = feeText.includes('PAID');
                const dueAmount = isPaid ? 0 : parseInt(feeText.replace(/[^0-9]/g, '')) || 0;

                // Action column contains modal trigger button
                const actionTd = $(tds[5]);
                const modalButton = actionTd.find('button[data-target]');
                const modalId = modalButton.attr('data-target'); // e.g., #exampleModal191

                // Action links
                const printLink = actionTd.find('a[href*="print_form"]').attr('href') || '';
                const uploadLink = actionTd.find('a[href*="upload_documents"]').attr('href') || '';
                const editLink = actionTd.find('a[href*="members_add"]').attr('href') || '';
                const studentId = editLink.match(/edit=(\d+)/)?.[1] || '';

                // Parse modal for extra details
                let modalData = {
                    netFee: 0,
                    fatherName: '',
                    doj: '',
                    batch: '',
                    address: '',
                    updatedBy: '',
                    feePayments: []
                };

                if (modalId) {
                    const modal = $(modalId);
                    modal.find('.modal-body table tr').each((i, tr) => {
                        const cells = $(tr).find('td');
                        if (cells.length >= 2) {
                            const label = $(cells[0]).text().trim().toLowerCase();
                            const value = $(cells[1]).text().trim();

                            if (label.includes('net fee')) modalData.netFee = parseInt(value) || 0;
                            if (label.includes('father')) modalData.fatherName = value;
                            if (label.includes('doj')) modalData.doj = value;
                            if (label.includes('batch')) modalData.batch = value;
                            if (label.includes('address')) modalData.address = value;
                            if (label.includes('updated')) modalData.updatedBy = value;
                        }
                    });
                }

                pageStudents++;
                allStudents.push({
                    id: studentId,
                    regNo: regNo,
                    password: password,
                    name: name,
                    course: course,
                    contact: contact,
                    feeStatus: isPaid ? 'PAID' : 'DUE',
                    dueAmount: dueAmount,
                    netFee: modalData.netFee,
                    fatherName: modalData.fatherName,
                    doj: modalData.doj,
                    batch: modalData.batch,
                    address: modalData.address,
                    updatedBy: modalData.updatedBy,
                    printUrl: printLink,
                    uploadDocUrl: uploadLink,
                    editUrl: editLink
                });
            });

            console.log(`   ✅ Page ${start / pageSize + 1}: Found ${pageStudents} students`);

            // Check if this page had students, if not we've reached the end
            if (pageStudents === 0) {
                hasMore = false;
            } else {
                start += pageSize;
                // Safety limit: max 20 pages (1000 students)
                if (start > 1000) hasMore = false;
            }
        }

        console.log(`✅ Total: Found ${allStudents.length} students with full details`);

        if (allStudents.length > 0) {
            await this.saveStudentsEnhanced(allStudents);
        }

        return allStudents;
    }

    // Enhanced save that includes all new fields
    async saveStudentsEnhanced(students) {
        console.log('💾 Saving enhanced student data...');
        let savedCount = 0;
        for (const s of students) {
            try {
                // Also fill old columns (registration_number, password_hash) for backwards compatibility
                await db.query(
                    `INSERT INTO students(registration_number, password_hash, reg_no, password, name, course, phone, fee_status, due_amount, net_fee, father_name, doj, batch, address, updated_by)
VALUES($1, $2, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
                     ON CONFLICT(registration_number) DO UPDATE SET
reg_no = EXCLUDED.reg_no,
    password = EXCLUDED.password,
    password_hash = EXCLUDED.password_hash,
    name = EXCLUDED.name,
    course = EXCLUDED.course,
    phone = EXCLUDED.phone,
    fee_status = EXCLUDED.fee_status,
    due_amount = EXCLUDED.due_amount,
    net_fee = EXCLUDED.net_fee,
    father_name = EXCLUDED.father_name,
    doj = EXCLUDED.doj,
    batch = EXCLUDED.batch,
    address = EXCLUDED.address,
    updated_by = EXCLUDED.updated_by`,
                    [s.regNo, s.password, s.name, s.course, s.contact, s.feeStatus, s.dueAmount, s.netFee, s.fatherName, s.doj, s.batch, s.address, s.updatedBy]
                );
                savedCount++;
            } catch (e) {
                console.error(`❌ Error saving ${s.regNo}: `, e.message);
            }
        }
        console.log(`✅ Saved / Updated ${savedCount} students`);
    }

    async saveStudents(students) {
        console.log('💾 Saving students to database...');
        let savedCount = 0;

        for (const student of students) {
            try {
                // Formatting phone to fit VARCHAR(20)
                const safePhone = (student.phone || '').replace(/[^0-9]/g, '').substring(0, 20);
                const fatherName = student.fatherName || '';

                // Upsert logic
                await db.query(
                    `INSERT INTO students(registration_number, name, father_name, course_id, phone, password_hash)
VALUES($1, $2, $3, 0, $4, 'default_hash')
                     ON CONFLICT(registration_number)
                     DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone`,
                    [student.regNo, student.name, fatherName, safePhone]
                );
                savedCount++;
            } catch (e) {
                console.error(`❌ Error saving ${student.regNo}: `);
                console.error(e);
            }
        }
        console.log(`✅ Saved / Updated ${savedCount} students`);
    }
}

module.exports = new SyncService();
