// lib/routes/download_routes.dart
// Downloads: list study materials and track download counts.
// Port of download.routes.js — no scraping, pure Supabase REST.
//
// Endpoints:
//   GET  /api/v1/downloads          — public list of downloadable files
//   POST /api/v1/downloads/:id/download — increment download count
//
// The `downloads` table is expected to have:
//   id, title, description, file_url, file_type, file_size,
//   download_count, created_at

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/supabase_service.dart';
import '../middleware/rate_limiter.dart';

Router buildDownloadRouter() {
  final router = Router();
  final rateLimit = apiLimiter.middleware;

  // ── GET /api/v1/downloads ──────────────────────────────────────────────────
  // Public endpoint — no auth required (study materials are public).
  // Returns all downloadable files ordered by newest first.
  router.get('/', Pipeline()
      .addMiddleware(rateLimit)
      .addHandler((Request req) async {
    try {
      final downloads = await SupabaseService.select(
        'downloads',
        columns: 'id,title,description,file_url,file_type,file_size,download_count,created_at',
        order: 'created_at.desc',
      );

      return _json(200, {
        'success': true,
        'count': downloads.length,
        'downloads': downloads.map((row) => {
              'id':            row['id'].toString(),
              'title':         row['title'],
              'description':   row['description'],
              'fileUrl':       row['file_url'],
              'fileType':      row['file_type'],
              'fileSize':      row['file_size'],
              'downloadCount': row['download_count'] ?? 0,
              'createdAt':     row['created_at'],
            }).toList(),
      });
    } catch (e) {
      print('❌ Get downloads error: $e');
      return _json(500, {'error': 'Failed to fetch downloads'});
    }
  }));

  // ── POST /api/v1/downloads/:id/download ────────────────────────────────────
  // Public — increments download_count when user taps "Download" in the app.
  // No auth required so even guests can download public materials.
  router.post('/<id>/download', Pipeline()
      .addMiddleware(rateLimit)
      .addHandler((Request req) async {
    try {
      final id = req.params['id'] as String;
      final downloadId = int.tryParse(id);
      if (downloadId == null) {
        return _json(400, {'error': 'Invalid download ID'});
      }

      // Fetch the current count first (Supabase REST doesn't support atomic increment directly)
      final rows = await SupabaseService.select(
        'downloads',
        columns: 'id,download_count',
        filters: {'id': downloadId},
      );

      if (rows.isEmpty) {
        return _json(404, {'error': 'Download not found'});
      }

      final currentCount = (rows.first['download_count'] as int?) ?? 0;

      // Increment by 1
      await SupabaseService.update(
        'downloads',
        {'download_count': currentCount + 1},
        filters: {'id': downloadId},
      );

      return _json(200, {'success': true, 'download_count': currentCount + 1});
    } catch (e) {
      print('❌ Download increment error: $e');
      return _json(500, {'error': 'Failed to record download'});
    }
  }));

  return router;
}

// ── Helper ────────────────────────────────────────────────────────────────────
Response _json(int status, Map<String, dynamic> body) => Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
