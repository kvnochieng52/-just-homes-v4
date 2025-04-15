import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/spalsh_screen/splash_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: HexColor('#252742'), // Set the color of the status bar
    statusBarIconBrightness:
        Brightness.light, // Set icons color to light for dark background
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: 'Deep Link Example',
    //   theme: ThemeData(primarySwatch: Colors.blue),
    //   home: DeepLinkHandler(),
    // );

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
          // home: DeepLinkHandler(),

          home: SplashScreen(),
          // home: const SplashScreen()),
          // home:  RealTimeUpdatePage()),
          // RealTimeUpdatePage
        ),
      ),
    );
  }
}
