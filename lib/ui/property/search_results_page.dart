import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/filter_search_widget.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class SearchResultsPage extends StatefulWidget {
  final searchParameters;
  const SearchResultsPage({super.key, required this.searchParameters});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  bool get wantKeepAlive => true;
  List _latestProperties = [];
  List _filteredProperties = [];
  var islogdin = 0;
  bool _isLoading = true;

  int _selectedFooterIndex = 0;

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
    var data = widget.searchParameters;

    if (user['id'] != null) {
      if (mounted) {
        setState(() {
          islogdin = 1;
        });
      }
    }

    var res = await CallApi().postData(data, 'property/search-advanced');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        if (mounted) {
          setState(() {
            // print(body['data']);
            _latestProperties = body['data']['properties'];
            _filteredProperties = _latestProperties;
            _isLoading = false; // Stop showing the shimmer effect
          });
        }
      }
    }
  }

  _searchProperties(townId, subRegionId, propertyTypeID, leaseTypeID) async {
    var data = {
      'townID': townId,
      'subRegionId': subRegionId,
      'propertyType': propertyTypeID,
      'leaseType': leaseTypeID,
    };

    var res = await CallApi().postData(data, 'property/search');
    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (body['success']) {
        if (mounted) {
          setState(() {
            _filteredProperties = body['data']['properties'];
            _isLoading = false; // Stop showing the shimmer effect
          });
        }
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
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          //drawer: islogdin == 1 ? drawer(context) : public_drawer(context),
          appBar: buildHeader(context),
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
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: FilterSearchWidget(
                  properties: _latestProperties,
                  onLocationSelected: _filterPropertiesByLocation,
                ),
              ),
              _isLoading
                  ? _buildShimmerLoading()
                  : LatestPropertiesWidget(
                      latestProperties: _filteredProperties,
                    ),
            ],
          ),
        ),
        // Manually added navigation icon
      ],
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

  _checkifUserisLoggedIn() async {
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
