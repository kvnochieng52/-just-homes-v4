import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateChecker {
  static const String versionCheckUrl =
      'https://justhomes.co.ke/api/app-version/latest';

  static Future<Map<String, dynamic>?> getUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error checking app update: $e');
      return null;
    }
  }

  static bool isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i])
        return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void launchStore() {
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=ke.co.justhomes.app'
        : 'https://apps.apple.com/app/just-homes-kenya/id6693024490';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
