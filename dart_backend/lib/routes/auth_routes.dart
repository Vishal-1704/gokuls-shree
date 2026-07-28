// lib/routes/auth_routes.dart
// Auth routes: login, register, OTP, logout, profile, admin registration, password reset
// Ported from auth.routes.js with BUG-2 and BUG-6 fixes applied.

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_guard.dart';
import '../middleware/rate_limiter.dart';
import '../models/user_session.dart';

Router buildAuthRouter() {
  final router = Router();

  // ── Public Student Register ───────────────────────────────────────────────
  router.post('/register', (Request req) async {
    try {
      final body = await _body(req);
      final email    = body['email'] as String?;
      final password = body['password'] as String?;
      final name     = body['name'] as String?;
      final phone    = body['phone'] as String?;
      final fatherName = body['father_name'] as String?;
      final dob      = body['dob'] as String?;
      final address  = body['address'] as String?;
      final gender   = body['gender'] as String?;
      final courseId = body['course_id'];
      final branchId = body['branch_id'];

      if (email == null || password == null || name == null) {
        return _json(400, {'error': 'Email, password and name are required'});
      }

      // Validate branch if provided
      if (branchId != null) {
        final branches = await SupabaseService.select(
          'branches',
          columns: 'id,status',
          filters: {'id': int.parse(branchId.toString())},
        );
        if (branches.isEmpty) return _json(400, {'error': 'Invalid branch ID'});
        if (branches.first['status'] != 1) {
          return _json(400, {'error': 'Selected branch is currently inactive'});
        }
      }

      // 1. Create auth user (auto-confirms email)
      final authUser = await SupabaseService.adminCreateUser(
        email: email,
        password: password,
        userMetadata: {'name': name, 'mobile': phone},
      );
      final authUid = authUser!['id'] as String;

      // 2. Create Profile record (role = student, status = 0 Pending)
      Map<String, dynamic> profile;
      try {
        profile = await SupabaseService.insert('profiles', {
          'auth_uid': authUid,
          'full_name': name,
          'role': roleStudent,
          'contact': phone,
          'email': email,
          'branch_id': branchId != null ? int.parse(branchId.toString()) : null,
          'status': 0, // Pending approval
          'permissions': [
            'READ_OWN_PROFILE', 'READ_OWN_FEES', 'READ_OWN_ATTENDANCE',
            'READ_OWN_MARKSHEET', 'READ_OWN_CERTIFICATE', 'READ_OWN_IDCARD', 'TAKE_EXAM'
          ],
        });
      } catch (e) {
        await SupabaseService.adminDeleteUser(authUid);
        return _json(500, {'error': 'Failed to create student profile: $e'});
      }

      // 3. Create Student record
      // BUG-2 FIX: use profile['id'] (profiles.id), NOT authUid (auth.users.id)
      try {
        await SupabaseService.insert('students', {
          'profile_id': profile['id'], // ← FIXED: was authUid in JS bug
          'name': name,
          'email': email,
          'contact': phone,
          'status': 0,
          'father_name': fatherName,
          'dob': dob,
          'address': address,
          'gender': gender,
          'course_id': courseId != null ? int.parse(courseId.toString()) : null,
          'branch_id': branchId != null ? int.parse(branchId.toString()) : null,
        });
      } catch (e) {
        print('⚠️ Student record creation warning: $e');
      }

      return _json(200, {
        'success': true,
        'message': 'Student registered successfully and is pending approval',
        'user': {'id': profile['id'], 'email': email, 'name': name},
      });
    } catch (e) {
      print('Student Registration Error: $e');
      return _json(500, {'error': 'Internal server error during registration'});
    }
  });

  // ── Login ─────────────────────────────────────────────────────────────────
  router.post('/login', (Request req) async {
    try {
      final body = await _body(req);
      final email    = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return _json(400, {'error': 'Email and password required'});
      }

      final authData = await SupabaseService.signInWithPassword(
        email: email,
        password: password,
      );
      if (authData == null) {
        return _json(401, {'error': 'Invalid email or password'});
      }

      final accessToken  = authData['access_token'] as String;
      final refreshToken = authData['refresh_token'] as String;
      final user         = authData['user'] as Map<String, dynamic>;

      // Fetch role profile
      final profiles = await SupabaseService.select(
        'profiles',
        columns: 'id,role,branch_id,full_name,status,permissions',
        filters: {'auth_uid': user['id']},
      );

      if (profiles.isEmpty) {
        return _json(403, {'error': 'Account is inactive or not found'});
      }

      final profile = profiles.first;

      // BUG-6 FIX: use != 1 (not == 0) — catches null, suspended, etc.
      if (profile['status'] != 1) {
        return _json(403, {'error': 'Account is inactive or not found'});
      }

      return _json(200, {
        'success': true,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': {
          'id':          profile['id'],
          'role':        profile['role'],
          'name':        profile['full_name'],
          'branch_id':   profile['branch_id'],
          'email':       user['email'],
          'permissions': profile['permissions'] ?? [],
        },
      });
    } catch (e) {
      print('Login error: $e');
      return _json(500, {'error': 'Login failed'});
    }
  });

  // ── Send OTP ──────────────────────────────────────────────────────────────
  router.post('/send-otp', (Request req) async {
    try {
      final body  = await _body(req);
      final email = body['email'] as String?;
      if (email == null) return _json(400, {'error': 'Email required'});

      final ok = await SupabaseService.sendOtp(email);
      if (!ok) return _json(400, {'error': 'Failed to send OTP'});

      return _json(200, {'success': true, 'message': 'OTP sent successfully to email'});
    } catch (e) {
      return _json(500, {'error': 'Failed to send OTP'});
    }
  });

  // ── Verify OTP ────────────────────────────────────────────────────────────
  router.post('/verify-otp', (Request req) async {
    try {
      final body  = await _body(req);
      final email = body['email'] as String?;
      final otp   = body['otp'] as String?;
      if (email == null || otp == null) {
        return _json(400, {'error': 'Email and OTP required'});
      }

      final data = await SupabaseService.verifyOtp(email: email, token: otp);
      if (data == null) return _json(401, {'error': 'Invalid or expired OTP'});

      final user         = data['user'] as Map<String, dynamic>;
      final accessToken  = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      final profiles = await SupabaseService.select(
        'profiles',
        columns: 'id,role,branch_id,full_name,status',
        filters: {'auth_uid': user['id']},
      );

      if (profiles.isEmpty || profiles.first['status'] != 1) {
        return _json(403, {'error': 'Account is inactive or not found'});
      }

      final profile = profiles.first;
      return _json(200, {
        'success': true,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': {
          'id': profile['id'], 'role': profile['role'],
          'name': profile['full_name'], 'branch_id': profile['branch_id'],
          'email': user['email'],
        },
      });
    } catch (e) {
      return _json(500, {'error': 'Failed to verify OTP'});
    }
  });

  // ── Get current user profile ──────────────────────────────────────────────
  router.get('/me', Pipeline()
      .addMiddleware(requireAuth())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      Map<String, dynamic> extraData = {};

      if (session.role == roleStudent) {
        final students = await SupabaseService.select(
          'students',
          columns: 'id,name,reg_no,roll_no,photo_url,course_id,branch_id,status',
          filters: {'profile_id': session.profileId},
        );
        extraData['student'] = students.isNotEmpty ? students.first : null;
      }

      if (session.role == roleTeacher) {
        final employees = await SupabaseService.select(
          'employees',
          columns: 'id,name,designation,department,branch_id',
          filters: {'profile_id': session.profileId},
        );
        extraData['employee'] = employees.isNotEmpty ? employees.first : null;
      }

      return _json(200, {
        'success': true,
        'profile': {
          'id': session.profileId, 'role': session.role,
          'name': session.fullName, 'branch_id': session.branchId,
          'email': session.profile['email'],
          'permissions': session.profile['permissions'] ?? [],
        },
        ...extraData,
      });
    } catch (e) {
      return _json(500, {'error': 'Could not fetch profile'});
    }
  }));

  // ── Refresh token ─────────────────────────────────────────────────────────
  router.post('/refresh', (Request req) async {
    try {
      final body         = await _body(req);
      final refreshToken = body['refresh_token'] as String?;
      if (refreshToken == null) return _json(400, {'error': 'refresh_token required'});

      final data = await SupabaseService.refreshSession(refreshToken);
      if (data == null) return _json(401, {'error': 'Token refresh failed'});

      return _json(200, {
        'success': true,
        'access_token':  data['access_token'],
        'refresh_token': data['refresh_token'],
      });
    } catch (e) {
      return _json(500, {'error': 'Refresh failed'});
    }
  });

  // ── Logout ────────────────────────────────────────────────────────────────
  router.post('/logout', Pipeline()
      .addMiddleware(requireAuth())
      .addHandler((Request req) async {
    try {
      final token = req.context['token'] as String;
      await SupabaseService.signOut(token);
      return _json(200, {'success': true, 'message': 'Logged out'});
    } catch (e) {
      return _json(500, {'error': 'Failed to log out from server'});
    }
  }));

  // ── Admin: Register Branch Admin ──────────────────────────────────────────
  router.post('/admin/register-branch-admin', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('REGISTER_BRANCH_ADMIN'))
      .addHandler((Request req) async {
    try {
      final body = await _body(req);
      final email    = body['email'] as String?;
      final password = body['password'] as String?;
      final name     = body['name'] as String?;

      if (email == null || password == null || name == null) {
        return _json(400, {'error': 'Email, password and name are required'});
      }

      final authUser = await SupabaseService.adminCreateUser(
        email: email, password: password,
        userMetadata: {'name': name},
      );
      final authUid = authUser!['id'] as String;

      Map<String, dynamic> profile;
      try {
        profile = await SupabaseService.insert('profiles', {
          'auth_uid': authUid,
          'full_name': name,
          'role': roleBranchAdmin,
          'status': 1,
          'email': email,
          'permissions': [
            'READ_OWN_PROFILE', 'MARK_ATTENDANCE', 'READ_BRANCH_STUDENTS',
            'UPLOAD_MARKS', 'ENROLL_STUDENT', 'RECORD_FEE', 'SUBMIT_MARKSHEET',
            'ISSUE_ADMIT_CARD', 'READ_BRANCH_FEES', 'MANAGE_NOTICES',
            'ISSUE_CERTIFICATE', 'SETUP_OWN_BRANCH', 'REGISTER_TEACHER',
          ],
        });
      } catch (e) {
        await SupabaseService.adminDeleteUser(authUid);
        return _json(500, {'error': 'Failed to create user profile'});
      }

      return _json(200, {
        'success': true,
        'message': 'Branch Admin registered successfully',
        'user': {'id': profile['id'], 'email': email, 'name': name},
      });
    } catch (e) {
      print('Admin Registration Error: $e');
      return _json(500, {'error': 'Internal server error during registration'});
    }
  }));

  // ── Admin: Register Teacher ───────────────────────────────────────────────
  router.post('/admin/register-teacher', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('REGISTER_TEACHER'))
      .addHandler((Request req) async {
    try {
      final session  = req.context['session'] as UserSession;
      final body     = await _body(req);
      final email    = body['email'] as String?;
      final password = body['password'] as String?;
      final name     = body['name'] as String?;
      // Force branch_admin to use their own branch
      final branchId = session.role == roleBranchAdmin
          ? session.branchId
          : body['branch_id'] as int?;

      if (email == null || password == null || name == null) {
        return _json(400, {'error': 'Email, password and name are required'});
      }

      final authUser = await SupabaseService.adminCreateUser(
        email: email, password: password,
        userMetadata: {'name': name},
      );
      final authUid = authUser!['id'] as String;

      Map<String, dynamic> profile;
      try {
        profile = await SupabaseService.insert('profiles', {
          'auth_uid': authUid,
          'full_name': name,
          'role': roleTeacher,
          'branch_id': branchId,
          'status': 1,
          'email': email,
          'permissions': [
            'READ_OWN_PROFILE', 'MARK_ATTENDANCE',
            'READ_BRANCH_STUDENTS', 'UPLOAD_MARKS',
          ],
        });
      } catch (e) {
        await SupabaseService.adminDeleteUser(authUid);
        return _json(500, {'error': 'Failed to create user profile'});
      }

      try {
        await SupabaseService.insert('employees', {
          'profile_id': profile['id'],
          'name': name,
          'designation': 'Teacher',
          'department': 'Academic',
          'branch_id': branchId,
        });
      } catch (e) {
        print('⚠️ Employee record creation failed: $e');
      }

      return _json(200, {
        'success': true,
        'message': 'Teacher registered successfully',
        'user': {'id': profile['id'], 'email': email, 'name': name},
      });
    } catch (e) {
      print('Teacher Registration Error: $e');
      return _json(500, {'error': 'Internal server error during registration'});
    }
  }));

  // ── Super Admin: Reset Any User Password ─────────────────────────────────
  router.post('/admin/reset-password', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('RESET_USER_PASSWORD'))
      .addHandler((Request req) async {
    try {
      final body            = await _body(req);
      final targetProfileId = body['targetProfileId'] as String?;
      final newPassword     = body['newPassword'] as String?;

      if (targetProfileId == null || newPassword == null) {
        return _json(400, {'error': 'Target profile ID and new password are required'});
      }
      if (newPassword.length < 8) {
        // SEC-4 FIX: raised from 6 to 8 chars
        return _json(400, {'error': 'Password must be at least 8 characters long'});
      }

      final profiles = await SupabaseService.select(
        'profiles',
        columns: 'id,role,branch_id,auth_uid,full_name',
        filters: {'id': targetProfileId},
      );
      if (profiles.isEmpty) {
        return _json(404, {'error': 'Target user profile not found'});
      }

      final target = profiles.first;
      final authUid = target['auth_uid'] as String?;
      if (authUid == null) {
        return _json(400, {'error': 'Target user has no auth account linked.'});
      }

      await SupabaseService.adminUpdateUserById(authUid, password: newPassword);

      return _json(200, {
        'success': true,
        'message': 'Password updated successfully for ${target['full_name']}',
      });
    } catch (e) {
      print('Admin Password Reset Error: $e');
      return _json(500, {'error': 'Internal server error during password reset'});
    }
  }));

  return router;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Future<Map<String, dynamic>> _body(Request req) async {
  final str = await req.readAsString();
  if (str.isEmpty) return {};
  return jsonDecode(str) as Map<String, dynamic>;
}

Response _json(int status, Map<String, dynamic> body) =>
    Response(status,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'});
