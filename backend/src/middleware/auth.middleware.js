/**
 * AUTH MIDDLEWARE — Bulletproof JWT + profile validation
 *
 * Every protected request must pass ALL checks:
 *   1. Authorization header present + Bearer format
 *   2. Supabase JWT valid (not expired, not tampered)
 *   3. profiles row exists for this auth user
 *   4. profile.status === 1 (active — not suspended)
 *   5. profile.branch_id set for non-super-admin users
 *
 * Attaches to req:
 *   req.user        - Supabase auth.users record
 *   req.profile     - profiles table row
 *   req.role        - 'super_admin' | 'branch_admin' | 'teacher' | 'student'
 *   req.profileId   - profiles.id (UUID)
 *   req.branchId    - profiles.branch_id (INT | null for super_admin)
 */
const { supabase } = require('../config/supabase');

// Valid roles — anything else is rejected even if in DB
const VALID_ROLES = new Set(['super_admin', 'branch_admin', 'teacher', 'student']);

const requireAuth = async (req, res, next) => {
  try {
    // ── Check 1: Header present ────────────────────────────────────────
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Authorization header missing or malformed',
        hint: 'Send: Authorization: Bearer <token>',
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token || token.length < 20) {
      return res.status(401).json({ error: 'Token too short or empty' });
    }

    // ── Check 2: Validate JWT with Supabase ───────────────────────────
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return res.status(401).json({
        error: 'Invalid or expired token. Please login again.',
      });
    }

    // ── Check 3: Fetch profile row ────────────────────────────────────
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id, role, branch_id, full_name, status, updated_at')
      .eq('auth_uid', user.id)
      .single();

    if (profileError || !profile) {
      console.warn(`🚨 Auth: No profile for auth_uid=${user.id}`);
      return res.status(403).json({
        error: 'Your account has no profile. Contact the administrator.',
      });
    }

    // ── Check 4: Account active ───────────────────────────────────────
    if (profile.status !== 1) {
      console.warn(`🚨 Auth: Inactive account profileId=${profile.id} role=${profile.role}`);
      return res.status(403).json({
        error: 'Your account is inactive or suspended. Contact administrator.',
      });
    }

    // ── Check 5: Valid role ───────────────────────────────────────────
    if (!VALID_ROLES.has(profile.role)) {
      console.error(`🚨 Auth: Invalid role "${profile.role}" for profileId=${profile.id}`);
      return res.status(403).json({ error: 'Invalid role assigned. Contact administrator.' });
    }

    // ── Check 6: Branch assigned for non-super-admin ──────────────────
    if (profile.role !== 'super_admin' && !profile.branch_id) {
      return res.status(403).json({
        error: 'No branch assigned to your account. Contact super admin.',
      });
    }

    // ── Attach to request (read-only intent) ──────────────────────────
    req.user      = user;
    req.profile   = profile;
    req.role      = profile.role;
    req.profileId = profile.id;
    req.branchId  = profile.branch_id || null;

    next();

  } catch (err) {
    console.error('💥 Auth middleware crash:', err.message);
    res.status(500).json({ error: 'Authentication service error' });
  }
};

/**
 * requireRole(...roles) — role whitelist check
 * Should be used AFTER requireAuth.
 */
const requireRole = (...roles) => (req, res, next) => {
  if (!req.role) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  if (!roles.includes(req.role)) {
    console.warn(
      `🚨 Role denied | Required: [${roles}] | Got: ${req.role} | ` +
      `Profile: ${req.profileId} | Path: ${req.path}`
    );
    return res.status(403).json({
      error: `Access denied. This section requires: ${roles.join(' or ')}`,
    });
  }
  next();
};

/**
 * getBranchFilter(req) — returns branch_id to filter DB queries.
 * NEVER use req.body.branch_id or req.query.branch_id for filtering.
 * Always use this function.
 */
const getBranchFilter = (req) => {
  if (req.role === 'super_admin') return null;
  return req.branchId;
};

module.exports = { requireAuth, requireRole, getBranchFilter };
