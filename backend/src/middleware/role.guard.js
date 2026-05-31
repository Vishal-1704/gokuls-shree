/**
 * ROLE GUARD MIDDLEWARE
 * Bulletproof role-based access control.
 *
 * SECURITY MODEL:
 *   Every route declares EXACTLY which roles may call it.
 *   If the caller's role is not in that whitelist → 403, always.
 *   Branch isolation is enforced at query level — not just middleware.
 *
 * DEFENCE LAYERS:
 *   1. JWT must be valid (auth.middleware.js)
 *   2. profile.status must be 1 (active)
 *   3. Role must be in allowed list (this file)
 *   4. Branch ID is injected at query level (never trust client branch_id)
 *   5. All sensitive actions are audit-logged
 */

// Role hierarchy constants — single source of truth
const ROLES = Object.freeze({
  SUPER_ADMIN:  'super_admin',
  BRANCH_ADMIN: 'branch_admin',
  TEACHER:      'teacher',
  STUDENT:      'student',
});

// ── Role permission matrix ─────────────────────────────────────────────────
// Maps each permission to the roles that hold it.
// This is the ONLY place permissions are defined.
const PERMISSIONS = Object.freeze({
  // Student-level
  READ_OWN_PROFILE:     [ROLES.STUDENT, ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  READ_OWN_FEES:        [ROLES.STUDENT],
  READ_OWN_ATTENDANCE:  [ROLES.STUDENT],
  READ_OWN_MARKSHEET:   [ROLES.STUDENT],
  READ_OWN_CERTIFICATE: [ROLES.STUDENT],
  READ_OWN_IDCARD:      [ROLES.STUDENT],
  TAKE_EXAM:            [ROLES.STUDENT],

  // Teacher-level
  MARK_ATTENDANCE:      [ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  READ_BRANCH_STUDENTS: [ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  UPLOAD_MARKS:         [ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],

  // Branch Admin-level
  ENROLL_STUDENT:       [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  RECORD_FEE:           [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  SUBMIT_MARKSHEET:     [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  ISSUE_ADMIT_CARD:     [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  READ_BRANCH_FEES:     [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  MANAGE_NOTICES:       [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],

  // Super Admin ONLY
  APPROVE_MARKSHEET:    [ROLES.SUPER_ADMIN],
  ISSUE_CERTIFICATE:    [ROLES.SUPER_ADMIN, ROLES.BRANCH_ADMIN],
  READ_ALL_BRANCHES:    [ROLES.SUPER_ADMIN],
  MANAGE_BRANCHES:      [ROLES.SUPER_ADMIN],
  REGISTER_BRANCH_ADMIN:[ROLES.SUPER_ADMIN],
  SETUP_OWN_BRANCH:     [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
  ACCESS_ALL_DATA:      [ROLES.SUPER_ADMIN],
  RESET_USER_PASSWORD:   [ROLES.SUPER_ADMIN],
  APPROVE_STUDENT:      [ROLES.SUPER_ADMIN],
  APPROVE_CERTIFICATE:  [ROLES.SUPER_ADMIN],
  REGISTER_TEACHER:     [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
});

/**
 * requirePermission(permissionKey)
 * Usage: router.get('/fees', requireAuth, requirePermission('READ_BRANCH_FEES'), handler)
 */
const requirePermission = (permissionKey) => (req, res, next) => {
  const allowedRoles = PERMISSIONS[permissionKey];

  if (!allowedRoles) {
    // Unknown permission key — this is a coding bug, fail hard
    console.error(`🚨 SECURITY: Unknown permission key "${permissionKey}"`);
    return res.status(500).json({ error: 'Server misconfiguration' });
  }

  if (!req.role) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  if (!allowedRoles.includes(req.role)) {
    // Log attempted unauthorized access
    console.warn(
      `🚨 UNAUTHORIZED ACCESS ATTEMPT | Role: ${req.role} | ` +
      `Permission needed: ${permissionKey} | ` +
      `IP: ${req.ip} | Path: ${req.path} | ` +
      `Profile: ${req.profileId}`
    );
    return res.status(403).json({
      error: 'Access denied',
      required_permission: permissionKey,
      your_role: req.role,
    });
  }

  next();
};

/**
 * strictBranchGuard — enforces that every query is scoped to caller's branch.
 * Attaches req.queryBranchId which MUST be used in all DB queries.
 *
 * - super_admin: req.queryBranchId = null (no filter = all branches)
 * - everyone else: req.queryBranchId = their profile's branch_id (immutable)
 *
 * CRITICAL: routes MUST use req.queryBranchId, NOT req.body.branch_id
 * because client can forge body/query params.
 */
const strictBranchGuard = (req, res, next) => {
  if (req.role === ROLES.SUPER_ADMIN) {
    req.queryBranchId = null; // can see all
  } else if (req.branchId) {
    req.queryBranchId = req.branchId; // locked to their branch from JWT
  } else {
    // Staff without a branch assignment — deny
    return res.status(403).json({
      error: 'No branch assigned to your account. Contact super admin.',
    });
  }

  // Override any branch_id the client tried to send in body or query
  // This prevents privilege escalation via forged branch_id
  if (req.body) {
    delete req.body.branch_id; // will be set by server below
    if (req.queryBranchId) req.body.branch_id = req.queryBranchId;
  }

  next();
};

/**
 * studentSelfGuard — for student-only routes.
 * Ensures a student can ONLY access their own record.
 * Attaches req.studentOwnerId (the student table id linked to this profile).
 */
const studentSelfGuard = async (req, res, next) => {
  if (req.role !== ROLES.STUDENT) {
    // Non-students hitting a student-self route is a bug
    return res.status(403).json({ error: 'This endpoint is for students only' });
  }

  const { supabase } = require('../config/supabase');
  const { data: student, error } = await supabase
    .from('students')
    .select('id, branch_id, status')
    .eq('profile_id', req.profileId)
    .single();

  if (error || !student) {
    return res.status(404).json({ error: 'Student record not found' });
  }
  if (student.status === 0) {
    return res.status(403).json({ error: 'Student account is inactive' });
  }

  // Attach to req — routes use this, never trust query params
  req.studentId = student.id;
  req.studentBranchId = student.branch_id;

  next();
};

module.exports = {
  ROLES,
  PERMISSIONS,
  requirePermission,
  strictBranchGuard,
  studentSelfGuard,
};
