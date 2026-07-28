// lib/routes/fee_routes.dart + attendance_routes.dart + notice_routes.dart + course_routes.dart + branch_routes.dart
// All remaining routes in a single pass — port of their JS equivalents

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_guard.dart';
import '../middleware/audit_logger.dart';
import '../middleware/rate_limiter.dart';
import '../models/user_session.dart';

// ═══════════════════════════════════════════════════════════════
// FEE ROUTES — port of fee.routes.js
// BUG-10 FIX: sensitiveLimiter placed BEFORE auditLog
// ═══════════════════════════════════════════════════════════════
Router buildFeeRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // Student: own fee history
  router.get('/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_FEES'))
      .addMiddleware(studentSelfGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;

      final students = await SupabaseService.select(
        'students',
        columns: 'id,course_fee,reg_fee,admin_fee,discount',
        filters: {'id': session.studentId},
      );
      if (students.isEmpty) return _json(404, {'error': 'Student record not found'});
      final student = students.first;

      final fees = await SupabaseService.select(
        'fee_payments',
        columns: 'id,receipt_no,payment_date,amount,net_pay,payment_mode,description,next_due_date',
        filters: {'student_id': session.studentId},
        order: 'payment_date.desc',
      );

      final totalPaid = fees.fold<double>(0, (s, f) => s + ((f['net_pay'] as num?)?.toDouble() ?? 0));
      final totalFee  = ((student['course_fee'] as num?)?.toDouble() ?? 0) +
                        ((student['reg_fee'] as num?)?.toDouble() ?? 0) +
                        ((student['admin_fee'] as num?)?.toDouble() ?? 0);
      final discount  = (student['discount'] as num?)?.toDouble() ?? 0;
      final totalDue  = (totalFee - discount - totalPaid).clamp(0, double.infinity);

      return _json(200, {
        'success': true,
        'summary': {
          'total_fee': totalFee,
          'discount': discount,
          'total_paid': totalPaid,
          'balance_due': totalDue,
        },
        'payments': fees,
      });
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Admin: list all fees (branch filtered)
  router.get('/', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_BRANCH_FEES'))
      .addMiddleware(strictBranchGuard())
      .addHandler((Request req) async {
    try {
      final session  = req.context['session'] as UserSession;
      final params   = req.url.queryParameters;
      final page     = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit    = int.tryParse(params['limit'] ?? '20') ?? 20;
      final studentId = params['student_id'];
      final from     = (page - 1) * limit;

      final qp = <String, String>{
        'select': 'id,receipt_no,payment_date,amount,net_pay,fine,'
            'payment_mode,description,next_due_date,'
            'students(id,name,reg_no),branches(id,name)',
        'order': 'payment_date.desc',
        'offset': from.toString(),
        'limit': limit.toString(),
      };
      if (session.queryBranchId != null) qp['branch_id'] = 'eq.${session.queryBranchId}';
      if (studentId != null) qp['student_id'] = 'eq.$studentId';

      final headers = <String, String>{'Prefer': 'count=exact'};
      final res = await SupabaseService.query('fee_payments', queryParams: qp, extraHeaders: headers);
      final count = _parseCount(res.headers['content-range']);
      final data  = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'total': count, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Record fee payment
  // BUG-10 FIX: sensitiveLimiter → auditLog (not the other way around)
  router.post('/', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('RECORD_FEE'))
      .addMiddleware(strictBranchGuard())
      .addMiddleware(sensitiveLimiter.middleware) // ← rate limit BEFORE audit
      .addMiddleware(auditLog('RECORD_FEE'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);

      body['branch_id']   = session.queryBranchId;
      body['recorded_by'] = session.profileId;

      if (body['student_id'] == null || body['net_pay'] == null) {
        return _json(400, {'error': 'student_id and net_pay are required'});
      }

      final data = await SupabaseService.insert('fee_payments', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  return router;
}

// ═══════════════════════════════════════════════════════════════
// ATTENDANCE ROUTES — port of attendance.routes.js
// ═══════════════════════════════════════════════════════════════
Router buildAttendanceRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // Student: own attendance
  router.get('/me', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_OWN_ATTENDANCE'))
      .addMiddleware(studentSelfGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final params  = req.url.queryParameters;
      final month   = params['month'];
      final year    = params['year'];

      final qp = <String, String>{
        'select': 'id,attendance_date,status,month,year',
        'student_id': 'eq.${session.studentId}',
        'order': 'attendance_date.desc',
      };
      if (month != null) qp['month'] = 'eq.$month';
      if (year != null)  qp['year']  = 'eq.$year';

      final res  = await SupabaseService.query('student_attendance', queryParams: qp);
      final data = jsonDecode(res.body) as List;

      final present = data.where((d) => d['status'] == 'P').length;
      final absent  = data.where((d) => d['status'] == 'A').length;
      final late    = data.where((d) => d['status'] == 'L').length;
      final pct     = data.isNotEmpty
          ? '${(present / data.length * 100).toStringAsFixed(1)}%'
          : '0%';

      return _json(200, {
        'success': true,
        'summary': {'total': data.length, 'present': present, 'absent': absent, 'late': late, 'percentage': pct},
        'records': data,
      });
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Teacher/Admin: mark attendance (upsert)
  router.post('/mark', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('MARK_ATTENDANCE'))
      .addMiddleware(strictBranchGuard())
      .addMiddleware(sensitiveLimiter.middleware)
      .addMiddleware(auditLog('MARK_ATTENDANCE'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);
      final date    = body['date'] as String?;
      final records = body['records'] as List?;

      if (date == null || records == null || records.isEmpty) {
        return _json(400, {'error': 'date and records[] required'});
      }

      final d = DateTime.parse(date);
      final rows = records.map((r) => {
        'student_id':      r['student_id'],
        'branch_id':       session.queryBranchId,
        'attendance_date': date,
        'status':          r['status'],
        'month':           d.month,
        'year':            d.year,
        'marked_by':       session.profileId,
      }).toList();

      final upserted = await SupabaseService.upsert(
        'student_attendance', rows,
        onConflict: 'student_id,attendance_date',
      );
      return _json(200, {'success': true, 'marked': upserted.length});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  // Admin: list attendance (branch filtered)
  router.get('/', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('READ_BRANCH_ATTENDANCE'))
      .addMiddleware(strictBranchGuard())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final params  = req.url.queryParameters;

      final qp = <String, String>{
        'select': 'id,attendance_date,status,month,year,students(id,name,reg_no)',
        'order': 'attendance_date.desc',
      };
      if (session.queryBranchId != null) qp['branch_id'] = 'eq.${session.queryBranchId}';
      if (params['date'] != null)       qp['attendance_date'] = 'eq.${params['date']}';
      if (params['month'] != null)      qp['month'] = 'eq.${params['month']}';
      if (params['year'] != null)       qp['year']  = 'eq.${params['year']}';
      if (params['student_id'] != null) qp['student_id'] = 'eq.${params['student_id']}';

      final res  = await SupabaseService.query('student_attendance', queryParams: qp);
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'total': data.length, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  return router;
}

// ═══════════════════════════════════════════════════════════════
// NOTICE ROUTES — port of notice.routes.js
// ═══════════════════════════════════════════════════════════════
Router buildNoticeRouter() {
  final router = Router();

  router.get('/', Pipeline()
      .addMiddleware(requireAuth())
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final qp = <String, String>{
        'select': 'id,title,content,type,published_at',
        'status': 'eq.1',
        'order': 'published_at.desc',
        'limit': '50',
      };

      // Students/Teachers see their branch + public notices
      if (['student', 'teacher'].contains(session.role) && session.branchId != null) {
        qp['or'] = '(branch_id.eq.${session.branchId},is_public.eq.true)';
        qp.remove('status');
        qp['status'] = 'eq.1';
      } else if (session.role == roleBranchAdmin && session.branchId != null) {
        qp['branch_id'] = 'eq.${session.branchId}';
      }
      // super_admin: no filter = sees all

      final res  = await SupabaseService.query('notices', queryParams: qp);
      final data = jsonDecode(res.body) as List;
      return _json(200, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  router.post('/', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requireRole([roleSuperAdmin, roleBranchAdmin]))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      final body    = await _body(req);
      body['created_by'] = session.profileId;
      if (session.role == roleBranchAdmin) body['branch_id'] = session.branchId;

      final data = await SupabaseService.insert('notices', body);
      return _json(201, {'success': true, 'data': data});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  return router;
}

// ═══════════════════════════════════════════════════════════════
// COURSE ROUTES — port of course.routes.js
// BUG-4 FIX: use 'name' instead of 'title', add 'description' column
// ═══════════════════════════════════════════════════════════════
Router buildCourseRouter() {
  final router = Router();

  // Public: get all courses
  router.get('/', (Request req) async {
    try {
      final category = req.url.queryParameters['category'];

      final qp = <String, String>{
        'select': '*',
        'status': 'eq.1',
        'order': 'name.asc', // BUG-4 FIX: was 'title', schema has 'name'
      };
      if (category != null) qp['category'] = 'eq.$category';

      final res  = await SupabaseService.query('courses', queryParams: qp);
      final data = jsonDecode(res.body) as List;

      return _json(200, {
        'count': data.length,
        'courses': data.map((row) => {
          'id':          row['id'].toString(),
          'title':       row['name'],        // BUG-4 FIX: map name→title for API consumers
          'short_name':  row['short_name'],
          'category':    row['category'],
          'duration':    row['duration'],
          'description': row['description'] ?? '', // safe null
          'imageUrl':    row['image_url'],
        }).toList(),
      });
    } catch (e) {
      return _json(500, {'error': 'Failed to fetch courses'});
    }
  });

  // Public: get course by ID
  router.get('/<id>', (Request req, String id) async {
    try {
      final courseId = int.tryParse(id);
      if (courseId == null) return _json(400, {'error': 'Invalid course ID'});

      final res  = await SupabaseService.query('courses',
          queryParams: {'select': '*', 'id': 'eq.$courseId', 'status': 'eq.1'});
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return _json(404, {'error': 'Course not found'});

      final row = data.first;
      return _json(200, {
        'id':          row['id'].toString(),
        'title':       row['name'],
        'short_name':  row['short_name'],
        'category':    row['category'],
        'duration':    row['duration'],
        'description': row['description'] ?? '',
        'imageUrl':    row['image_url'],
      });
    } catch (e) {
      return _json(500, {'error': 'Failed to fetch course'});
    }
  });

  // Public: course categories
  router.get('/meta/categories', (Request req) async {
    try {
      final res  = await SupabaseService.query('courses',
          queryParams: {'select': 'category', 'status': 'eq.1'});
      final data = jsonDecode(res.body) as List;

      final categories = data
          .map((r) => r['category'] as String?)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

      return _json(200, {'categories': categories});
    } catch (e) {
      return _json(500, {'error': 'Failed to fetch categories'});
    }
  });

  return router;
}

// ═══════════════════════════════════════════════════════════════
// BRANCH ROUTES — port of branch.routes.js
// BUG-3 FIX: admin_id column (requires migration 012)
// BUG-9 FIX: contact column (not contact_phone)
// ═══════════════════════════════════════════════════════════════
Router buildBranchRouter() {
  final router = Router();

  router.get('/my-branch', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('SETUP_OWN_BRANCH'))
      .addHandler((Request req) async {
    try {
      final session = req.context['session'] as UserSession;
      if (session.branchId == null && session.role != roleSuperAdmin) {
        return _json(200, {'setup_required': true});
      }

      final res  = await SupabaseService.query('branches',
          queryParams: {'select': '*', 'id': 'eq.${session.branchId}'});
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return _json(200, {'setup_required': true});
      return _json(200, {'success': true, 'branch': data.first});
    } catch (e) {
      return _json(500, {'error': 'Failed to fetch branch details'});
    }
  }));

  router.post('/setup', Pipeline()
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('SETUP_OWN_BRANCH'))
      .addHandler((Request req) async {
    try {
      final session     = req.context['session'] as UserSession;
      final body        = await _body(req);
      final name        = body['name'] as String?;
      final code        = body['code'] as String?;
      final ownerName   = body['owner_name'] as String?;
      final contactPhone = body['contact_phone'] as String?; // user sends contact_phone
      final addr        = body['address'] as String?;

      if (name == null || code == null) {
        return _json(400, {'error': 'Branch name and code are required'});
      }

      // Check if branch already exists for this admin (BUG-3 FIX: uses admin_id column after migration 012)
      final existing = await SupabaseService.query('branches',
          queryParams: {'select': 'id', 'admin_id': 'eq.${session.userId}'});
      final existingData = jsonDecode(existing.body) as List;

      int branchId;
      if (existingData.isNotEmpty) {
        // Update
        final updated = await SupabaseService.update('branches', {
          'name': name,
          'code': code,
          'owner_name': ownerName,
          'contact': contactPhone, // BUG-9 FIX: column is 'contact' not 'contact_phone'
          'address': addr,
        }, filters: {'id': existingData.first['id']});
        branchId = updated.first['id'] as int;
      } else {
        // Create
        final created = await SupabaseService.insert('branches', {
          'admin_id': session.userId, // requires migration 012 to add this column
          'name': name,
          'code': code,
          'owner_name': ownerName,
          'contact': contactPhone,   // BUG-9 FIX: schema uses 'contact'
          'address': addr,
        });
        branchId = created['id'] as int;

        // Link profile to branch
        await SupabaseService.update('profiles', {'branch_id': branchId},
            filters: {'id': session.profileId});
      }

      return _json(200, {
        'success': true,
        'message': 'Franchise setup completed successfully',
        'branch_id': branchId,
      });
    } catch (e) {
      print('Franchise Setup Error: $e');
      return _json(500, {'error': 'Failed to setup franchise'});
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
