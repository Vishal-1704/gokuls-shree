// lib/middleware/auth_middleware.dart
// 6-check JWT + profile validation — direct port of auth.middleware.js
// Attaches UserSession to shelf Request context via request.context['session']

import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/supabase_service.dart';
import '../models/user_session.dart';

/// requireAuth — validates JWT, loads profile, checks status and role.
/// On success: passes Request with context['session'] = UserSession
/// On failure: returns 401/403 immediately (never calls inner)
Middleware requireAuth() {
  return (Handler inner) {
    return (Request request) async {
      try {
        // ── Check 1: Authorization header ───────────────────────────────
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _json(401, {
            'error': 'Authorization header missing or malformed',
            'hint': 'Send: Authorization: Bearer <token>',
          });
        }

        final token = authHeader.substring(7).trim();
        if (token.length < 20) {
          return _json(401, {'error': 'Token too short or empty'});
        }

        // ── Check 2: Validate JWT with Supabase ─────────────────────────
        final user = await SupabaseService.getUser(token);
        if (user == null) {
          return _json(401, {'error': 'Invalid or expired token. Please login again.'});
        }

        // ── Check 3: Fetch profile row ───────────────────────────────────
        final profiles = await SupabaseService.select(
          'profiles',
          columns: 'id,role,branch_id,full_name,status,permissions',
          filters: {'auth_uid': user['id']},
        );

        if (profiles.isEmpty) {
          print('🚨 Auth: No profile for auth_uid=${user['id']}');
          return _json(403, {
            'error': 'Your account has no profile. Contact the administrator.',
          });
        }

        final profile = profiles.first;

        // ── Check 4: Account active (status must be exactly 1) ───────────
        // BUG-6 FIX: use != 1, not == 0 (catches null, 2, etc.)
        if (profile['status'] != 1) {
          print('🚨 Auth: Inactive account profileId=${profile['id']} role=${profile['role']}');
          return _json(403, {
            'error': 'Your account is inactive or suspended. Contact administrator.',
          });
        }

        // ── Check 5: Valid role ──────────────────────────────────────────
        final role = profile['role'] as String? ?? '';
        if (!validRoles.contains(role)) {
          print('🚨 Auth: Invalid role "$role" for profileId=${profile['id']}');
          return _json(403, {'error': 'Invalid role assigned. Contact administrator.'});
        }

        // ── Check 6: Branch assigned for non-super-admin ─────────────────
        final branchId = profile['branch_id'] as int?;
        if (role != 'super_admin' && branchId == null) {
          return _json(403, {
            'error': 'No branch assigned to your account. Contact super admin.',
          });
        }

        // ── Attach session to request context ────────────────────────────
        final session = UserSession(
          userId: user['id'] as String,
          profileId: profile['id'] as String,
          role: role,
          branchId: branchId,
          fullName: profile['full_name'] as String? ?? '',
          profile: profile,
        );

        final updatedRequest = request.change(
          context: {...request.context, 'session': session, 'token': token},
        );

        return inner(updatedRequest);
      } catch (e) {
        print('💥 Auth middleware crash: $e');
        return _json(500, {'error': 'Authentication service error'});
      }
    };
  };
}

/// requireRole — shorthand role whitelist check.
Middleware requireRole(List<String> roles) {
  return (Handler inner) {
    return (Request request) async {
      final session = request.context['session'] as UserSession?;
      if (session == null) return _json(401, {'error': 'Not authenticated'});
      if (!roles.contains(session.role)) {
        print('🚨 Role denied | Required: $roles | Got: ${session.role} | Profile: ${session.profileId}');
        return _json(403, {
          'error': 'Access denied. This section requires: ${roles.join(' or ')}',
        });
      }
      return inner(request);
    };
  };
}

Response _json(int status, Map<String, dynamic> body) =>
    Response(status,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'});
