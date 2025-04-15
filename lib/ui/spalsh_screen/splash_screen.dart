import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final logger = Logger();

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isVideosCached = false;

  @override
  void initState() {
    super.initState();
    //  _initDeepLinkListener();
    _navigateToHome();
  }

  // Cache videos before navigating to the next screen
  _cacheVideos() async {
    try {
      final postData = {};
      final response = await http.post(
        Uri.parse("https://justhomes.co.ke/api/reels/get-videos"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<String> videoUrls = (data['data'] as List).map((video) {
            return 'https://justhomes.co.ke/${video['video_path']}';
          }).toList();

          // Cache videos
          for (var videoUrl in videoUrls) {
            await _cacheVideo(videoUrl);
          }

          // Once videos are cached, update the state and navigate
          setState(() {
            isVideosCached = true;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('cachedVideos', json.encode(videoUrls));
          logger.i("Caching videos, count: ${videoUrls.length}");
        }
      } else {
        logger.e("Failed to fetch videos, status code: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Error fetching videos: $e");
    }
  }

  // Function to cache a single video
  Future<void> _cacheVideo(String videoUrl) async {
    final cacheManager = DefaultCacheManager();
    await cacheManager.downloadFile(videoUrl);
  }

  _navigateToHome() async {
    // _cacheVideos();
    await Future.delayed(
      const Duration(seconds: 5), // Adjust the duration as needed
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashBoardPage()),
        );
      },
    );

    // if (isVideosCached) {

    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ensure the image covers the entire screen
          Image.asset(
            'images/splashscreen.jpg',
            fit: BoxFit.cover, // Use BoxFit.cover to fill the screen
            width: double.infinity,
            height: double.infinity,
          ),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}
