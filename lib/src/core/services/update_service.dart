import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static const String _githubRepo = 'Vishal-1704/gokuls-shree';
  static const String _prefsLastSeenTagKey = 'update_last_seen_tag';

  /// Checks for an update and shows a snackbar if a new, not-yet-seen
  /// version is available. Call once (e.g. from RoleShell, shared by every
  /// role) — not per-dashboard, so every role actually gets checked.
  ///
  /// Waits before doing any network work so this never competes with the
  /// dashboard's own initial data fetches right at boot/login — this was
  /// previously fired from postFrameCallback the instant the dashboard
  /// first rendered, adding a GitHub API round-trip to the app's busiest
  /// startup moment. Runs like a background check instead: the dashboard
  /// is already fully interactive by the time this does anything.
  static Future<void> checkForUpdate(
    BuildContext context, {
    Duration delay = const Duration(seconds: 8),
  }) async {
    await Future.delayed(delay);
    if (!context.mounted) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await Dio().get(
        'https://api.github.com/repos/$_githubRepo/releases/latest',
      );

      if (response.statusCode != 200) return;

      final data = response.data;
      final latestTag = data['tag_name'] as String?;
      if (latestTag == null) return;
      final latestVersion = latestTag.replaceAll('v', '');

      // Built-name/build-number are now generated from the exact same
      // release tag as the CI workflow (see release.yml) — comparing
      // currentVersion (the running APK's own versionName) against
      // latestVersion this way is finally comparing like with like,
      // instead of a hand-maintained pubspec version against a date tag.
      if (!_isUpdateAvailable(currentVersion, latestVersion)) return;

      final prefs = await SharedPreferences.getInstance();
      final lastSeenTag = prefs.getString(_prefsLastSeenTagKey);
      // Already shown this exact release before — don't nag again every
      // single launch. Only a genuinely newer tag re-triggers the notice.
      if (lastSeenTag == latestTag) return;

      final assets = data['assets'] as List?;
      final apkAsset = assets?.cast<Map>().firstWhere(
            (a) => (a['name'] as String?)?.endsWith('.apk') ?? false,
            orElse: () => const {},
          );
      final downloadUrl = apkAsset?['browser_download_url'] as String?;

      if (context.mounted) {
        _showUpdateSnackBar(context, latestTag, latestVersion, downloadUrl);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// Basic version comparison (e.g. 2026.09.14-1530 vs 2026.09.10-0900) —
  /// this date-stamp format sorts correctly as a plain string compare.
  static bool _isUpdateAvailable(String current, String latest) {
    return latest.compareTo(current) > 0;
  }

  static Future<void> _markSeen(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastSeenTagKey, tag);
  }

  static void _showUpdateSnackBar(
    BuildContext context,
    String tag,
    String version,
    String? downloadUrl,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(
          SnackBar(
            content: Text('A new version ($version) is available.'),
            duration: const Duration(seconds: 8),
            action: downloadUrl == null
                ? null
                : SnackBarAction(
                    label: 'UPDATE',
                    onPressed: () => _downloadAndInstall(context, downloadUrl),
                  ),
          ),
        )
        .closed
        .then((_) => _markSeen(tag));
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String downloadUrl,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Downloading update…'), duration: Duration(seconds: 30)),
    );

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/gokul_shree_update.apk';
      await Dio().download(downloadUrl, filePath);

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      messenger.hideCurrentSnackBar();
      await OpenFilex.open(filePath);
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
