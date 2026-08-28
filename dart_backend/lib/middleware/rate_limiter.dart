// lib/middleware/rate_limiter.dart
// In-memory rate limiter — port of rate.limiter.js
// No external Redis needed for single-process Render.com free tier.

import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../models/user_session.dart';

class _Entry {
  int count;
  DateTime resetAt;
  _Entry({required this.count, required this.resetAt});
}

class RateLimiter {
  final Duration window;
  final int max;
  final String message;
  final String Function(Request req)? keyFn;

  final Map<String, _Entry> _store = {};
  RateLimiter({
    required this.window,
    required this.max,
    required this.message,
    this.keyFn,
  }) {
    // Clean up expired entries every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      _store.removeWhere((_, v) => now.isAfter(v.resetAt));
    });
  }

  Middleware get middleware {
    return (Handler inner) {
      return (Request request) async {
        final session = request.context['session'] as UserSession?;
        final key = keyFn != null
            ? keyFn!(request)
            : (session?.profileId ?? _getIp(request));

        final now = DateTime.now();
        _Entry? entry = _store[key];
        if (entry == null || now.isAfter(entry.resetAt)) {
          entry = _Entry(count: 0, resetAt: now.add(window));
          _store[key] = entry;
        }

        entry.count++;

        final remaining = (max - entry.count).clamp(0, max);
        final resetEpoch = entry.resetAt.millisecondsSinceEpoch ~/ 1000;

        final headers = {
          'X-RateLimit-Limit': max.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': resetEpoch.toString(),
        };

        if (entry.count > max) {
          print('🚫 RATE LIMIT HIT | Key: $key | Count: ${entry.count}');
          final retryAfter = entry.resetAt.difference(now).inSeconds;
          return Response(429,
              body: jsonEncode({'error': message, 'retry_after_seconds': retryAfter}),
              headers: {...headers, 'Content-Type': 'application/json'});
        }

        // Add headers to the response from inner handler
        final response = await inner(request);
        return response.change(headers: {...response.headersAll, ...headers.map((k, v) => MapEntry(k, [v]))});
      };
    };
  }

  String _getIp(Request req) =>
      req.headers['x-forwarded-for']?.split(',').first.trim() ??
      req.headers['x-real-ip'] ??
      'unknown';
}

// ── Pre-configured limiters (mirrors rate.limiter.js) ────────────────────────

/// Login: 5 attempts per 15 minutes per IP
final loginLimiter = RateLimiter(
  window: const Duration(minutes: 15),
  max: 5,
  message: 'Too many login attempts. Please try again in 15 minutes.',
);

/// General API: 120 req/min per authenticated user
final apiLimiter = RateLimiter(
  window: const Duration(minutes: 1),
  max: 120,
  message: 'API rate limit exceeded. Please slow down.',
  keyFn: (req) {
    final session = req.context['session'] as UserSession?;
    return session?.profileId ?? 'anon';
  },
);

/// Sensitive ops: 20/min (approve, generate cert)
final sensitiveLimiter = RateLimiter(
  window: const Duration(minutes: 1),
  max: 20,
  message: 'Too many sensitive operations. Please slow down.',
  keyFn: (req) {
    final session = req.context['session'] as UserSession?;
    return session?.profileId ?? 'anon';
  },
);
