import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/main.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/filter_search_widget.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class GovernmentHousing extends StatefulWidget {
  // Accepting leaseType as a parameter
  final int selectedIndex;

  const GovernmentHousing({super.key, required this.selectedIndex});

  @override
  _GovernmentHousingState createState() => _GovernmentHousingState();
}

class _GovernmentHousingState extends State<GovernmentHousing> {
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
      'governmentHousing': 1,
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
      'auction': 1,
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
      // appBar: header(context),
      //  drawer: islogdin == 1 ? drawer(context) : public_drawer(context),

      appBar: AppBar(
        title: const Text(
          'Government Housing',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16), // White text color for the title
        ),
        backgroundColor: HexColor('#252742'), // Background color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // White back button
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
      ),
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
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      FilterSearchWidget(
                        properties: _latestProperties,
                        onLocationSelected: _filterPropertiesByLocation,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 0),
                        child: IconButton(
                          icon: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, color: Colors.black),
                              SizedBox(
                                  width:
                                      4.0), // Add some space between the icon and text
                              Text(
                                "Advanced Search",
                                style: TextStyle(
                                  color: Colors.black,
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
              ),
            ],
          ),
          _isLoading
              ? _buildShimmerLoading() // Show shimmer effect while loading
              : LatestPropertiesWidget(
                  latestProperties: _filteredProperties,
                ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            height: 100,
            color: Colors.white,
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
