import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/app_update_checker.dart';

class AppUpdateDialog extends StatelessWidget {
  final bool forceUpdate;
  final String latestVersion;
  final String releaseNotes;
  final VoidCallback onDismiss;

  const AppUpdateDialog({
    required this.forceUpdate,
    required this.latestVersion,
    required this.releaseNotes,
    required this.onDismiss,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(Icons.system_update,
              size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          const Text('Update Available',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('A new version ($latestVersion) is available.'),
            const SizedBox(height: 12),
            const Text('Release Notes:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(releaseNotes),
            if (forceUpdate) ...[
              const SizedBox(height: 12),
              Text('This update is required to continue using the app.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        if (!forceUpdate)
          TextButton(
            onPressed: onDismiss,
            child: const Text('Later'),
          ),
        ElevatedButton.icon(
          icon: Icon(
            Platform.isAndroid ? Icons.android : Icons.apple,
            color: Colors.white, // White icon color
          ),
          label: const Text(
            'Update Now',
            style: TextStyle(color: Colors.white), // White text color
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, // Purple background
            foregroundColor: Colors.white, // White ripple effect
          ),
          onPressed: () {
            AppUpdateChecker.launchStore();
            if (!forceUpdate) {
              onDismiss();
            }
          },
        ),
      ],
    );
  }
}
