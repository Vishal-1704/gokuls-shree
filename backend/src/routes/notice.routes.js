/**
 * Notice & Course Routes (unchanged structure, just role-gated)
 */
const router = require('express').Router();
const { supabase } = require('../config/supabase');
const { requireAuth, requireRole, getBranchFilter } = require('../middleware/auth.middleware');

// ── Notices (all roles can read) ──────────────────────────────────────────
router.get('/', requireAuth, async (req, res) => {
  try {
    let query = supabase
      .from('notices')
      .select('id, title, content, type, published_at')
      .eq('status', 1)
      .order('published_at', { ascending: false })
      .limit(50);

    // Students/teachers see only their branch + public notices
    if (['student', 'teacher'].includes(req.role) && req.branchId) {
      query = query.or(`branch_id.eq.${req.branchId},is_public.eq.true`);
    }
    const branchId = getBranchFilter(req);
    if (req.role === 'branch_admin' && branchId) query = query.eq('branch_id', branchId);

    const { data, error } = await query;
    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: create notice
router.post('/', requireAuth, requireRole('super_admin', 'branch_admin'), async (req, res) => {
  try {
    const body = { ...req.body, created_by: req.profileId };
    if (req.role === 'branch_admin') body.branch_id = req.branchId;

    const { data, error } = await supabase.from('notices').insert(body).select().single();
    if (error) throw error;
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
