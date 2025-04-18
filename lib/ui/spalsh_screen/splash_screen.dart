import 'package:flutter/material.dart';
import 'package:just_apartment_live/app_update_checker.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

final logger = Logger();

class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitComplete;
  final bool skipSplash;

  const SplashScreen({
    super.key,
    this.onInitComplete,
    this.skipSplash = false,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.onInitComplete != null && !widget.skipSplash) {
      Future.delayed(const Duration(seconds: 3), widget.onInitComplete!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'images/splashscreen.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          if (!widget.skipSplash)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
        ],
      ),
    );
  }
}
