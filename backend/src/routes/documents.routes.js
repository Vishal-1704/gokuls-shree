/**
 * DOCUMENTS ROUTES — Bulletproof
 * Marksheets, Certificates, Admit Cards, ID Cards
 *
 * CRITICAL APPROVAL WORKFLOW:
 *   branch_admin submits marksheet  → status = 0 (PENDING)
 *   super_admin approves            → status = 1 (APPROVED)
 *   student can download            → only if status = 1
 *
 *   Students can NEVER see pending (status=0) marksheets.
 *   Only super_admin can approve — enforced at route level.
 */
const router = require('express').Router();
const { supabase }                              = require('../config/supabase');
const { requireAuth }                           = require('../middleware/auth.middleware');
const { requirePermission, strictBranchGuard,
        studentSelfGuard, ROLES }               = require('../middleware/role.guard');
const { sensitiveLimiter, apiLimiter }          = require('../middleware/rate.limiter');
const { auditLog }                              = require('../middleware/audit.logger');

router.use(apiLimiter);

// ══════════════════════════════════════════════════════════════
// MARKSHEETS
// ══════════════════════════════════════════════════════════════

// Student: own marksheets — APPROVED ONLY
router.get('/marksheet/me',
  requireAuth,
  requirePermission('READ_OWN_MARKSHEET'),
  studentSelfGuard,
  async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('marksheets')
        .select(`
          id, roll_no, session, marks, total_marks, obtained_marks,
          percentage, grade, result, marksheet_sl_no, certificate_sl_no,
          marksheet_month, marksheet_year, issue_date, status,
          courses(id, name, short_name)
        `)
        .eq('student_id', req.studentId)
        .eq('status', 1)        // ← HARD FILTER: students only see APPROVED
        .order('created_at', { ascending: false });

      if (error) throw error;
      res.json({ success: true, count: data.length, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Admin/Teacher: list marksheets (branch scoped, all statuses)
router.get('/marksheets',
  requireAuth,
  requirePermission('READ_BRANCH_STUDENTS'),
  strictBranchGuard,
  async (req, res) => {
    try {
      const { status, student_id, page = 1, limit = 20 } = req.query;
      const from = (parseInt(page) - 1) * parseInt(limit);

      let query = supabase
        .from('marksheets')
        .select(`
          id, roll_no, session, percentage, grade, result, status,
          marksheet_sl_no, created_at,
          students(id, name, reg_no),
          courses(id, name, short_name)
        `, { count: 'exact' })
        .range(from, from + parseInt(limit) - 1)
        .order('created_at', { ascending: false });

      if (req.queryBranchId)      query = query.eq('branch_id', req.queryBranchId);
      if (status !== undefined)   query = query.eq('status', parseInt(status));
      if (student_id)             query = query.eq('student_id', parseInt(student_id));

      const { data, count, error } = await query;
      if (error) throw error;
      res.json({ success: true, total: count, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Branch Admin: submit marksheet (status always forced to 0=PENDING)
router.post('/marksheet',
  requireAuth,
  requirePermission('SUBMIT_MARKSHEET'),
  strictBranchGuard,
  auditLog('SUBMIT_MARKSHEET'),
  async (req, res) => {
    try {
      const body = { ...req.body };

      // CRITICAL: branch admin CANNOT self-approve
      body.status    = 0;           // always PENDING
      body.branch_id = req.queryBranchId;  // from server, never client
      delete body.approved_by;      // cannot set this
      delete body.approved_at;

      if (!body.student_id || !body.course_id) {
        return res.status(400).json({ error: 'student_id and course_id required' });
      }

      const { data, error } = await supabase
        .from('marksheets')
        .insert(body)
        .select()
        .single();

      if (error) throw error;
      res.status(201).json({
        success: true,
        data,
        message: 'Marksheet submitted and pending Super Admin approval.',
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// SUPER ADMIN ONLY: approve marksheet
router.patch('/marksheet/:id/approve',
  requireAuth,
  requirePermission('APPROVE_MARKSHEET'),  // super_admin ONLY
  sensitiveLimiter,
  auditLog('APPROVE_MARKSHEET'),
  async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid ID' });

      // Verify it exists and is currently pending
      const { data: existing } = await supabase
        .from('marksheets').select('id, status').eq('id', id).single();

      if (!existing) return res.status(404).json({ error: 'Marksheet not found' });
      if (existing.status === 1) return res.status(400).json({ error: 'Already approved' });
      if (existing.status === 2) return res.status(400).json({ error: 'Cannot approve a rejected marksheet' });

      const { data, error } = await supabase
        .from('marksheets')
        .update({
          status:      1,
          approved_by: req.profileId,
          approved_at: new Date().toISOString(),
          updated_at:  new Date().toISOString(),
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, message: 'Marksheet approved. Student can now download.', data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// SUPER ADMIN ONLY: reject marksheet
router.patch('/marksheet/:id/reject',
  requireAuth,
  requirePermission('APPROVE_MARKSHEET'),
  sensitiveLimiter,
  auditLog('REJECT_MARKSHEET'),
  async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid ID' });

      const { data, error } = await supabase
        .from('marksheets')
        .update({ status: 2, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select().single();

      if (error) throw error;
      res.json({ success: true, message: 'Marksheet rejected', data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// CERTIFICATES — Super Admin issues, students view own
// ══════════════════════════════════════════════════════════════

router.get('/certificate/me',
  requireAuth,
  requirePermission('READ_OWN_CERTIFICATE'),
  studentSelfGuard,
  async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('certificates')
        .select('id, certificate_no, issue_date, session, certificate_url, status, courses(id, name, short_name)')
        .eq('student_id', req.studentId)
        .eq('status', 1); // only issued/approved

      if (error) throw error;
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.post('/certificate',
  requireAuth,
  requirePermission('ISSUE_CERTIFICATE'),
  sensitiveLimiter,
  auditLog('ISSUE_CERTIFICATE'),
  async (req, res) => {
    try {
      const body = { ...req.body };

      if (req.role !== ROLES.SUPER_ADMIN) {
        body.status = 0; // Forced to 0 (PENDING) for branch admins
        body.branch_id = req.branchId; // Scope to branch
        delete body.approved_by;
        delete body.approved_at;
      } else {
        body.approved_by = req.profileId;
        body.status = 1; // Super Admin issues directly
        body.approved_at = new Date().toISOString();
      }

      // Verify linked marksheet is approved before issuing cert
      if (body.marksheet_id) {
        const { data: ms } = await supabase
          .from('marksheets').select('status').eq('id', body.marksheet_id).single();
        if (!ms || ms.status !== 1) {
          return res.status(400).json({ error: 'Cannot issue certificate: marksheet not approved' });
        }
      }

      const { data, error } = await supabase
        .from('certificates').insert(body).select().single();
      if (error) throw error;
      res.status(201).json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// SUPER ADMIN ONLY: approve certificate
router.patch('/certificate/:id/approve',
  requireAuth,
  requirePermission('APPROVE_CERTIFICATE'), // super_admin ONLY
  sensitiveLimiter,
  auditLog('APPROVE_CERTIFICATE'),
  async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid ID' });

      // Verify it exists and is currently pending
      const { data: existing } = await supabase
        .from('certificates').select('id, status').eq('id', id).single();

      if (!existing) return res.status(404).json({ error: 'Certificate not found' });
      if (existing.status === 1) return res.status(400).json({ error: 'Already approved/issued' });

      const { data, error } = await supabase
        .from('certificates')
        .update({
          status:      1,
          approved_by: req.profileId,
          approved_at: new Date().toISOString(),
          updated_at:  new Date().toISOString(),
        })
          .eq('id', id)
          .select()
          .single();

      if (error) throw error;
      res.json({ success: true, message: 'Certificate approved. Student can now view/download.', data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ADMIT CARDS
// ══════════════════════════════════════════════════════════════

router.get('/admit-card/me',
  requireAuth,
  requirePermission('READ_OWN_PROFILE'),
  studentSelfGuard,
  async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('admit_cards')
        .select('id, roll_no, exam_date, exam_center, session, issued_date, status, courses(id, name, short_name), branches(name, address)')
        .eq('student_id', req.studentId)
        .eq('status', 1);

      if (error) throw error;
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.post('/admit-card',
  requireAuth,
  requirePermission('ISSUE_ADMIT_CARD'),
  strictBranchGuard,
  auditLog('ISSUE_ADMIT_CARD'),
  async (req, res) => {
    try {
      const body = { ...req.body, branch_id: req.queryBranchId, generated_by: req.profileId };
      const { data, error } = await supabase.from('admit_cards').insert(body).select().single();
      if (error) throw error;
      res.status(201).json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ID CARDS
// ══════════════════════════════════════════════════════════════

router.get('/id-card/me',
  requireAuth,
  requirePermission('READ_OWN_IDCARD'),
  studentSelfGuard,
  async (req, res) => {
    try {
      const { data: student } = await supabase
        .from('students')
        .select('id, name, reg_no, photo_url, doj, courses(name), branches(name)')
        .eq('id', req.studentId).single();

      const { data: idCard } = await supabase
        .from('id_cards')
        .select('id, issue_date, expiry_date, qr_code_url, card_url')
        .eq('student_id', req.studentId)
        .eq('status', 1)
        .maybeSingle();

      res.json({ success: true, student, id_card: idCard || null });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

module.exports = router;
