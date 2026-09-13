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

  // RoleShell (the single call site for this, shared by every role) can
  // have its State recreated/re-run initState() multiple times per app
  // session during ordinary GoRouter shell rebuilds — without this guard,
  // every rebuild queued another SnackBar, each one interrupting/replacing
  // whichever was already showing, which looked like a single notice stuck
  // on screen forever and made the first tap just dismiss the current
  // instance instead of ever reaching its action button. One real check
  // per process lifetime is all this needs; a fresh app launch re-arms it.
  static bool _hasCheckedThisSession = false;

  static final ValueNotifier<double?> downloadProgress = ValueNotifier<double?>(null);

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
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

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
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                Expanded(child: Text('A new version ($version) is available.')),
                if (downloadUrl != null)
                  TextButton(
                    onPressed: () => _downloadAndInstall(context, downloadUrl),
                    child: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                // Explicit close so this doesn't rely only on the 8s
                // auto-timeout to go away.
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => messenger.hideCurrentSnackBar(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
    messenger.hideCurrentSnackBar();
    downloadProgress.value = null;

    final progressController = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 10),
        content: ValueListenableBuilder<double?>(
          valueListenable: downloadProgress,
          builder: (context, progress, _) => Row(
            children: [
              const Text('Downloading update…'),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(value: progress, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(progress == null ? '' : '${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/gokul_shree_update.apk';
      await Dio().download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) downloadProgress.value = received / total;
        },
      );

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      progressController.close();
      await OpenFilex.open(filePath);
    } catch (e) {
      progressController.close();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
