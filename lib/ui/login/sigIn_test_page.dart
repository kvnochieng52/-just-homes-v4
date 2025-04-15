import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInTestPage extends StatefulWidget {
  @override
  _SignInTestPageState createState() => _SignInTestPageState();
}

class _SignInTestPageState extends State<SignInTestPage> {
  final AppLinks _appLinks = AppLinks();
  late Stream<Uri> _uriStream;

  @override
  void initState() {
    super.initState();

    print("HEREEEEE");
    // Listen for incoming deep links
    _uriStream = _appLinks.uriLinkStream;
    _uriStream.listen(_handleDeepLink);
  }

  // Function to handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.path == '/android-callback') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        // Save token in SharedPreferences
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('auth_token', token);

        // Navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        // Token is missing, navigate to ErrorPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorPage()),
        );
      }
    }
  }

  // Function to handle Google sign-in and initiate the deep link redirection
  Future<void> _handleGoogleSignIn() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.setString('google_sign_initiated', '1');

    final Uri deepLinkUrl =
        Uri.parse('https://justhomes.co.ke/login/google-android');

    if (await canLaunchUrl(deepLinkUrl)) {
      await launchUrl(
        deepLinkUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $deepLinkUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              child: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder HomePage for navigation after successful login
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}

// Error Page for handling unsuccessful login
class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Error')),
      body: Center(
        child: Text('Failed to log in. Please try again.'),
      ),
    );
  }
}
