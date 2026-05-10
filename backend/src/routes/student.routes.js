/**
 * STUDENT ROUTES — Bulletproof Role Isolation
 *
 * Security layers on every route:
 *   requireAuth          → valid JWT + active account
 *   requirePermission()  → role in permission whitelist
 *   strictBranchGuard    → branch_id locked to caller's profile (not body)
 *   studentSelfGuard     → students can ONLY read their own record
 *   DB query always uses req.queryBranchId (never req.body.branch_id)
 */
const router = require('express').Router();
const { supabase }                          = require('../config/supabase');
const { requireAuth, getBranchFilter }      = require('../middleware/auth.middleware');
const { requirePermission, strictBranchGuard, studentSelfGuard, ROLES } = require('../middleware/role.guard');
const { apiLimiter }                        = require('../middleware/rate.limiter');
const { auditLog }                          = require('../middleware/audit.logger');

// Apply API rate limit to all student routes
router.use(apiLimiter);

// ══════════════════════════════════════════════════════════════
// STUDENT: read own record  (STUDENT ONLY — no admin here)
// GET /api/v1/students/me
// ══════════════════════════════════════════════════════════════
router.get(
  '/me',
  requireAuth,
  requirePermission('READ_OWN_PROFILE'),  // student + all admins can call
  studentSelfGuard,                        // but attaches req.studentId securely
  async (req, res) => {
    try {
      // studentSelfGuard has already resolved req.studentId
      const { data, error } = await supabase
        .from('students')
        .select(`
          id, name, reg_no, roll_no, adm_no, gender, dob,
          contact, email, father_name, mother_name,
          qualification, session, doj, course_fee,
          reg_fee, admin_fee, discount,
          photo_url, signature_url, id_card_issued, status,
          courses(id, name, short_name, duration),
          branches(id, name, address)
        `)
        .eq('id', req.studentId)  // ← always use req.studentId, never a param
        .single();

      if (error || !data) return res.status(404).json({ error: 'Student record not found' });
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ADMIN/TEACHER: list students in their branch
// GET /api/v1/students?page=1&limit=20&search=name&course_id=X
// ══════════════════════════════════════════════════════════════
router.get(
  '/',
  requireAuth,
  requirePermission('READ_BRANCH_STUDENTS'),
  strictBranchGuard,
  async (req, res) => {
    try {
      const { page = 1, limit = 20, search, course_id, status = 1 } = req.query;
      const from = (parseInt(page) - 1) * parseInt(limit);

      let query = supabase
        .from('students')
        .select(`
          id, name, reg_no, roll_no, gender, contact, email,
          doj, status, photo_url, id_card_issued,
          courses(id, name, short_name),
          branches(id, name)
        `, { count: 'exact' })
        .eq('status', parseInt(status))
        .range(from, from + parseInt(limit) - 1)
        .order('name');

      // ← CRITICAL: always use req.queryBranchId from strictBranchGuard
      if (req.queryBranchId) query = query.eq('branch_id', req.queryBranchId);
      if (course_id)          query = query.eq('course_id', parseInt(course_id));
      if (search)             query = query.ilike('name', `%${search}%`);

      const { data, count, error } = await query;
      if (error) throw error;
      res.json({ success: true, total: count, page: +page, limit: +limit, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ADMIN/TEACHER: get single student by ID (branch scoped)
// GET /api/v1/students/:id
// Students CANNOT call this — use /me
// ══════════════════════════════════════════════════════════════
router.get(
  '/:id',
  requireAuth,
  requirePermission('READ_BRANCH_STUDENTS'),
  strictBranchGuard,
  async (req, res) => {
    try {
      const studentId = parseInt(req.params.id);
      if (isNaN(studentId)) return res.status(400).json({ error: 'Invalid student ID' });

      let query = supabase
        .from('students')
        .select(`*, courses(id, name, short_name, duration, fee), branches(id, name, address, contact)`)
        .eq('id', studentId);

      // Branch-scope: non-super-admins can only fetch their branch's students
      if (req.queryBranchId) query = query.eq('branch_id', req.queryBranchId);

      const { data, error } = await query.single();
      if (error || !data) return res.status(404).json({ error: 'Student not found in your branch' });
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BRANCH ADMIN / SUPER ADMIN: enroll new student
// POST /api/v1/students
// ══════════════════════════════════════════════════════════════
router.post(
  '/',
  requireAuth,
  requirePermission('ENROLL_STUDENT'),
  strictBranchGuard,    // strips + re-injects branch_id from profile
  auditLog('ENROLL_STUDENT'),
  async (req, res) => {
    try {
      const body = { ...req.body };

      // strictBranchGuard already set body.branch_id from server-side profile
      // Double-enforce: never allow client to override
      if (req.role !== ROLES.SUPER_ADMIN) {
        body.branch_id = req.queryBranchId;
      }

      // Required fields check
      if (!body.name || !body.course_id) {
        return res.status(400).json({ error: 'name and course_id are required' });
      }

      const { data, error } = await supabase
        .from('students')
        .insert(body)
        .select()
        .single();

      if (error) throw error;
      res.status(201).json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BRANCH ADMIN / SUPER ADMIN: update student
// PUT /api/v1/students/:id
// ══════════════════════════════════════════════════════════════
router.put(
  '/:id',
  requireAuth,
  requirePermission('ENROLL_STUDENT'),
  strictBranchGuard,
  auditLog('UPDATE_STUDENT'),
  async (req, res) => {
    try {
      const studentId = parseInt(req.params.id);
      if (isNaN(studentId)) return res.status(400).json({ error: 'Invalid student ID' });

      const body = { ...req.body, updated_at: new Date().toISOString() };
      // Prevent clients from changing branch_id or profile_id via update
      delete body.profile_id;
      if (req.role !== ROLES.SUPER_ADMIN) {
        body.branch_id = req.queryBranchId; // lock to their branch
      }

      let query = supabase
        .from('students')
        .update(body)
        .eq('id', studentId);

      // Branch-scope the update too — cannot update another branch's student
      if (req.queryBranchId) query = query.eq('branch_id', req.queryBranchId);

      const { data, error } = await query.select().single();
      if (error || !data) return res.status(404).json({ error: 'Student not found or access denied' });
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

module.exports = router;
