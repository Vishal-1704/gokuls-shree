// lib/routes/mock_auth_routes.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildMockAuthRouter() {
  final router = Router();

  router.post('/mock-login', (Request req) async {
    try {
      final payload = await req.readAsString();
      final body = payload.isNotEmpty ? jsonDecode(payload) as Map<String, dynamic> : {};
      final role = (body['role'] as String?)?.toLowerCase() ?? 'super_admin';

      Map<String, dynamic> userSession;

      if (role == 'teacher') {
        userSession = {
          'user': {
            'id': 'mock-teacher-uuid-002',
            'email': 'teacher@gokulshree.com',
            'phone': '9876543211',
            'user_metadata': {'full_name': 'Dr. Rajesh Sharma', 'role': 'teacher'},
          },
          'profile': {
            'id': 'mock-teacher-uuid-002',
            'role': 'teacher',
            'name': 'Dr. Rajesh Sharma',
            'email': 'teacher@gokulshree.com',
            'branch_id': 1,
            'department': 'Computer Science',
            'designation': 'Senior Lecturer',
          },
          'permissions': [
            'MARK_ATTENDANCE',
            'READ_BRANCH_STUDENTS',
            'UPLOAD_MARKS',
            'mark_attendance',
            'view_students',
            'upload_results'
          ],
          'access_token': 'mock-teacher-jwt-token-xyz',
          'expires_in': 86400,
        };
      } else if (role == 'student') {
        userSession = {
          'user': {
            'id': 'mock-student-uuid-003',
            'email': 'student@gokulshree.com',
            'phone': '9876543212',
            'user_metadata': {'full_name': 'Ananya Verma', 'role': 'student'},
          },
          'profile': {
            'id': 'mock-student-uuid-003',
            'role': 'student',
            'name': 'Ananya Verma',
            'email': 'student@gokulshree.com',
            'branch_id': 1,
            'course': 'B.Tech CS',
            'batch': '2024-2028',
          },
          'permissions': ['READ_OWN_PROFILE', 'VIEW_ATTENDANCE', 'VIEW_MARKS'],
          'access_token': 'mock-student-jwt-token-xyz',
          'expires_in': 86400,
        };
      } else {
        // Super Admin
        userSession = {
          'user': {
            'id': 'mock-superadmin-uuid-001',
            'email': 'superadmin@gokulshree.com',
            'phone': '9876543210',
            'user_metadata': {'full_name': 'Super Administrator', 'role': 'super_admin'},
          },
          'profile': {
            'id': 'mock-superadmin-uuid-001',
            'role': 'super_admin',
            'name': 'Super Administrator',
            'email': 'superadmin@gokulshree.com',
            'branch_id': 1,
            'department': 'Management',
            'designation': 'Head Admin',
          },
          'permissions': [
            'SUPER_ADMIN',
            'ALL',
            'MARK_ATTENDANCE',
            'READ_BRANCH_STUDENTS',
            'UPLOAD_MARKS',
            'MANAGE_EMPLOYEES',
            'APPROVE_CERTIFICATES'
          ],
          'access_token': 'mock-superadmin-jwt-token-xyz',
          'expires_in': 86400,
        };
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Mock login successful',
          'session': userSession,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
