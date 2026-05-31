/**
 * Auth Routes — Login, logout, profile
 * POST /api/v1/auth/login
 * GET  /api/v1/auth/me
 * POST /api/v1/auth/logout
 */
const router = require('express').Router();
const { supabase } = require('../config/supabase');
const { requireAuth } = require('../middleware/auth.middleware');
const { requirePermission, ROLES } = require('../middleware/role.guard');

// ── Login ─────────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Authenticate with Supabase Auth
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return res.status(401).json({ error: 'Invalid email or password' });

    const { user, session } = data;

    // Fetch role profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, role, branch_id, full_name, status')
      .eq('auth_uid', user.id)
      .single();

    if (!profile || profile.status === 0) {
      return res.status(403).json({ error: 'Account is inactive or not found' });
    }

    // Return token + role info — Flutter app stores this
    res.json({
      success: true,
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      user: {
        id:        profile.id,
        role:      profile.role,
        name:      profile.full_name,
        branch_id: profile.branch_id,
        email:     user.email,
      }
    });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed' });
  }
});

// ── Send OTP (Email based) ────────────────────────────────────────────────
router.post('/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    // Send OTP via Supabase
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { shouldCreateUser: false }, // Prevent random signups
    });
    
    if (error) return res.status(400).json({ error: error.message });

    res.json({ success: true, message: 'OTP sent successfully to email' });
  } catch (err) {
    console.error('OTP Send error:', err.message);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// ── Verify OTP ────────────────────────────────────────────────────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ error: 'Email and OTP required' });
    }

    // Verify OTP with Supabase Auth
    const { data, error } = await supabase.auth.verifyOtp({
      email,
      token: otp,
      type: 'email',
    });
    
    if (error) return res.status(401).json({ error: 'Invalid or expired OTP' });

    const { user, session } = data;

    // Fetch role profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, role, branch_id, full_name, status')
      .eq('auth_uid', user.id)
      .single();

    if (!profile || profile.status === 0) {
      return res.status(403).json({ error: 'Account is inactive or not found' });
    }

    // Return token + role info
    res.json({
      success: true,
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      user: {
        id:        profile.id,
        role:      profile.role,
        name:      profile.full_name,
        branch_id: profile.branch_id,
        email:     user.email,
      }
    });
  } catch (err) {
    console.error('Verify OTP error:', err.message);
    res.status(500).json({ error: 'Failed to verify OTP' });
  }
});

// ── Get current user profile ───────────────────────────────────────────────
router.get('/me', requireAuth, async (req, res) => {
  try {
    const role = req.role;
    let extraData = {};

    if (role === 'student') {
      // Fetch student record linked to this profile
      const { data: student } = await supabase
        .from('students')
        .select('id, name, reg_no, roll_no, photo_url, course_id, branch_id, status')
        .eq('profile_id', req.profileId)
        .single();
      extraData = { student };
    }

    if (role === 'teacher') {
      const { data: employee } = await supabase
        .from('employees')
        .select('id, name, designation, department, branch_id')
        .eq('profile_id', req.profileId)
        .single();
      extraData = { employee };
    }

    res.json({
      success: true,
      profile: {
        id:       req.profileId,
        role:     req.role,
        name:     req.profile.full_name,
        branch_id: req.branchId,
        email:    req.user.email,
      },
      ...extraData
    });
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch profile' });
  }
});

// ── Refresh token ─────────────────────────────────────────────────────────
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) return res.status(400).json({ error: 'refresh_token required' });

    const { data, error } = await supabase.auth.refreshSession({ refresh_token });
    if (error) return res.status(401).json({ error: 'Token refresh failed' });

    res.json({
      success: true,
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    });
  } catch (err) {
    res.status(500).json({ error: 'Refresh failed' });
  }
});

// ── Logout ────────────────────────────────────────────────────────────────
router.post('/logout', requireAuth, async (req, res) => {
  await supabase.auth.signOut();
  res.json({ success: true, message: 'Logged out' });
});

