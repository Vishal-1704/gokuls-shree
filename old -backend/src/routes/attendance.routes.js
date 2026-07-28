/**
 * ATTENDANCE ROUTES — Bulletproof
 *   student      → GET /attendance/me  (own monthly attendance)
 *   teacher      → POST mark attendance, GET branch attendance
 *   branch_admin → same as teacher + view reports
 *   super_admin  → full access
 */
const router = require('express').Router();
const { supabase }                          = require('../config/supabase');
const { requireAuth }                       = require('../middleware/auth.middleware');
const { requirePermission, strictBranchGuard, studentSelfGuard } = require('../middleware/role.guard');
const { apiLimiter, sensitiveLimiter }      = require('../middleware/rate.limiter');
const { auditLog }                          = require('../middleware/audit.logger');

router.use(apiLimiter);

// ── Student: my attendance (Bulletproof) ──────────────────────────────────
router.get('/me',
  requireAuth,
  requirePermission('READ_OWN_ATTENDANCE'),
  studentSelfGuard,
  async (req, res) => {
    try {
      const { month, year } = req.query;

      let query = supabase
        .from('student_attendance')
        .select('id, attendance_date, status, month, year')
        .eq('student_id', req.studentId)
        .order('attendance_date', { ascending: false });

      if (month) query = query.eq('month', parseInt(month));
      if (year)  query = query.eq('year', parseInt(year));

      const { data, error } = await query;
      if (error) throw error;

      const present = data.filter(d => d.status === 'P').length;
      const absent  = data.filter(d => d.status === 'A').length;
      const late    = data.filter(d => d.status === 'L').length;

      res.json({
        success: true,
        summary: { 
          total: data.length, 
          present, 
          absent, 
          late,
          percentage: data.length ? ((present / data.length) * 100).toFixed(1) + '%' : '0%'
        },
        records: data
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ── Teacher/Admin: mark attendance (Bulletproof) ───────────────────────────
// POST /api/v1/attendance/mark
// Body: { date: "2026-05-10", records: [{ student_id: 1, status: "P" }, ...] }
router.post('/mark',
  requireAuth,
  requirePermission('MARK_ATTENDANCE'),
  strictBranchGuard,
  sensitiveLimiter,
  auditLog('MARK_ATTENDANCE'),
  async (req, res) => {
    try {
      const { date, records } = req.body;
      if (!date || !Array.isArray(records) || !records.length) {
        return res.status(400).json({ error: 'date and records[] required' });
      }

      const d = new Date(date);
      // Map and inject verified branch_id
      const rows = records.map(r => ({
        student_id:      r.student_id,
        branch_id:       req.queryBranchId, // Enforced by guard
        attendance_date: date,
        status:          r.status, // P/A/L/H
        month:           d.getMonth() + 1,
        year:            d.getFullYear(),
        marked_by:       req.profileId,
      }));

      // Upsert — if attendance already marked for same student+date, update it
      const { data, error } = await supabase
        .from('student_attendance')
        .upsert(rows, { onConflict: 'student_id,attendance_date' })
        .select();

      if (error) throw error;
      res.json({ success: true, marked: data.length });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ── Admin: get attendance list (branch filtered) ──────────────────────────
router.get('/',
  requireAuth,
  requirePermission('READ_BRANCH_ATTENDANCE'),
  strictBranchGuard,
  async (req, res) => {
    try {
      const { date, month, year, student_id } = req.query;

      let query = supabase
        .from('student_attendance')
        .select(`
          id, attendance_date, status, month, year,
          students(id, name, reg_no)
        `)
        .order('attendance_date', { ascending: false });

      if (req.queryBranchId) query = query.eq('branch_id', req.queryBranchId);
      if (date)       query = query.eq('attendance_date', date);
      if (month)      query = query.eq('month', parseInt(month));
      if (year)       query = query.eq('year', parseInt(year));
      if (student_id) query = query.eq('student_id', parseInt(student_id));

      const { data, error } = await query;
      if (error) throw error;
      res.json({ success: true, total: data.length, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

module.exports = router;

