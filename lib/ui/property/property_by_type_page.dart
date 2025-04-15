import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/filter_search_widget.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class PropertyByTypePage extends StatefulWidget {
  final String leaseType; // Accepting leaseType as a parameter
  final int selectedIndex;

  const PropertyByTypePage(
      {super.key, required this.leaseType, required this.selectedIndex});

  @override
  _PropertyByTypePageState createState() => _PropertyByTypePageState();
}

class _PropertyByTypePageState extends State<PropertyByTypePage> {
  List _latestProperties = [];
  List _filteredProperties = [];
  var islogdin = 0;
  bool _isLoading = true;
  late int _selectedFooterIndex; // Declare without initialization

  @override
  void initState() {
    super.initState();

    // Initialize the _selectedFooterIndex here
    _selectedFooterIndex = widget.selectedIndex;

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
      'leaseType': widget.leaseType,
    };

    var res = await CallApi().postData(data, 'property/search');

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
      'leaseType': widget.leaseType,
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

  void _filterPropertiesByLocation(
    String townId,
    String subRegionId,
    String propertyTypeID,
    String leaseType,
    String onAuction,
    String offPlan,
  ) {
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
      // drawer: islogdin == 1 ? drawer(context) : public_drawer(context),
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
      body: ListView(
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
                      FilterSearchWidget(
                        properties: _latestProperties,
                        onLocationSelected: _filterPropertiesByLocation,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 0.0),
                        child: IconButton(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors
                                          .black), // Icon color for dark mode
                              const SizedBox(
                                  width:
                                      4.0), // Add some space between the icon and text
                              Text(
                                "Advanced Search",
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors
                                          .black, // Text color for dark mode
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchPage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          _isLoading
              ? _buildShimmerLoading(
                  context) // Show shimmer effect while loading
              : LatestPropertiesWidget(
                  latestProperties: _filteredProperties,
                ),
        ],
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
