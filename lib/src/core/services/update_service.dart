import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _githubRepo = 'Vishal-1704/gokuls-shree';

  /// Checks for an update and shows a dialog if a new version is available.
  /// This should be called from the main screen after the app loads.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await Dio().get(
        'https://api.github.com/repos/$_githubRepo/releases/latest',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String?;
        final downloadUrl = data['html_url'] as String?;

        if (latestTag != null && downloadUrl != null) {
          final latestVersion = latestTag.replaceAll('v', '');
          
          if (_isUpdateAvailable(currentVersion, latestVersion)) {
            if (context.mounted) {
              _showUpdateDialog(context, latestVersion, downloadUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// Basic version comparison (e.g. 1.0.0 vs 1.0.1)
  static bool _isUpdateAvailable(String current, String latest) {
    // If we use date-based tags like v2024.10.15, this logic will need tweaking,
    // but for simple semver or timestamp comparison, comparing strings works well enough for basic use cases.
    return latest.compareTo(current) > 0;
  }

  static void _showUpdateDialog(BuildContext context, String newVersion, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force update if needed, change to true for optional
      builder: (context) => AlertDialog(
        title: const Text('Update Available!'),
        content: Text('A new version ($newVersion) of the app is available. Please update to get the latest features and fixes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Update Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
