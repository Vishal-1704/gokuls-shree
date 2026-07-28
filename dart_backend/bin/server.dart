// bin/server.dart
// Gokul Shree School — Dart Backend Entry Point
// Architecture: shelf + shelf_router (equivalent of Express.js)
//
// Security layers (outermost → innermost):
//   1. CORS whitelist
//   2. Security headers (Helmet-equivalent)
//   3. Request logging (Morgan-equivalent)
//   4. Rate limiter (login: 5/15min, API: 120/min)
//   5. requireAuth (JWT + profile + status check)
//   6. requirePermission (role whitelist)
//   7. strictBranchGuard (branch isolation)
//   8. studentSelfGuard (own-record only)
//   9. Supabase RLS (database-level final defense)
//  10. auditLog (every sensitive action recorded)

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import '../lib/config/supabase_service.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/student_routes.dart';
import '../lib/routes/other_routes.dart';
import '../lib/routes/documents_routes.dart';
import '../lib/routes/employees_routes.dart';
import '../lib/routes/download_routes.dart';
import '../lib/routes/mock_auth_routes.dart';
import '../lib/utils/logger.dart';

void main() async {
  AppLogger.init();
  // Load .env file
  var env = dotenv.DotEnv(includePlatformEnvironment: true)..load();

  // ── Environment ──────────────────────────────────────────────────────────
  final supabaseUrl    = env['SUPABASE_URL']         ?? '';
  final serviceKey     = env['SUPABASE_SERVICE_KEY'] ?? '';
  final anonKey        = env['SUPABASE_ANON_KEY']    ?? '';
  final allowedOrigins = (env['ALLOWED_ORIGINS'] ?? '*')
      .split(',')
      .map((s) => s.trim())
      .toList();
  final port           = int.tryParse(env['PORT'] ?? '3001') ?? 3001;
  final apiVersion     = env['API_VERSION'] ?? 'v1';
  final apiBase        = '/api/$apiVersion';

  if (supabaseUrl.isEmpty || serviceKey.isEmpty) {
    AppLogger.error('❌ SUPABASE_URL and SUPABASE_SERVICE_KEY must be set');
    exit(1);
  }

  // ── Init Supabase ────────────────────────────────────────────────────────
  SupabaseService.init(
    supabaseUrl: supabaseUrl,
    serviceKey: serviceKey,
    anonKey: anonKey,
  );

  // ── Build CORS handler ────────────────────────────────────────────────────
  final corsMiddleware = corsHeaders(
    headers: {
      ACCESS_CONTROL_ALLOW_ORIGIN:  allowedOrigins.contains('*') ? '*' : allowedOrigins.first,
      ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      ACCESS_CONTROL_ALLOW_HEADERS: 'Content-Type, Authorization',
      ACCESS_CONTROL_EXPOSE_HEADERS: 'X-RateLimit-Limit, X-RateLimit-Remaining',
    },
  );

  // ── Build main router ─────────────────────────────────────────────────────
  final router = Router();

  // Health checks — public, no auth
  router.get('/',       (Request req) => Response.ok('{"app":"Gokul Shree API","version":"$apiVersion","status":"online"}',
      headers: {'Content-Type': 'application/json'}));
  router.get('/health', (Request req) => Response.ok(
      '{"status":"ok","timestamp":"${DateTime.now().toUtc().toIso8601String()}"}',
      headers: {'Content-Type': 'application/json'}));
  router.get('/ping',   (Request req) => Response.ok('pong'));

  // Mount route modules
  router.mount('$apiBase/auth/',       buildAuthRouter().call);
  router.mount('$apiBase/students/',   buildStudentRouter().call);
  router.mount('$apiBase/fees/',       buildFeeRouter().call);
  router.mount('$apiBase/attendance/', buildAttendanceRouter().call);
  router.mount('$apiBase/notices/',    buildNoticeRouter().call);
  router.mount('$apiBase/courses/',    buildCourseRouter().call);
  router.mount('$apiBase/branches/',   buildBranchRouter().call);
  router.mount('$apiBase/documents/',  buildDocumentsRouter().call);
  router.mount('$apiBase/employees/',  buildEmployeesRouter().call);
  router.mount('$apiBase/downloads/',  buildDownloadRouter().call);
  router.mount('$apiBase/auth/mock/',  buildMockAuthRouter().call);
  router.mount('$apiBase/mock/',       buildMockAuthRouter().call);

  // ── 404 handler ───────────────────────────────────────────────────────────
  router.all('/<ignored|.*>', (Request req) {
    return Response.notFound(
        '{"error":"Route ${req.method} ${req.url.path} not found"}',
        headers: {'Content-Type': 'application/json'});
  });

  // ── Middleware pipeline ───────────────────────────────────────────────────
  final handler = Pipeline()
      .addMiddleware(corsMiddleware)
      .addMiddleware(_securityHeaders())
      .addMiddleware(_requestLogger())
      .addHandler(router.call);

  // ── Start server ──────────────────────────────────────────────────────────
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  AppLogger.info('\n🚀 Gokul Shree Dart API — Port $port\n'
      '📍 NODE_ENV  : ${env['NODE_ENV'] ?? 'development'}\n'
      '🔗 Supabase  : ${supabaseUrl.isNotEmpty ? '✅' : '❌ MISSING'}\n'
      '📡 API Base  : $apiBase\n'
      '\n🛡️  Security layers active:\n'
      '   ✅ CORS (origins: ${allowedOrigins.join(', ')})\n'
      '   ✅ Security headers\n'
      '   ✅ Request logging\n'
      '   ✅ Rate limiter (login: 5/15min | API: 120/min)\n'
      '   ✅ JWT auth + profile status check\n'
      '   ✅ Role permission matrix\n'
      '   ✅ Branch isolation (server-enforced)\n'
      '   ✅ Student self-guard\n'
      '   ✅ Audit logging\n');
}

/// Security headers — Helmet-equivalent
Middleware _securityHeaders() {
  return (Handler inner) => (Request req) async {
    final res = await inner(req);
    return res.change(headers: {
      ...res.headersAll,
      'X-Content-Type-Options': ['nosniff'],
      'X-Frame-Options': ['DENY'],
      'Referrer-Policy': ['no-referrer'],
      'X-XSS-Protection': ['1; mode=block'],
    });
  };
}

/// Request logger — Morgan-equivalent
Middleware _requestLogger() {
  return (Handler inner) => (Request req) async {
    final start = DateTime.now();
    final res   = await inner(req);
    final ms    = DateTime.now().difference(start).inMilliseconds;
    final env   = dotenv.DotEnv(includePlatformEnvironment: true)..load();
    final isDev = env['NODE_ENV'] != 'production';

    if (isDev) {
      AppLogger.info('[${res.statusCode}] ${req.method} /${req.url.path} — ${ms}ms');
    } else {
      // Combined log format
      final ip = req.headers['x-forwarded-for'] ?? 'unknown';
      AppLogger.info('$ip ${req.method} /${req.url.path} ${res.statusCode} ${ms}ms');
    }
    return res;
  };
}
