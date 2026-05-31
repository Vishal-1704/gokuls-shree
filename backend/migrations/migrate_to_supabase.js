/**
 * GOKUL SHREE SCHOOL — Data Migration Script
 * Reads the legacy MySQL SQL dump and pushes all data
 * into the new restructured Supabase/PostgreSQL schema.
 *
 * Run: node migrate_to_supabase.js
 * Requires: npm install @supabase/supabase-js dotenv
 */

require('dotenv').config({ path: '../.env' });
const fs   = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// ─── Supabase client (use SERVICE_ROLE key for migrations) ─────────────────
// Add SUPABASE_SERVICE_KEY to your .env for migration.
// Normal anon key won't bypass RLS.
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
);

const SQL_FILE = path.join(__dirname, '../../madhepuradiet_gokulshreeschool (1).sql');

// ─── Helpers ────────────────────────────────────────────────────────────────
function readSQL() {
  return fs.readFileSync(SQL_FILE, 'latin1');
}

/** Extract all INSERT rows for a given table from the SQL dump */
function extractTableData(sql, tableName) {
  const rows = [];
  const blockRx = new RegExp(
    `INSERT INTO \`${tableName}\`[\\s\\S]+?;\\r?\\n`,
    'gi'
  );
  const blocks = sql.match(blockRx) || [];

  for (const block of blocks) {
    const colMatch = block.match(/\(([^)]+)\)\s+VALUES/i);
    if (!colMatch) continue;
    const cols = colMatch[1]
      .split(',')
      .map(c => c.trim().replace(/`/g, ''));

    const valuesStartIndex = block.toUpperCase().indexOf('VALUES') + 6;
    const valueSection = block.substring(valuesStartIndex);

    // State machine to extract tuples
    const tuples = [];
    let currentTuple = '';
    let inString = false;
    let escape = false;
    let parenDepth = 0;

    for (let i = 0; i < valueSection.length; i++) {
      const c = valueSection[i];

      if (parenDepth === 0) {
        if (c === '(') {
          parenDepth = 1;
          currentTuple = '';
        }
        continue;
      }

      // Inside a tuple
      if (escape) {
        currentTuple += c;
        escape = false;
        continue;
      }

      if (c === '\\') {
        currentTuple += c;
        escape = true;
        continue;
      }

      if (c === "'") {
        currentTuple += c;
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (c === '(') {
          parenDepth++;
        } else if (c === ')') {
          parenDepth--;
          if (parenDepth === 0) {
            tuples.push(currentTuple);
            continue;
          }
        }
      }

      currentTuple += c;
    }

    for (const t of tuples) {
      const vals = smartSplit(t);
      if (vals.length !== cols.length) continue;
      const obj = {};
      cols.forEach((col, i) => {
        let v = vals[i].trim();
        if (v === 'NULL' || v === "''") {
          obj[col] = null;
        } else if (v.startsWith("'") && v.endsWith("'")) {
          obj[col] = v.slice(1, -1)
            .replace(/\\'/g, "'")
            .replace(/\\"/g, '"')
            .replace(/\\\\/g, '\\')
            .replace(/\\r\\n/g, '\n')
            .replace(/\\n/g, '\n');
        } else {
          const n = parseFloat(v);
          obj[col] = isNaN(n) ? v : n;
        }
      });
      rows.push(obj);
    }
  }
  return rows;
}

/** Split a CSV values string respecting quoted strings */
function smartSplit(str) {
  const parts = [];
  let cur = '', inQ = false, qc = '';
  for (let i = 0; i < str.length; i++) {
    const c = str[i];
    if (!inQ && (c === "'" || c === '"')) { inQ = true; qc = c; cur += c; }
    else if (inQ && c === qc && str[i - 1] !== '\\') { inQ = false; cur += c; }
    else if (!inQ && c === ',') { parts.push(cur.trim()); cur = ''; }
    else { cur += c; }
  }
  if (cur.trim()) parts.push(cur.trim());
  return parts;
}

/** Batch upsert to Supabase */
async function upsert(table, rows, chunkSize = 50, conflictCol = 'legacy_id') {
  if (!rows.length) { console.log(`  ⏭  ${table}: no rows`); return 0; }
  let inserted = 0;
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    const { error } = await supabase.from(table).upsert(chunk, { onConflict: conflictCol });
    if (error) {
      console.error(`  ❌ ${table} chunk ${i}-${i + chunkSize}:`, error.message);
    } else {
      inserted += chunk.length;
    }
  }
  console.log(`  ✅ ${table}: ${inserted}/${rows.length} rows`);
  return inserted;
}

// ─── Transform functions ─────────────────────────────────────────────────────

function transformBranches(rows) {
  return rows.map(r => ({
    legacy_id:   r.id,
    name:        r.name        || r.bname || '',
    owner_name:  r.owner       || r.oname || '',
    contact:     r.mobile      || r.contact || '',
    email:       r.email       || '',
    address:     r.address     || '',
    city:        r.city        || '',
    state:       r.state       || '',
    pincode:     String(r.pincode || ''),
    bank_name:   r.bank        || r.bank_name || '',
    bank_acc_no: r.accno       || r.account_no || '',
    bank_ifsc:   r.ifsc        || '',
    pan_no:      r.pan         || '',
    status:      r.status ?? 1,
  }));
}

function transformCourses(rows) {
  return rows.map(r => ({
    legacy_id:   r.id,
    name:        r.courses     || r.name || '',
    short_name:  r.code        || r.short_name || r.sname || '',
    duration:    r.duration    || '',
    fee:         parseFloat(r.fee || r.fees || 0) || 0,
    category:    r.category    || r.type || 'General',
    total_marks: parseInt(r.total_marks || r.marks || 0) || 0,
    pass_marks:  parseInt(r.pass_marks  || 0) || 0,
    status:      r.status ?? 1,
  }));
}

function transformSubjects(rows) {
  return rows.map(r => ({
    legacy_id:   r.id,
    course_id:   null,              // resolved by legacy_id after courses inserted
    legacy_course_id: parseInt(r.cid) || null,
    name:        r.name  || '',
    code:        r.code  || '',
    total_marks: parseInt(r.total || 100) || 100,
    pass_marks:  parseInt(r.passing || 33) || 33,
    status:      parseInt(r.status) || 1,
  }));
}

function transformStudents(rows) {
  return rows.map(r => ({
    legacy_id:      r.id,
    reg_no:         r.regsno      || '',
    adm_no:         r.admno       || r.serialno || '',
    roll_no:        r.rollno      || '',
    name:           r.name        || '',
    father_name:    r.father      || '',
    mother_name:    r.mother      || '',
    gender:         r.gender      || '',
    dob:            r.dob || null,
    religion:       r.religion    || '',
    category:       r.category    || '',
    marital_status: r.marital     || '',
    disability:     r.disability  || 'No',
    occupation:     r.occupation  || '',
    contact:        String(r.contact || r.username || ''),
    father_contact: String(r.fcontact || ''),
    email:          r.email       || '',
    address:        r.address     || '',
    temp_address:   r.taddress    || '',
    state_code:     parseInt(r.state) || null,
    district_code:  parseInt(r.district) || null,
    pincode:        parseInt(r.pincode) || null,
    identity_type:  r.identity_type || '',
    id_number:      r.idnumber    || '',
    aadhar:         r.adhar       || '',
    qualification:  r.qui         || '',
    passing_year:   r.passingyear || '',
    session:        r.asession    || '',
    medium:         r.medium      || '',
    batch_time:     String(r.btime || ''),
    doj:            r.doj || null,
    dol:            r.dol || null,
    course_fee:     parseFloat(r.fee  || 0) || 0,
    reg_fee:        parseFloat(r.regfee || 0) || 0,
    admin_fee:      parseFloat(r.adminfee || 0) || 0,
    discount:       parseFloat(r.discount || 0) || 0,
    enquiry_source: r.enquiry_source || r.refer || '',
    remarks:        r.remarks     || '',
    photo_url:      r.photo       || '',
    signature_url:  r.signature   || '',
    id_proof_url:   r.idproof     || '',
    qual_proof_url: r.qualification_proof || '',
    id_card_issued: (parseInt(r.card) || 0) === 1,
    status:         parseInt(r.status) ?? 1,
    legacy_branch_id: parseInt(r.branch) || 1,
    legacy_course_id: parseInt(r.courses) || null,
    type:           parseInt(r.type) || 1,
  }));
}

function transformFees(rows) {
  return rows.map(r => ({
    legacy_id:       r.id,
    receipt_no:      String(r.receipt || ''),
    payment_date:    r.dated    || null,
    next_due_date:   r.nextdate === '0000-00-00' ? null : (r.nextdate || null),
    amount:          parseFloat(r.depfee || 0) || 0,
    net_pay:         parseFloat(r.netpay || 0) || 0,
    discount:        parseFloat(r.disc || 0) || 0,
    fine:            parseFloat(r.fine || 0) || 0,
    other_charges:   parseFloat(r.other || 0) || 0,
    payment_mode:    r.cheque ? 'CHEQUE' : 'CASH',
    cheque_no:       r.cheque || '',
    description:     r.descr  || '',
    legacy_student_id: parseInt(r.sid) || null,
    legacy_branch_id:  parseInt(r.branch) || 1,
  }));
}

function transformAttendance(rows) {
  return rows.map(r => ({
    legacy_id:        r.id,
    attendance_date:  r.adate || null,
    status:           r.atype == '1' ? 'P' : r.atype == '2' ? 'L' : 'A',
    month:            parseInt(r.amonth) || null,
    year:             parseInt(r.ayear)  || null,
    legacy_student_id: parseInt(r.sid) || null,
  }));
}

function transformMarksheets(rows) {
  return rows.map(r => {
    const theoryScores = (r.theory || '').split('~').filter(x => x !== '');
    const marks = { subjects: theoryScores.map((t, i) => ({
      index: i,
      theory: parseInt(t) || 0,
    }))};
    const total = theoryScores.reduce((s, t) => s + (parseInt(t) || 0), 0);
    const maxMarks = theoryScores.length * 100;
    const pct = maxMarks > 0 ? ((total / maxMarks) * 100).toFixed(2) : 0;
    return {
      legacy_id:          r.id,
      roll_no:            r.roll          || '',
      session:            r.csession      || '',
      exam_mode:          parseInt(r.exam_mode) || 1,
      marks:              marks,
      total_marks:        maxMarks,
      obtained_marks:     total,
      percentage:         parseFloat(pct),
      grade:              pct >= 80 ? 'A' : pct >= 60 ? 'B' : pct >= 40 ? 'C' : 'D',
      result:             parseInt(r.status) === 1 ? 'PASS' : 'FAIL',
      marksheet_sl_no:    r.mslno         || '',
      certificate_sl_no:  r.cslno         || '',
      issue_date:         r.issue === '0000-00-00' ? null : (r.issue || null),
      marksheet_month:    r.mmonth        || '',
      marksheet_year:     r.myear         || '',
      certificate_month:  r.cmonth        || '',
      certificate_year:   r.cyear         || '',
      status:             parseInt(r.status) || 0,
      fee_paid:           (r.fee && r.fee !== '') ? true : false,
      legacy_course_id:   parseInt(r.cid) || null,
      legacy_student_roll: r.roll         || '',
    };
  });
}

function transformExamCategories(rows) {
  return rows.map(r => ({
    legacy_id:       r.id,
    name:            r.name           || r.catname || '',
    total_marks:     parseInt(r.marks || r.total_marks || 100) || 100,
    pass_marks:      parseInt(r.pass_marks || 33) || 33,
    time_limit:      parseInt(r.time  || 60) || 60,
    total_questions: parseInt(r.questions || r.no_of_questions || 20) || 20,
    status:          parseInt(r.status ?? 1) || 1,
  }));
}

function transformExamResults(rows) {
  return rows.map(r => ({
    legacy_id:           r.id,
    questions_attempted: (r.q_id || '').split(',').filter(Boolean),
    answers_given:       (r.ans  || '').split(',').filter(Boolean),
    score:               0,  // recalculate from questions if needed
    time_taken:          parseInt(r.timetaken) || 0,
    legacy_student_id:   parseInt(r.user) || null,
    legacy_category_id:  parseInt(r.cat_id) || null,
    attempted_at:        r.date || null,
    legacy_branch_id:    parseInt(r.branch) || 1,
  }));
}

function transformAdmitCards(rows) {
  return rows.map(r => ({
    legacy_id:         r.id,
    roll_no:           r.rollno     || '',
    exam_date:         r.examdate   || r.exam_date || null,
    exam_center:       r.center     || r.ecenter || '',
    exam_city:         r.city       || '',
    session:           r.session    || r.csession || '',
    issued_date:       r.issdate    || null,
    status:            parseInt(r.status ?? 1),
    legacy_student_id: parseInt(r.sid || r.memberid) || null,
    legacy_branch_id:  parseInt(r.branch) || 1,
  }));
}

function transformStates(rows) {
  return rows.map(r => ({
    code: parseInt(r.StCode),
    name: r.StateName || '',
  }));
}

function transformNotices(rows) {
  return rows.map(r => ({
    legacy_id:   r.id,
    title:       r.title    || r.heading || '',
    content:     r.content  || r.description || r.body || '',
    type:        'general',
    is_public:   true,
    published_at: r.date    || r.created_at || new Date().toISOString(),
  }));
}

function transformDownloads(rows) {
  return rows.map(r => ({
    legacy_id: r.id,
    title:     r.title   || r.name || '',
    file_url:  r.file    || r.filepath || '',
    category:  r.type    || r.category || 'general',
    is_public: true,
  }));
}

// ─── Main migration ──────────────────────────────────────────────────────────
async function migrate() {
  console.log('\n🚀 GOKUL SHREE — Supabase Migration Starting...\n');
  console.log('📂 Reading SQL file...');
  const sql = readSQL();
  console.log(`   SQL file size: ${(sql.length / 1024 / 1024).toFixed(2)} MB\n`);

  // ── Step 1: States ──────────────────────────────────────────────────────
  console.log('📍 Step 1: States');
  const stateRows = extractTableData(sql, 'state');
  await upsert('states', transformStates(stateRows), 50, 'code');

  // ── Step 2: Branches ────────────────────────────────────────────────────
  console.log('\n🏫 Step 2: Branches');
  const branchRows = extractTableData(sql, 'branch');
  await upsert('branches', transformBranches(branchRows));

  // Fetch inserted branches to build legacy_id → new_id map
  const { data: branches } = await supabase.from('branches').select('id,legacy_id');
  const branchMap = {};
  (branches || []).forEach(b => { branchMap[b.legacy_id] = b.id; });
  console.log(`   Branch map built: ${Object.keys(branchMap).length} branches`);

  // ── Step 3: Courses ─────────────────────────────────────────────────────
  console.log('\n📚 Step 3: Courses');
  const courseRows = extractTableData(sql, 'courses');
  await upsert('courses', transformCourses(courseRows));

  const { data: courses } = await supabase.from('courses').select('id,legacy_id');
  const courseMap = {};
  (courses || []).forEach(c => { courseMap[c.legacy_id] = c.id; });
  console.log(`   Course map built: ${Object.keys(courseMap).length} courses`);

  // ── Step 4: Subjects ────────────────────────────────────────────────────
  console.log('\n📖 Step 4: Subjects');
  const subjectRows = extractTableData(sql, 'subject');
  const subjects = transformSubjects(subjectRows).map(s => {
    const copy = {
      ...s,
      course_id: courseMap[s.legacy_course_id] || null,
    };
    delete copy.legacy_course_id;
    return copy;
  });
  await upsert('subjects', subjects);

  // ── Step 5: Students ────────────────────────────────────────────────────
  console.log('\n🎓 Step 5: Students');
  const memberRows = extractTableData(sql, 'members');
  const studentData = transformStudents(memberRows).map(s => {
    const copy = {
      ...s,
      branch_id: branchMap[s.legacy_branch_id] || null,
      course_id: courseMap[s.legacy_course_id] || null,
    };
    delete copy.legacy_branch_id;
    delete copy.legacy_course_id;
    return copy;
  });
  await upsert('students', studentData);

  const { data: students } = await supabase.from('students').select('id,legacy_id');
  const studentMap = {};
  (students || []).forEach(s => { studentMap[s.legacy_id] = s.id; });
  console.log(`   Student map built: ${Object.keys(studentMap).length} students`);

  // ── Step 6: Fee Payments ─────────────────────────────────────────────────
  console.log('\n💰 Step 6: Fee Payments');
  const feeRows = extractTableData(sql, 'fees');
  const fees = transformFees(feeRows).map(f => {
    const copy = {
      ...f,
      student_id: studentMap[f.legacy_student_id] || null,
      branch_id:  branchMap[f.legacy_branch_id]   || null,
    };
    delete copy.legacy_student_id;
    delete copy.legacy_branch_id;
    return copy;
  });
  await upsert('fee_payments', fees);

  // ── Step 7: Student Attendance ──────────────────────────────────────────
  console.log('\n📅 Step 7: Student Attendance');
  const attRows = extractTableData(sql, 'sattdance');
  const attendance = transformAttendance(attRows).map(a => {
    const copy = {
      ...a,
      student_id: studentMap[a.legacy_student_id] || null,
    };
    delete copy.legacy_student_id;
    return copy;
  });
  await upsert('student_attendance', attendance);

  // ── Step 8: Marksheets ───────────────────────────────────────────────────
  console.log('\n📋 Step 8: Marksheets');
  const msRows = extractTableData(sql, 'marksheet');
  // Match students by roll_no since marksheet links via roll
  const { data: allStudents } = await supabase.from('students').select('id,reg_no,legacy_id');
  const studentByRegNo = {};
  (allStudents || []).forEach(s => { studentByRegNo[s.reg_no] = s.id; });

  const marksheets = transformMarksheets(msRows).map(m => {
    const copy = {
      ...m,
      student_id:       studentByRegNo[m.legacy_student_roll] || null,
      course_id:        courseMap[m.legacy_course_id] || null,
    };
    delete copy.legacy_course_id;
    delete copy.legacy_student_roll;
    return copy;
  });
  await upsert('marksheets', marksheets);

  // ── Step 9: Exam Categories ──────────────────────────────────────────────
  console.log('\n📝 Step 9: Exam Categories');
  const catRows = extractTableData(sql, 'category');
  await upsert('exam_categories', transformExamCategories(catRows));

  const { data: examCats } = await supabase.from('exam_categories').select('id,legacy_id');
  const catMap = {};
  (examCats || []).forEach(c => { catMap[c.legacy_id] = c.id; });

  // ── Step 10: Exam Results ────────────────────────────────────────────────
  console.log('\n🏆 Step 10: Exam Results (Online Tests)');
  const resultRows = extractTableData(sql, 'final_result');
  const results = transformExamResults(resultRows).map(r => {
    const copy = {
      ...r,
      student_id:         studentMap[r.legacy_student_id] || null,
      category_id:        catMap[r.legacy_category_id]    || null,
      branch_id:          branchMap[r.legacy_branch_id]   || null,
    };
    delete copy.legacy_student_id;
    delete copy.legacy_category_id;
    delete copy.legacy_branch_id;
    return copy;
  });
  await upsert('exam_results', results);

  // ── Step 11: Admit Cards ─────────────────────────────────────────────────
  console.log('\n🎫 Step 11: Admit Cards');
  const admitRows = extractTableData(sql, 'admitcard');
  const admitCards = transformAdmitCards(admitRows).map(a => {
    const copy = {
      ...a,
      student_id:       studentMap[a.legacy_student_id] || null,
      branch_id:        branchMap[a.legacy_branch_id]   || null,
    };
    delete copy.legacy_student_id;
    delete copy.legacy_branch_id;
    return copy;
  });
  await upsert('admit_cards', admitCards);

  // ── Step 12: Notices ─────────────────────────────────────────────────────
  console.log('\n📣 Step 12: Notices / News');
  const newsRows = extractTableData(sql, 'news');
  await upsert('notices', transformNotices(newsRows));

  // ── Step 13: Downloads ───────────────────────────────────────────────────
  console.log('\n📎 Step 13: Downloads');
  const dlRows = extractTableData(sql, 'download');
  await upsert('downloads', transformDownloads(dlRows));

  // ── Summary ──────────────────────────────────────────────────────────────
  console.log('\n' + '='.repeat(55));
  console.log('✅  MIGRATION COMPLETE!');
  console.log('='.repeat(55));
  console.log(`
  Tables migrated:
    branches         : ${branchRows.length}
    courses          : ${courseRows.length}
    subjects         : ${subjectRows.length}
    students         : ${memberRows.length}
    fee_payments     : ${feeRows.length}
    student_attendance: ${attRows.length}
    marksheets       : ${msRows.length}
    exam_categories  : ${catRows.length}
    exam_results     : ${resultRows.length}
    admit_cards      : ${admitRows.length}
    notices          : ${newsRows.length}
    downloads        : ${dlRows.length}
    states           : ${stateRows.length}
  `);
}

migrate().catch(err => {
  console.error('\n💥 Migration failed:', err.message);
  process.exit(1);
});
