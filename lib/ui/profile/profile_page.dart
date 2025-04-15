import 'dart:convert'; // Needed for json.decode
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/calendar/calendar_page.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/favorites/favorites_page.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/profile/deactivate_page.dart';
import 'package:just_apartment_live/ui/profile/properties_page.dart';
import 'package:just_apartment_live/ui/profile/settings_page.dart';
import 'package:just_apartment_live/ui/profile/user_profile_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:just_apartment_live/ui/property/subscription_status_card.dart';
import 'package:just_apartment_live/ui/reels/upload_reels.dart';
import 'package:just_apartment_live/ui/stats/leads_page.dart';
import 'package:just_apartment_live/ui/stats/stats_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final double _iconSize = 23.0;
  final double _iconPadding = 12.0;
  String _loggedInUserName = 'User'; // Default username

  @override
  void initState() {
    super.initState();
    _fetchWebUrl();
    _loadUserName();
  }

  var defaultImage = 'https://justhomes.co.ke/images/back6.jpg';
  bool hasGotApiLink = false;

  var _webUrlFuture = '';

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      _webUrlFuture = apiLink['web'].toString();
      hasGotApiLink = true;
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  Future<void> _loadUserName() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    setState(() {
      _loggedInUserName = user['name'] ??
          'User'; // Update with username or 'User' if not available
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16), // White text color for the title
        ),
        backgroundColor: HexColor('#252742'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashBoardPage(),
              ),
            );
          },
        ),
      ),
      // appBar: header(context),
      // drawer: drawer(context),

      body: Column(
        children: [
          // Purple container with title and username
          Container(
            color: Colors.purple,
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _loggedInUserName, // Display logged-in user's name
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubscriptionStatusCard(),
                    const SizedBox(height: 10),
                    _buildGroupCard(
                      'Properties',
                      [
                        _buildIcon(FontAwesomeIcons.building, 'Properties',
                            context, const PropertiesPage()),
                        _buildIcon(FontAwesomeIcons.plus, 'Post', context,
                            const PostPage()),
                        _buildIcon(FontAwesomeIcons.magnifyingGlass, 'Search',
                            context, const SearchPage()),
                        _buildIcon(FontAwesomeIcons.calendarDays, 'Calendar',
                            context, const CalendarWithEvents()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildGroupCard(
                      'Leads & Favorites',
                      [
                        _buildIcon(FontAwesomeIcons.chartBar, 'Statistics',
                            context, const StatsPage()),
                        _buildIcon(FontAwesomeIcons.users, 'Leads', context,
                            const LeadsPage()),
                        _buildIcon(FontAwesomeIcons.heart, 'Favorites', context,
                            const FavoritesPage()),
                        // _buildIcon(FontAwesomeIcons.video, 'Reels', context,
                        //     const UserReels()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildGroupCard(
                      'Profile',
                      [
                        _buildIcon(
                            FontAwesomeIcons.share, 'Share Profile', context),
                        _buildIcon(FontAwesomeIcons.user, 'Profile', context,
                            const UserProfilePage()),
                        _buildIcon(FontAwesomeIcons.gear, 'Settings', context,
                            const SettingsPage()),
                        _buildIcon(FontAwesomeIcons.personCircleMinus,
                            'Delete Profile', context, DeactivateAccountPage()),
                        _buildIcon(FontAwesomeIcons.rightFromBracket, 'Logout',
                            context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String title, List<Widget> icons) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Theme.of(context).cardColor, // Use card color from theme
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? Colors.grey.shade400
                    : Colors
                        .purple, // Light grey in dark mode, purple in light mode
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: icons,
            ),
          ],
        ),
      ),
    );
  }

  _shareProfile() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    final weblink = hasGotApiLink ? _webUrlFuture : '';

    final message = 'Hi, Check out my Properties at Just Homes:\n'
        'Name: ${user['name']}\n'
        'Telephone: ${user['telephone']}\n'
        'My Profile & Properties: ${weblink}agent/profile/${user['id']}\n';
    Share.share(message);
  }

  // Updated _buildIcon to accept context and page
  Widget _buildIcon(IconData iconData, String label, BuildContext context,
      [Widget? page]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (label == 'Logout') {
          _logoutUser(); // Call logout method directly
        } else if (label == 'Share Profile') {
          _shareProfile();
        } else if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(_iconPadding),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.purple.shade50 : Colors.purple.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade500, // Light grey border
                width: 1,
              ),
            ),
            child: FaIcon(
              iconData,
              size: _iconSize,
              color: isDarkMode
                  ? Colors.purple
                  : Colors.purple, // Icon color based on theme
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? Colors.white
                  : Colors.grey.shade700, // Dynamic text color
            ),
          ),
        ],
      ),
    );
  }

  void _logoutUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    // Remove the stored user data and token
    await localStorage.remove('user');
    await localStorage.remove('token');
    await localStorage.remove('google_sign_initiated');

    // Navigate to the login page and remove all other routes from the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DashBoardPage()),
      (Route<dynamic> route) => false,
    );
  }
}

// Optional: HexColor class if needed
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }
}
