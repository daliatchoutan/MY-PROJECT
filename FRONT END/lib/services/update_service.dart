import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class UpdateService {
  static const int currentBuildNumber = 3;
  static const String currentVersion = '1.0.2';

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateSnack = false}) async {
    // Only check for native mobile APK updates (Web PWA updates silently in the browser)
    if (kIsWeb) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app/version'),
        headers: ApiConfig.headers(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int serverBuild = data['buildNumber'] ?? 1;
        final String serverVersion = data['version'] ?? '1.0.0';
        final String apkUrl = data['apkDownloadUrl'] ?? 'https://my-project-production-f607.up.railway.app/download/novara-latest.apk';
        final String releaseNotes = data['releaseNotes'] ?? 'Bug fixes and performance improvements.';
        final bool forceUpdate = data['forceUpdate'] ?? false;

        if (serverBuild > currentBuildNumber && context.mounted) {
          _showUpdateDialog(context, serverVersion, releaseNotes, apkUrl, forceUpdate);
        } else if (showNoUpdateSnack && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NOVARA is up to date!'),
              backgroundColor: Color(0xFF0D7A57),
            ),
          );
        }
      }
    } catch (_) {
      // Fail silently on network errors during background check
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String notes,
    String downloadUrl,
    bool force,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/novara_logo.jpg', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Update Available (v$newVersion)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version of NOVARA is ready! Update to get the latest features and improvements without losing your account data.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(notes, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted && !force) {
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D7A57),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