// ── Admin: Register Branch Admin ──────────────────────────────────────────
router.post('/admin/register-branch-admin', requireAuth, requirePermission('REGISTER_BRANCH_ADMIN'), async (req, res) => {
  const { email, password, name } = req.body;
  
  if (!email || !password || !name) {
    return res.status(400).json({ error: 'Email, password and name are required' });
  }

  try {
    // 1. Create user in Supabase Auth (Service Role bypasses signup confirmation if configured)
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name }
    });

    if (authError) return res.status(400).json({ error: authError.message });

    const user = authData.user;

    // 2. Create Profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .insert({
        auth_uid: user.id,
        full_name: name,
        role: ROLES.BRANCH_ADMIN,
        status: 1 // Active
      })
      .select()
      .single();

    if (profileError) {
      // Cleanup: delete auth user if profile creation fails
      await supabase.auth.admin.deleteUser(user.id);
      return res.status(500).json({ error: 'Failed to create user profile' });
    }

    // 3. Create Admin record
    const { error: adminError } = await supabase
      .from('admins')
      .insert({
        user_id: user.id,
        email: email,
        name: name
      });

    if (adminError) {
      console.warn('⚠️ Admin record creation failed, but user and profile exist:', adminError.message);
    }

    res.json({
      success: true,
      message: 'Branch Admin registered successfully',
      user: {
        id: profile.id,
        email: user.email,
        name: name
      }
    });
  } catch (err) {
    console.error('Admin Registration Error:', err.message);
    res.status(500).json({ error: 'Internal server error during registration' });
  }
});

// ── Admin: Register Teacher ───────────────────────────────────────────────
router.post('/admin/register-teacher', requireAuth, requirePermission('REGISTER_TEACHER'), async (req, res) => {
  const { email, password, name } = req.body;
  let branchId = req.body.branch_id;
  
  if (req.role === ROLES.BRANCH_ADMIN) {
    branchId = req.branchId; // Force their own branch
  }

  if (!email || !password || !name) {
    return res.status(400).json({ error: 'Email, password and name are required' });
  }

  try {
    // 1. Create user in Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name }
    });

    if (authError) return res.status(400).json({ error: authError.message });

    const user = authData.user;

    // 2. Create Profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .insert({
        auth_uid: user.id,
        full_name: name,
        role: ROLES.TEACHER,
        branch_id: branchId,
        status: 1 // Active
      })
      .select()
      .single();

    if (profileError) {
      await supabase.auth.admin.deleteUser(user.id);
      return res.status(500).json({ error: 'Failed to create user profile' });
    }

    // 3. Create Employee record
    const { error: employeeError } = await supabase
      .from('employees')
      .insert({
        profile_id: profile.id,
        name: name,
        designation: 'Teacher',
        department: 'Academic',
        branch_id: branchId
      });

    if (employeeError) {
      console.warn('⚠️ Employee record creation failed, but user and profile exist:', employeeError.message);
    }

    res.json({
      success: true,
      message: 'Teacher registered successfully',
      user: {
        id: profile.id,
        email: user.email,
        name: name
      }
    });
  } catch (err) {
    console.error('Teacher Registration Error:', err.message);
    res.status(500).json({ error: 'Internal server error during registration' });
  }
});

// ── Super Admin ONLY: Reset Any User Password ──────────────────────────────
// requirePermission('RESET_USER_PASSWORD') blocks ALL non-super_admin roles before reaching this handler.
router.post('/admin/reset-password', requireAuth, requirePermission('RESET_USER_PASSWORD'), async (req, res) => {
  const { targetProfileId, newPassword } = req.body;

  if (!targetProfileId || !newPassword) {
    return res.status(400).json({ error: 'Target profile ID and new password are required' });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters long' });
  }

  try {
    // 1. Fetch target profile
    const { data: targetProfile, error: profileError } = await supabase
      .from('profiles')
      .select('id, role, branch_id, auth_uid, full_name')
      .eq('id', targetProfileId)
      .single();

    if (profileError || !targetProfile) {
      return res.status(404).json({ error: 'Target user profile not found' });
    }

    // 2. Super Admin can reset ANY user's password — no further checks needed.
    // (requirePermission('RESET_USER_PASSWORD') already ensures only super_admin reaches here)
    // Prevent super_admin from accidentally being passed invalid targets via extra guard:
    if (!targetProfile.auth_uid) {
      return res.status(400).json({ error: 'Target user has no auth account linked. Cannot reset password.' });
    }

    // 3. Update password via Supabase Admin Auth API
    const { error: authError } = await supabase.auth.admin.updateUserById(
      targetProfile.auth_uid,
      { password: newPassword }
    );

    if (authError) {
      return res.status(400).json({ error: authError.message });
    }

    res.json({
      success: true,
      message: `Password updated successfully for ${targetProfile.full_name}`,
    });

  } catch (err) {
    console.error('Admin Password Reset Error:', err.message);
    res.status(500).json({ error: 'Internal server error during password reset' });
  }
});

module.exports = router;
