import 'dart:io';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/app_update_checker.dart';
import 'package:just_apartment_live/app_update_dialog.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/spalsh_screen/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: HexColor('#252742'),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(),
      dark: ThemeData.dark(),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: HexColor('#252742'),
          statusBarIconBrightness: Brightness.light,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Just Homes',
          theme: theme,
          darkTheme: darkTheme,
          home: SplashWrapper(),
        ),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showUpdateDialog = false;
  bool _shouldNavigate = true;
  bool _forceUpdate = false;
  String _latestVersion = '';
  String _releaseNotes = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final response =
          await http.get(Uri.parse(AppUpdateChecker.versionCheckUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        //print("APPPP VERSION : " + currentVersion.toString());
        final latestVersion =
            Platform.isAndroid ? data['android_version'] : data['ios_version'];

        if (AppUpdateChecker.isNewerVersion(latestVersion, currentVersion)) {
          setState(() {
            _forceUpdate = data['force_update'] ?? false;
            _latestVersion = latestVersion;
            _releaseNotes =
                data['release_notes'] ?? 'Bug fixes and improvements';
            _showUpdateDialog = true;
            _shouldNavigate = false;
          });
        } else {
          _navigateToHome();
        }
      } else {
        _navigateToHome();
      }
    } catch (e) {
      print('Error checking update: $e');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_shouldNavigate && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashBoardPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SplashScreen(
          onInitComplete: _shouldNavigate ? _navigateToHome : null,
          skipSplash: _showUpdateDialog,
        ),
        if (_showUpdateDialog)
          WillPopScope(
            onWillPop: () async => !_forceUpdate,
            child: Scaffold(
              backgroundColor: Colors.black.withOpacity(0.5),
              body: Center(
                child: AppUpdateDialog(
                  forceUpdate: _forceUpdate,
                  latestVersion: _latestVersion,
                  releaseNotes: _releaseNotes,
                  onDismiss: () {
                    setState(() {
                      _shouldNavigate = true;
                      _navigateToHome();
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
