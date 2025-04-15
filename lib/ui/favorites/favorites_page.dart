import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List _latestProperties = [];
  List _filteredProperties = [];
  var islogdin = 0;
  bool _isLoading = true;
  int _selectedFooterIndex = 3;

  @override
  void initState() {
    super.initState();
    _getInitData();

    _checkifUserisLoggedIn().then((result) {
      if (mounted) {
        setState(() {
          islogdin = result;
        });
      }
    });
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user['id'] != null) {
      setState(() {
        islogdin = 1;
      });
    }

    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-favorite-list');

    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (body['success']) {
        setState(() {
          _latestProperties = body['data']['properties'];
          _filteredProperties = _latestProperties;
          _isLoading = false; // Stop showing the shimmer effect
        });
      }
    }
  }

  _searchProperties(townId, subRegionId, propertyTypeID, leaseTypeID) async {
    var data = {
      'townID': townId,
      'subRegionId': subRegionId,
      'propertyType': propertyTypeID,
    };

    var res = await CallApi().postData(data, 'property/search');
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (body['success']) {
        setState(() {
          _filteredProperties = body['data']['properties'];
          _isLoading = false; // Stop showing the shimmer effect
        });
      }
    }
  }

  void _filterPropertiesByLocation(String townId, String subRegionId,
      String propertyTypeID, String leaseType) {
    if (mounted) {
      setState(() {
        _isLoading = true; // Show shimmer effect when filtering
      });
    }
    _searchProperties(townId, subRegionId, propertyTypeID, leaseType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHeader(context),
      drawer: buildDrawer(context),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedFooterIndex,
        onItemSelected: (index) {
          if (mounted) {
            setState(() {
              _selectedFooterIndex = index;
            });
          }
        },
      ),
      body: islogdin == 1 ? _buildFavoritesContent() : _buildLoginMessage(),
    );
  }

  Widget _buildFavoritesContent() {
    return ListView(
      children: <Widget>[
        Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8.0),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800] // Dark mode background color
                  : Colors.grey.shade100, // Light mode background color
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      "Favorites",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Text color for dark mode
                            : Colors.black, // Text color for light mode
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        _isLoading
            ? _buildShimmerLoading(context) // Show shimmer effect while loading
            : LatestPropertiesWidget(
                latestProperties: _filteredProperties,
              ),
      ],
    );
  }

  Widget _buildLoginMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please log in to view your favorites.",
              style: TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.purple, // Set the button color to purple
                foregroundColor: Colors.white, // Set the text color to white
              ),
              child: const Text("Login"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            height: 100,
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.white, // Background color of shimmer item
          );
        }),
      ),
    );
  }

  Future<int> _checkifUserisLoggedIn() async {
    int isLoggedIn = 0;
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user['id'] != null) {
      isLoggedIn = 1;
    } else {
      isLoggedIn = 0;
    }

    return isLoggedIn;
  }
}
