import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_guard.dart';
import '../middleware/rate_limiter.dart';
import '../models/user_session.dart';

Router buildEmployeesRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // Super Admin / Admin: update employee details
  router.put('/<id>', Pipeline()
      .addMiddleware(rateLimit)
      .addMiddleware(requireAuth())
      .addMiddleware(requirePermission('MANAGE_STAFF'))
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final body = await _body(req);
      final empId = int.tryParse(id);
      
      if (empId == null) {
        return _json(400, {'error': 'Invalid employee ID'});
      }

      // Allow updating all Zoho fields
      final updateData = {
        if (body.containsKey('name')) 'name': body['name'],
        if (body.containsKey('email')) 'email': body['email'],
        if (body.containsKey('contact')) 'contact': body['contact'],
        if (body.containsKey('address')) 'address': body['address'],
        if (body.containsKey('designation')) 'designation': body['designation'],
        if (body.containsKey('department')) 'department': body['department'],
        if (body.containsKey('doj')) 'doj': body['doj'],
        if (body.containsKey('basic_salary')) 'basic_salary': body['basic_salary'],
        if (body.containsKey('hra')) 'hra': body['hra'],
        if (body.containsKey('da')) 'da': body['da'],
        if (body.containsKey('other_allowance')) 'other_allowance': body['other_allowance'],
        if (body.containsKey('pf_account_no')) 'pf_account_no': body['pf_account_no'],
        if (body.containsKey('pan_no')) 'pan_no': body['pan_no'],
        if (body.containsKey('esi_no')) 'esi_no': body['esi_no'],
        if (body.containsKey('causal_leave')) 'causal_leave': body['causal_leave'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final updated = await SupabaseService.update('employees', updateData, filters: {'id': empId});
      
      if (updated.isEmpty) {
        return _json(404, {'error': 'Employee not found'});
      }
      
      return _json(200, {'success': true, 'data': updated.first});
    } catch (e) {
      return _json(500, {'error': e.toString()});
    }
  }));

  return router;
}

Future<Map<String, dynamic>> _body(Request req) async {
  final str = await req.readAsString();
  if (str.isEmpty) return {};
  return jsonDecode(str) as Map<String, dynamic>;
}

Response _json(int status, Map<String, dynamic> body) =>
    Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
