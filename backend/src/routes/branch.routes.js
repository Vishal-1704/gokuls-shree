const router = require('express').Router();
const { supabase } = require('../config/supabase');
const { requireAuth } = require('../middleware/auth.middleware');
const { requirePermission, strictBranchGuard } = require('../middleware/role.guard');

// ── Get Branch Details ──────────────────────────────────────────────────
router.get('/my-branch', requireAuth, requirePermission('SETUP_OWN_BRANCH'), async (req, res) => {
  try {
    if (!req.branchId && req.role !== 'super_admin') {
      return res.status(200).json({ setup_required: true });
    }

    const branchId = req.branchId;
    const { data, error } = await supabase
      .from('branches')
      .select('*')
      .eq('id', branchId)
      .maybeSingle();

    if (error) return res.status(400).json({ error: error.message });
    if (!data) return res.status(200).json({ setup_required: true });

    res.json({ success: true, branch: data });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch branch details' });
  }
});

// ── Setup/Update Franchise Details ──────────────────────────────────────
router.post('/setup', requireAuth, requirePermission('SETUP_OWN_BRANCH'), async (req, res) => {
  const { name, code, owner_name, contact_phone, address } = req.body;

  if (!name || !code) {
    return res.status(400).json({ error: 'Branch name and code are required' });
  }

  try {
    const userId = req.user.id;
    const profileId = req.profileId;

    // 1. Check if branch already exists for this admin
    const { data: existingBranch } = await supabase
      .from('branches')
      .select('id')
      .eq('admin_id', userId)
      .maybeSingle();

    let branchId;

    if (existingBranch) {
      // Update
      const { data, error } = await supabase
        .from('branches')
        .update({
          name,
          code,
          owner_name,
          contact_phone,
          address
        })
        .eq('id', existingBranch.id)
        .select()
        .single();
      
      if (error) throw error;
      branchId = data.id;
    } else {
      // Create
      const { data, error } = await supabase
        .from('branches')
        .insert({
          admin_id: userId,
          name,
          code,
          owner_name,
          contact_phone,
          address
        })
        .select()
        .single();
      
      if (error) throw error;
      branchId = data.id;

      // 2. Link profile to this branch
      await supabase
        .from('profiles')
        .update({ branch_id: branchId })
        .eq('id', profileId);
    }

    res.json({
      success: true,
      message: 'Franchise setup completed successfully',
      branch_id: branchId
    });
  } catch (err) {
    console.error('Franchise Setup Error:', err.message);
    res.status(500).json({ error: 'Failed to setup franchise' });
  }
});

module.exports = router;
