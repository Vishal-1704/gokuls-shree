// lib/middleware/audit_logger.dart
// Non-blocking audit trail — port of audit.logger.js
// Writes to audit_logs table AFTER the route responds (non-blocking).

import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../config/supabase_service.dart';
import '../models/user_session.dart';

/// auditLog(action) — records sensitive operations to audit_logs table.
/// If DB write fails, logs to console but never crashes the request.
/// BUG-10 FIX: Always place auditLog BEFORE sensitiveLimiter in chain.
Middleware auditLog(String action) {
  return (Handler inner) {
    return (Request request) async {
      final session = request.context['session'] as UserSession?;

      // Read body once for audit (re-inject for handler)
      final bodyStr = await request.readAsString();
      final updatedRequest = request.change(body: bodyStr);

      // Run the actual handler first
      final response = await inner(updatedRequest);

      // Non-blocking audit write
      unawaited(_writeAudit(
        action: action,
        session: session,
        request: request,
        bodyStr: bodyStr,
        responseStatus: response.statusCode,
      ));

      return response;
    };
  };
}

Future<void> _writeAudit({
  required String action,
  required UserSession? session,
  required Request request,
  required String bodyStr,
  required int responseStatus,
}) async {
  try {
    final sanitized = _sanitizeBody(bodyStr);
    final payloadSummary = jsonEncode({
      'params': request.url.queryParameters,
      'body': sanitized,
    });

    await SupabaseService.insert('audit_logs', {
      'action': action,
      'profile_id': session?.profileId,
      'role': session?.role,
      'branch_id': session?.queryBranchId ?? session?.branchId,
      'ip_address': _getIp(request),
      'user_agent': request.headers['user-agent'],
      'request_path': '/${request.url.path}',
      'request_method': request.method,
      'response_status': responseStatus,
      'payload_summary': payloadSummary.length > 500
          ? payloadSummary.substring(0, 500)
          : payloadSummary,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  } catch (e) {
    // Audit failure must NEVER break the app
    print('⚠️  Audit log write failed: $e');
  }
}

Map<String, dynamic> _sanitizeBody(String bodyStr) {
  if (bodyStr.isEmpty) return {};
  try {
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final safe = Map<String, dynamic>.from(body);
    // Never log passwords or tokens
    safe.remove('password');
    safe.remove('password_hash');
    safe.remove('access_token');
    safe.remove('refresh_token');
    return safe;
  } catch (_) {
    return {};
  }
}

String _getIp(Request req) =>
    req.headers['x-forwarded-for']?.split(',').first.trim() ??
    req.headers['x-real-ip'] ??
    'unknown';
