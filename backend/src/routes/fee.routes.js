/**
 * FEE ROUTES — Bulletproof
 *   student      → GET /fees/me   (own fees only)
 *   branch_admin → GET/POST fees for their branch
 *   super_admin  → full access
 */
const router = require('express').Router();
const { supabase }                          = require('../config/supabase');
const { requireAuth }                       = require('../middleware/auth.middleware');
const { requirePermission, strictBranchGuard, studentSelfGuard } = require('../middleware/role.guard');
const { apiLimiter, sensitiveLimiter }      = require('../middleware/rate.limiter');
const { auditLog }                          = require('../middleware/audit.logger');

router.use(apiLimiter);

// ── Student: my fee history (Bulletproof) ──────────────────────────────────
router.get('/me',
  requireAuth,
  requirePermission('READ_OWN_FEE'),
  studentSelfGuard,
  async (req, res) => {
    try {
      // Get summary stats first
      const { data: student, error: stError } = await supabase
        .from('students')
        .select('id, course_fee, reg_fee, admin_fee, discount')
        .eq('id', req.studentId)
        .single();

      if (stError || !student) return res.status(404).json({ error: 'Student record not found' });

      // Get payment history
      const { data: fees, error } = await supabase
        .from('fee_payments')
        .select('id, receipt_no, payment_date, amount, net_pay, payment_mode, description, next_due_date')
        .eq('student_id', req.studentId)
        .order('payment_date', { ascending: false });

      if (error) throw error;

      const totalPaid = fees.reduce((sum, f) => sum + (parseFloat(f.net_pay) || 0), 0);
      const totalFee  = (parseFloat(student.course_fee) || 0) + (parseFloat(student.reg_fee) || 0) + (parseFloat(student.admin_fee) || 0);
      const discount  = (parseFloat(student.discount) || 0);
      const totalDue  = totalFee - discount - totalPaid;

      res.json({
        success: true,
        summary: {
          total_fee: totalFee,
          discount:  discount,
          total_paid: totalPaid,
          balance_due: Math.max(0, totalDue),
        },
        payments: fees
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ── Admin: list all fees (branch filtered) ────────────────────────────────
router.get('/',
  requireAuth,
  requirePermission('READ_BRANCH_FEES'),
  strictBranchGuard,
  async (req, res) => {
    try {
      const { page = 1, limit = 20, student_id } = req.query;
      const from = (parseInt(page) - 1) * parseInt(limit);

      let query = supabase
        .from('fee_payments')
        .select(`
          id, receipt_no, payment_date, amount, net_pay, fine,
          payment_mode, description, next_due_date,
          students(id, name, reg_no),
          branches(id, name)
        `, { count: 'exact' })
        .range(from, from + parseInt(limit) - 1)
        .order('payment_date', { ascending: false });

      // CRITICAL: use req.queryBranchId from guard
      if (req.queryBranchId) query = query.eq('branch_id', req.queryBranchId);
      if (student_id)         query = query.eq('student_id', parseInt(student_id));

      const { data, count, error } = await query;
      if (error) throw error;
      res.json({ success: true, total: count, data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ── Record fee payment (Super Admin / Branch Admin only) ──────────────────
router.post('/',
  requireAuth,
  requirePermission('COLLECT_FEE'),
  strictBranchGuard,
  sensitiveLimiter,
  auditLog('COLLECT_FEE'),
  async (req, res) => {
    try {
      const body = { ...req.body };
      
      // Inject verified IDs
      body.branch_id   = req.queryBranchId; 
      body.recorded_by = req.profileId;

      if (!body.student_id || !body.net_pay) {
        return res.status(400).json({ error: 'student_id and net_pay are required' });
      }

      const { data, error } = await supabase
        .from('fee_payments')
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

module.exports = router;

