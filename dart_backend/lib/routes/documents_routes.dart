// lib/routes/documents_routes.dart
// Marksheets, certificates, admit cards, ID cards, PDF generation
// SEC-2 FIX: generate_pdf route now requires authentication

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_guard.dart';
import '../middleware/audit_logger.dart';
import '../middleware/rate_limiter.dart';
import '../models/user_session.dart';
import '../services/document_service.dart';

Router buildDocumentsRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // SEC-2 FIX: Added requireAuth — was unauthenticated in JS!
  // PDF generation now requires at least a valid session.
  router.post('/generate_pdf', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_MARKSHEET'))
      .addHandler((Request req) async {
    try {
      final body = await _body(req);
      final regno = body['regno'] as String?;
      final type  = body['type'] as String?;

      if (regno == null || type == null) {
        return _json(400, {'error': 'regno and type are required'});
      }

      final pdfBytes = await DocumentService.generatePdf(regno: regno, type: type);
      return Response.ok(pdfBytes, headers: {'Content-Type': 'application/pdf'});
    } catch (e) {
      print('PDF generation error: $e');
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── MARKSHEETS ────────────────────────────────────────────────────────────

  // Student: own marksheets — APPROVED ONLY (status=1)
  router.get('/marksheet/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_MARKSHEET'))
      .addMiddleware(studentSelfGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final res = await SupabaseService.query('marksheets', queryParams: {
        'select': 'id,roll_no,session,marks,total_marks,obtained_marks,'
            'percentage,grade,result,marksheet_sl_no,certificate_sl_no,'
            'marksheet_month,marksheet_year,issue_date,status,'
            'courses(id,name,short_name)',
        'student_id': 'eq.${session.studentId}',
        'status': 'eq.1',   // HARD FILTER: students only see APPROVED
        'order': 'created_at.desc',
      });
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'count': data.length, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Admin/Teacher: list marksheets (branch scoped, all statuses)
  router.get('/marksheets', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_BRANCH_STUDENTS'))
      .addMiddleware(strictBranchGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final params  = req.url.queryParameters;
      final page    = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit   = int.tryParse(params['limit'] ?? '20') ?? 20;
      final from    = (page - 1) * limit;

      final qp = <String, String>{
        'select': 'id,roll_no,session,percentage,grade,result,status,'
            'marksheet_sl_no,created_at,'
            'students(id,name,reg_no),courses(id,name,short_name)',
        'order': 'created_at.desc',
        'offset': from.toString(),
        'limit': limit.toString(),
      };
      if (session.queryBranchId != null) qp['branch_id'] = 'eq.${session.queryBranchId}';
      if (params['status'] != null)      qp['status']    = 'eq.${params['status']}';
      if (params['student_id'] != null)  qp['student_id'] = 'eq.${params['student_id']}';

      final headers = <String, String>{'Prefer': 'count=exact'};
      final res   = await SupabaseService.query('marksheets', queryParams: qp, extraHeaders: headers);
      final count = _parseCount(res.headers['content-range']);
      final data  = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'total': count, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Branch Admin: submit marksheet
  router.post('/marksheets', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('SUBMIT_MARKSHEET'))
      .addMiddleware(strictBranchGuard())
      .addMiddleware(sensitiveLimiter.middleware)
      .addMiddleware(auditLog('SUBMIT_MARKSHEET'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);

      body['branch_id']   = session.queryBranchId;
      body['status']      = 0; // Always pending — super_admin must approve
      body['submitted_by'] = session.profileId;

      if (body['student_id'] == null) {
        return _json(400, {'error': 'student_id is required'});
      }

      final data = await SupabaseService.insert('marksheets', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Super Admin: approve marksheet
  router.patch('/marksheets/<id>/approve', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('APPROVE_MARKSHEET'))
      .addMiddleware(sensitiveLimiter.middleware)
      .addMiddleware(auditLog('APPROVE_MARKSHEET'))
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final session     = req.context['session'] as UserSession;
      final marksheetId = int.tryParse(id);
      if (marksheetId == null) return _json(400, {'error': 'Invalid marksheet ID'});

      final updated = await SupabaseService.update('marksheets', {
        'status': 1,
        'approved_by': session.profileId,
        'approved_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at':  DateTime.now().toUtc().toIso8601String(),
      }, filters: {'id': marksheetId});

      if (updated.isEmpty) return _json(404, {'error': 'Marksheet not found'});
      return _json(200, {'success': true, 'data': updated.first});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── CERTIFICATES ──────────────────────────────────────────────────────────

  // Student: own certificates (approved only)
  router.get('/certificates/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_CERTIFICATE'))
      .addMiddleware(studentSelfGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final res = await SupabaseService.query('certificates', queryParams: {
        'select': 'id,certificate_no,issue_date,session,certificate_url,status,'
            'courses(id,name,short_name)',
        'student_id': 'eq.${session.studentId}',
        'status': 'eq.1',
        'order': 'created_at.desc',
      });
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Super Admin: issue certificate
  router.post('/certificates', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('ISSUE_CERTIFICATE'))
      .addMiddleware(sensitiveLimiter.middleware)
      .addMiddleware(auditLog('ISSUE_CERTIFICATE'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);
      body['issued_by'] = session.profileId;
      body['status']    = 1; // Issued = already approved

      final data = await SupabaseService.insert('certificates', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // ── EXPERIENCE CERTIFICATES ─────────────────────────────────────────────────

  // Employee: request an experience certificate
  router.post('/experience-certificates/request', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      
      // Need to find the employee_id from profile_id
      final emps = await SupabaseService.select('employees', columns: 'id,branch_id', filters: {'profile_id': session.profileId});
      if (emps.isEmpty) return _json(404, {'error': 'Employee record not found for this user.'});
      final empId = emps.first['id'];
      final branchId = emps.first['branch_id'];

      final body = {
        'employee_id': empId,
        'branch_id': branchId,
        'status': 0, // Pending
        'request_date': DateTime.now().toUtc().toIso8601String(),
      };

      final data = await SupabaseService.insert('experience_certificates', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Employee: get their own requests
  router.get('/experience-certificates/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final emps = await SupabaseService.select('employees', columns: 'id', filters: {'profile_id': session.profileId});
      if (emps.isEmpty) return _json(200, {'success': true, 'data': []});
      
      final empId = emps.first['id'];
      final res = await SupabaseService.query('experience_certificates', queryParams: {
        'select': '*, employees(name, designation)',
        'employee_id': 'eq.$empId',
        'order': 'created_at.desc',
      });
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Super Admin: list all requests
  router.get('/experience-certificates', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('APPROVE_CERTIFICATE'))
      .addHandler((Request req) async {
    try {
      final res = await SupabaseService.query('experience_certificates', queryParams: {
        'select': '*, employees(name, designation, department, doj)',
        'order': 'created_at.desc',
      });
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Super Admin: approve request
  router.patch('/experience-certificates/<id>/approve', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('APPROVE_CERTIFICATE'))
      .addMiddleware(auditLog('APPROVE_EXPERIENCE_CERT'))
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final session = req.context['session'] as UserSession;
      final certId = int.tryParse(id);
      if (certId == null) return _json(400, {'error': 'Invalid ID'});

      // Fetch the cert and employee details to generate PDF
      final certs = await SupabaseService.select('experience_certificates', columns: '*, employees(*)', filters: {'id': certId});
      if (certs.isEmpty) return _json(404, {'error': 'Request not found'});

      final updated = await SupabaseService.update('experience_certificates', {
        'status': 1,
        'approved_by': session.profileId,
        'issue_date': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, filters: {'id': certId});

      return _json(200, {'success': true, 'data': updated.first});
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
