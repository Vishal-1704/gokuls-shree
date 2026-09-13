import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

/// Helper to safely resolve image providers from avatar/photo URLs, filenames, or base64.
/// Completely prevents "ArgumentError: No host specified in URI file:///..." crashes.
ImageProvider? resolveAvatarProvider(dynamic rawUrl) {
  if (rawUrl == null) return null;
  final url = rawUrl.toString().trim();
  if (url.isEmpty || url.toLowerCase() == 'null' || url.toLowerCase() == 'n/a') {
    return null;
  }

  try {
    // 1. Base64 data URL
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }

    // 2. Full HTTP/HTTPS URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }

    // 3. Relative filename stored in database (e.g. "1727776207685.jpg" or "avatars/...")
    final cleanPath = url
        .replaceFirst(RegExp(r'^/?avatars/'), '')
        .replaceFirst(RegExp(r'^/'), '');

    final supabaseUrl = EnvConfig.supabaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (supabaseUrl.isNotEmpty) {
      final fullUrl = '$supabaseUrl/storage/v1/object/public/avatars/$cleanPath';
      return NetworkImage(fullUrl);
    }

    // 4. Fallback to website base URL if Supabase URL is empty
    final websiteBase = EnvConfig.websiteBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (websiteBase.isNotEmpty) {
      return NetworkImage('$websiteBase/uploads/$cleanPath');
    }
  } catch (e) {
    debugPrint('Error resolving avatar provider for "$rawUrl": $e');
  }

  return null;
}
