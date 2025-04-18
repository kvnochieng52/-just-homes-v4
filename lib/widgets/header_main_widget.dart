import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/agents/agents_page.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/login/google_sign.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/login/sigIn_test_page.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/property/auctioned_properties_page.dart';
import 'package:just_apartment_live/ui/property/offplan_properties_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/ui/property/property_slider.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

const Color appBarColor = Color(0xFF252742); // Purple background color
const String userKey = 'user';
const String tokenKey = 'token';

Future<int> checkIfUserIsLoggedIn() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = json.decode(localStorage.getString(userKey) ?? '{}');
  return user['id'] != null ? 1 : 0;
}

void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

AppBar buildHeader(BuildContext context) {
  return AppBar(
    backgroundColor: appBarColor,
    iconTheme: const IconThemeData(color: Colors.white),
    centerTitle: false,
    elevation: 0.0,
    actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          checkIfUserIsLoggedIn().then((result) {
            navigateToPage(
                context, result == 1 ? const PostPage() : const LoginPage());
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.person_pin, color: Colors.white),
        onPressed: () {
          checkIfUserIsLoggedIn().then((result) {
            navigateToPage(
                context, result == 1 ? const ProfilePage() : const LoginPage());
          });
        },
      ),
    ],
  );
}

Drawer buildDrawer(BuildContext context, {bool isPublic = false}) {
  return Drawer(
    child: Column(
      children: <Widget>[
        const Divider(height: 30.0),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              buildDrawerItem(
                  context, Icons.home, 'Home', const DashBoardPage()),
              buildDrawerItem(
                  context, Icons.settings, 'Dashboard', const ProfilePage()),
              buildDrawerItem(context, Icons.people, 'Just Homes Agents',
                  const AgentsPage()),
              buildDrawerItem(
                  context, Icons.search, 'Search Property', const SearchPage()),
              buildDrawerItem(
                  context,
                  Icons.house_outlined,
                  'OffPlan Properties',
                  const OffPlanPropertiesPage(selectedIndex: 2)),
              buildDrawerItem(
                  context,
                  Icons.house_siding_rounded,
                  'On Auction Properties',
                  const AuctionedPropertiesPage(selectedIndex: 2)),
              buildDrawerItem(
                  context, Icons.house, 'Post New Property', const PostPage()),
              buildLogoutItem(context),
              buildThemeToggle(context),
              if (isPublic) buildLoginItem(context),
            ],
          ),
        ),
        // Add version information at the bottom
        // Alternative simpler version
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text.rich(
                  TextSpan(
                    text: 'Version ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    children: [
                      TextSpan(
                        text:
                            '${snapshot.data?.version} (${snapshot.data?.buildNumber})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  );
}

ListTile buildDrawerItem(
    BuildContext context, IconData icon, String title, Widget page) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () => navigateToPage(context, page),
  );
}

ListTile buildDrawerItemWithUrl(
    BuildContext context, IconData icon, String title, String url) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () async {
      final Uri uri = Uri.parse(url); // Convert String to Uri
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    },
  );
}

ListTile buildLogoutItem(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.logout),
    title: const Text('Logout'),
    onTap: () async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      await localStorage.remove(userKey);
      await localStorage.remove(tokenKey);
      await localStorage.remove('google_sign_initiated');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashBoardPage()),
        (Route<dynamic> route) => false,
      );
    },
  );
}

ListTile buildThemeToggle(BuildContext context) {
  return ListTile(
    title: const Text('Light/Dark Mode'),
    trailing: Switch(
      value: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light,
      onChanged: (value) {
        AdaptiveTheme.of(context).setThemeMode(
          value ? AdaptiveThemeMode.light : AdaptiveThemeMode.dark,
        );
      },
    ),
  );
}

ListTile buildLoginItem(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.login),
    title: const Text('Login'),
    onTap: () {
      navigateToPage(context, const LoginPage());
    },
  );
}
