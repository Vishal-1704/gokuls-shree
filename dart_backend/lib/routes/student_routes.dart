// lib/routes/student_routes.dart
// CRUD for students — port of student.routes.js

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_guard.dart';
import '../middleware/audit_logger.dart';
import '../middleware/rate_limiter.dart';
import '../models/user_session.dart';

Router buildStudentRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // ── Student: read own record ──────────────────────────────────────────────
  router.get('/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_PROFILE'))
      .addMiddleware(studentSelfGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final res = await SupabaseService.query(
        'students',
        columns: 'id,name,reg_no,roll_no,adm_no,gender,dob,'
            'contact,email,father_name,mother_name,'
            'qualification,session,doj,course_fee,'
            'reg_fee,admin_fee,discount,'
            'photo_url,signature_url,id_card_issued,status,'
            'courses(id,name,short_name,duration),'
            'branches(id,name,address)',
        queryParams: {'id': 'eq.${session.studentId}'},
      );

      if (res.statusCode != 200) return _json(404, {'error': 'Student record not found'});
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return _json(404, {'error': 'Student record not found'});
      return _json(200, {'success': true, 'data': data.first});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── Admin/Teacher: list students (branch scoped) ──────────────────────────
  router.get('/', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_BRANCH_STUDENTS'))
      .addMiddleware(strictBranchGuard())
      .addHandler((Request req) async {
    try {
      final session  = req.context['session'] as UserSession;
      final params   = req.url.queryParameters;
      final page     = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit    = int.tryParse(params['limit'] ?? '20') ?? 20;
      final search   = params['search'];
      final courseId = params['course_id'];
      final status   = int.tryParse(params['status'] ?? '1') ?? 1;
      final from     = (page - 1) * limit;

      final qp = <String, String>{
        'select': 'id,name,reg_no,roll_no,gender,contact,email,'
            'doj,status,photo_url,id_card_issued,'
            'courses(id,name,short_name),branches(id,name)',
        'status': 'eq.$status',
        'order': 'name.asc',
        'offset': from.toString(),
        'limit': limit.toString(),
      };

      if (session.queryBranchId != null) qp['branch_id'] = 'eq.${session.queryBranchId}';
      if (courseId != null) qp['course_id'] = 'eq.$courseId';
      if (search != null) qp['name'] = 'ilike.*$search*';

      final headers = <String, String>{'Prefer': 'count=exact'};
      final res = await SupabaseService.query('students', queryParams: qp, extraHeaders: headers);

      final count = _parseCount(res.headers['content-range']);
      final data  = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'total': count, 'page': page, 'limit': limit, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── Admin/Teacher: get student by ID ─────────────────────────────────────
  router.get('/<id>', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_BRANCH_STUDENTS'))
      .addMiddleware(strictBranchGuard())
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final session   = req.context['session'] as UserSession;
      final studentId = int.tryParse(id);
      if (studentId == null) return _json(400, {'error': 'Invalid student ID'});

      final qp = <String, String>{
        'select': '*,courses(id,name,short_name,duration),branches(id,name,address,contact)',
        'id': 'eq.$studentId',
      };
      if (session.queryBranchId != null) qp['branch_id'] = 'eq.${session.queryBranchId}';

      final res  = await SupabaseService.query('students', queryParams: qp);
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return _json(404, {'error': 'Student not found in your branch'});
      return _json(200, {'success': true, 'data': data.first});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── Branch Admin / Super Admin: enroll new student ────────────────────────
  router.post('/', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('ENROLL_STUDENT'))
      .addMiddleware(strictBranchGuard())
      .addMiddleware(auditLog('ENROLL_STUDENT'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);

      if (session.role != roleSuperAdmin) {
        body['branch_id'] = session.queryBranchId;
        body['status']    = 0; // Forced pending for branch admins
      }

      if (body['name'] == null || body['course_id'] == null) {
        return _json(400, {'error': 'name and course_id are required'});
      }

      final data = await SupabaseService.insert('students', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── Branch Admin / Super Admin: update student ────────────────────────────
  router.put('/<id>', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('ENROLL_STUDENT'))
      .addMiddleware(strictBranchGuard())
      .addMiddleware(auditLog('UPDATE_STUDENT'))
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final session   = req.context['session'] as UserSession;
      final studentId = int.tryParse(id);
      if (studentId == null) return _json(400, {'error': 'Invalid student ID'});

      final body = await _body(req);
      body['updated_at'] = DateTime.now().toUtc().toIso8601String();
      body.remove('profile_id'); // Never allow profile_id change
      if (session.role != roleSuperAdmin) {
        body['branch_id'] = session.queryBranchId;
        body.remove('status'); // Branch admin cannot approve status
      }

      final filters = <String, dynamic>{'id': studentId};
      if (session.queryBranchId != null) filters['branch_id'] = session.queryBranchId;

      final updated = await SupabaseService.update('students', body, filters: filters);
      if (updated.isEmpty) return _json(404, {'error': 'Student not found or access denied'});
      return _json(200, {'success': true, 'data': updated.first});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── Super Admin ONLY: approve student ────────────────────────────────────
  router.patch('/<id>/approve', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('APPROVE_STUDENT'))
      .addMiddleware(auditLog('APPROVE_STUDENT'))
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final studentId = int.tryParse(id);
      if (studentId == null) return _json(400, {'error': 'Invalid student ID'});

      final updated = await SupabaseService.update('students', {
        'status': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, filters: {'id': studentId});

      if (updated.isEmpty) return _json(404, {'error': 'Student not found or approval failed'});
      return _json(200, {
        'success': true,
        'message': 'Student registration approved successfully',
        'data': updated.first,
      });
    } catch (e) {
      return _json(500, {'error': e.toString()});
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

int _parseCount(String? contentRange) {
  if (contentRange == null) return 0;
  final parts = contentRange.split('/');
  return parts.length > 1 ? (int.tryParse(parts.last) ?? 0) : 0;
}

Response _json(int status, Map<String, dynamic> body) =>
    Response(status,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'});
