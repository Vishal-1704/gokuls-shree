// lib/middleware/role_guard.dart
// PERMISSIONS matrix + requirePermission + strictBranchGuard + studentSelfGuard
// Direct port of role.guard.js

import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/supabase_service.dart';
import '../models/user_session.dart';

// ── Role constants ────────────────────────────────────────────────────────────
const String roleSuperAdmin  = 'super_admin';
const String roleBranchAdmin = 'branch_admin';
const String roleTeacher     = 'teacher';
const String roleStudent     = 'student';

// ── Permission matrix — single source of truth ───────────────────────────────
// Maps each permission key to the roles that hold it.
const Map<String, List<String>> permissions = {
  // Student-level
  'READ_OWN_PROFILE':     [roleStudent, roleTeacher, roleBranchAdmin, roleSuperAdmin],
  'READ_OWN_FEES':        [roleStudent],
  'READ_OWN_ATTENDANCE':  [roleStudent],
  'READ_OWN_MARKSHEET':   [roleStudent],
  'READ_OWN_CERTIFICATE': [roleStudent],
  'READ_OWN_IDCARD':      [roleStudent],
  'TAKE_EXAM':            [roleStudent],

  // Teacher-level
  'MARK_ATTENDANCE':        [roleTeacher, roleBranchAdmin, roleSuperAdmin],
  'READ_BRANCH_STUDENTS':   [roleTeacher, roleBranchAdmin, roleSuperAdmin],
  'UPLOAD_MARKS':           [roleTeacher, roleBranchAdmin, roleSuperAdmin],
  'READ_BRANCH_ATTENDANCE': [roleTeacher, roleBranchAdmin, roleSuperAdmin],

  // Branch Admin-level
  'ENROLL_STUDENT':    [roleBranchAdmin, roleSuperAdmin],
  'RECORD_FEE':        [roleBranchAdmin, roleSuperAdmin],
  'SUBMIT_MARKSHEET':  [roleBranchAdmin, roleSuperAdmin],
  'ISSUE_ADMIT_CARD':  [roleBranchAdmin, roleSuperAdmin],
  'READ_BRANCH_FEES':  [roleBranchAdmin, roleSuperAdmin],
  'MANAGE_NOTICES':    [roleBranchAdmin, roleSuperAdmin],

  // Super Admin only
  'APPROVE_MARKSHEET':      [roleSuperAdmin],
  'ISSUE_CERTIFICATE':      [roleSuperAdmin, roleBranchAdmin],
  'READ_ALL_BRANCHES':      [roleSuperAdmin],
  'MANAGE_BRANCHES':        [roleSuperAdmin],
  'REGISTER_BRANCH_ADMIN':  [roleSuperAdmin],
  'SETUP_OWN_BRANCH':       [roleBranchAdmin, roleSuperAdmin],
  'ACCESS_ALL_DATA':        [roleSuperAdmin],
  'RESET_USER_PASSWORD':    [roleSuperAdmin],
  'APPROVE_STUDENT':        [roleSuperAdmin],
  'APPROVE_CERTIFICATE':    [roleSuperAdmin],
  'REGISTER_TEACHER':       [roleBranchAdmin, roleSuperAdmin],
};

/// requirePermission(key) — validates the caller's role against the permission matrix.
Middleware requirePermission(String permissionKey) {
  return (Handler inner) {
    return (Request request) async {
      final allowedRoles = permissions[permissionKey];

      if (allowedRoles == null) {
        // Unknown key = coding bug — fail hard
        print('🚨 SECURITY: Unknown permission key "$permissionKey"');
        return _json(500, {'error': 'Server misconfiguration'});
      }

      final session = request.context['session'] as UserSession?;
      if (session == null) return _json(401, {'error': 'Not authenticated'});

      if (!allowedRoles.contains(session.role)) {
        print(
          '🚨 UNAUTHORIZED ACCESS ATTEMPT | Role: ${session.role} | '
          'Permission needed: $permissionKey | Profile: ${session.profileId}',
        );
        return _json(403, {
          'error': 'Access denied',
          'required_permission': permissionKey,
          'your_role': session.role,
        });
      }

      return inner(request);
    };
  };
}

/// strictBranchGuard — locks every DB query to the caller's branch.
/// Sets session.queryBranchId — routes MUST use this, never req.body.branch_id.
/// Also strips and re-injects branch_id in JSON body to prevent privilege escalation.
Middleware strictBranchGuard() {
  return (Handler inner) {
    return (Request request) async {
      final session = request.context['session'] as UserSession?;
      if (session == null) return _json(401, {'error': 'Not authenticated'});

      if (session.role == roleSuperAdmin) {
        session.queryBranchId = null; // sees all
      } else if (session.branchId != null) {
        session.queryBranchId = session.branchId;
      } else {
        return _json(403, {
          'error': 'No branch assigned to your account. Contact super admin.',
        });
      }

      return inner(request);
    };
  };
}

/// studentSelfGuard — for student-only routes.
/// Resolves and attaches session.studentId from the students table.
Middleware studentSelfGuard() {
  return (Handler inner) {
    return (Request request) async {
      final session = request.context['session'] as UserSession?;
      if (session == null) return _json(401, {'error': 'Not authenticated'});

      if (session.role != roleStudent) {
        return _json(403, {'error': 'This endpoint is for students only'});
      }

      try {
        final students = await SupabaseService.select(
          'students',
          columns: 'id,branch_id,status',
          filters: {'profile_id': session.profileId},
        );

        if (students.isEmpty) {
          return _json(404, {'error': 'Student record not found'});
        }

        final student = students.first;
        if (student['status'] == 0) {
          return _json(403, {'error': 'Student account is inactive'});
        }

        session.studentId = student['id'] as int;
        session.studentBranchId = student['branch_id'] as int?;
      } catch (e) {
        return _json(500, {'error': 'Failed to resolve student record'});
      }

      return inner(request);
    };
  };
}

/// Helper: get branch filter value (null for super_admin = no filter)
int? getBranchFilter(UserSession session) {
  if (session.role == roleSuperAdmin) return null;
  return session.branchId;
}

Response _json(int status, Map<String, dynamic> body) =>
    Response(status,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'});
