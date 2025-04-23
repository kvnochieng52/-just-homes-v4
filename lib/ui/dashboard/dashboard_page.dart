import 'package:flutter/material.dart';
import 'package:flutter_meta_sdk/flutter_meta_sdk.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/filter_search_widget.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

class DashBoardPage extends StatefulWidget {
  const DashBoardPage({super.key});

  @override
  _DashBoardPageState createState() => _DashBoardPageState();
}

class _DashBoardPageState extends State<DashBoardPage>
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

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: HexColor('#252742'), // Set the color of the status bar
      statusBarIconBrightness: Brightness.light, // Set icons color to light
    ));

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

    print(user);
    var data = {
      // 'user_id': user['id'].toString(),
    };

    // if (user['id'] != null) {
    //   if (mounted) {
    //     setState(() {
    //       islogdin = 1;
    //     });
    //   }
    // }

    var res = await CallApi().postData(data, 'property/dashboard-init-data');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        FlutterMetaSdk().logEvent(
          name: 'customerAtDashboard',
          parameters: {
            'dashboard': 'CustomerOnDashboard',
          },
        );
        if (mounted) {
          setState(() {
            _latestProperties = body['data']['latestProperties'];
            _filteredProperties = _latestProperties;
            _isLoading = false; // Stop showing the shimmer effect
          });
        }
      }
    }
  }

  _searchProperties(townId, subRegionId, propertyTypeID, leaseTypeID) async {
    var data = {
      'location': townId,
      'propertyType': propertyTypeID,
      'leaseType': leaseTypeID,
    };

    logger.e("DATA MAP $data");

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
      String offPlan) {
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
          // body: ListView(
          //   children: <Widget>[
          //     Column(
          //       children: [
          //         Stack(
          //           children: [
          //             SizedBox(
          //               height: 270,
          //               child: FadeInImage.assetNetwork(
          //                 placeholder: 'images/back10.jpg',
          //                 image: '${Configuration.WEB_URL}/images/back10.jpg',
          //                 fit: BoxFit.cover,
          //                 height: 200,
          //                 width: double.infinity,
          //               ),
          //             ),
          //             Align(
          //               alignment: Alignment.topCenter,
          //               child: Padding(
          //                 padding: const EdgeInsets.only(top: 0.0),
          //                 child: Image.asset(
          //                   'images/floating_logo.png',
          //                   height: 55,
          //                 ),
          //               ),
          //             ),
          //             Positioned(
          //               top: -5,
          //               left: 0,
          //               right: 0,
          //               bottom: 0,
          //               child: Align(
          //                   alignment: Alignment.topRight,
          //                   child: ElevatedButton.icon(
          //                     onPressed: () {
          //                       _checkifUserisLoggedIn().then((result) {
          //                         Navigator.push(
          //                           context,
          //                           MaterialPageRoute(
          //                             builder: (context) => result == 1
          //                                 ? const ProfilePage()
          //                                 : LoginPage(),
          //                           ),
          //                         );
          //                       });
          //                     },
          //                     icon: const Icon(
          //                       Icons.person_pin,
          //                       color: Colors.white,
          //                       size: 18,
          //                     ),
          //                     label: Text(
          //                       islogdin == 1 ? 'Dashboard' : 'Login',
          //                       style: const TextStyle(color: Colors.white),
          //                     ),
          //                     style: ElevatedButton.styleFrom(
          //                       backgroundColor: Colors.purple,
          //                       foregroundColor: Colors.white,
          //                       padding: const EdgeInsets.symmetric(
          //                           horizontal: 5, vertical: 3),
          //                       textStyle: const TextStyle(fontSize: 12),
          //                       shape: const RoundedRectangleBorder(
          //                         borderRadius: BorderRadius.zero,
          //                       ),
          //                     ),
          //                   )),
          //             ),
          //             Positioned(
          //               top: 0,
          //               left: 0,
          //               right: 0,
          //               bottom: 0,
          //               child: SizedBox(
          //                 width: MediaQuery.of(context).size.width,
          //                 child: Column(
          //                   mainAxisAlignment: MainAxisAlignment.center,
          //                   children: [
          //                     const Text(
          //                       'Just Homes',
          //                       style: TextStyle(
          //                         color: Colors.white,
          //                         fontSize: 30.0,
          //                       ),
          //                     ),
          //                     const SizedBox(height: 5),
          //                     const Text(
          //                       'Search See Love',
          //                       style: TextStyle(
          //                         color: Colors.white,
          //                         fontSize: 15.0,
          //                       ),
          //                     ),
          //                     Padding(
          //                       padding: const EdgeInsets.all(8.0),
          //                       child: Stack(
          //                         alignment: Alignment.center,
          //                         children: [
          //                           GestureDetector(
          //                             child: Container(
          //                               padding: const EdgeInsets.all(8),
          //                               decoration: const BoxDecoration(
          //                                 color: Colors.purple,
          //                                 shape: BoxShape.circle,
          //                               ),
          //                               child: const FaIcon(
          //                                 FontAwesomeIcons.plus,
          //                                 color: Colors.white,
          //                                 size: 20,
          //                               ),
          //                             ),
          //                             onTap: () async {
          //                               int loginStatus =
          //                                   await _checkifUserisLoggedIn();

          //                               Navigator.push(
          //                                 context,
          //                                 MaterialPageRoute(
          //                                   builder: (context) =>
          //                                       loginStatus == 1
          //                                           ? const PostPage()
          //                                           : LoginPage(),
          //                                 ),
          //                               );
          //                             },
          //                           )
          //                         ],
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //             Positioned(
          //               top: 10.0, // Adjust this value to fit your layout
          //               left: 10.0, // Adjust this value to fit your layout
          //               child: Material(
          //                 color: Colors
          //                     .transparent, // Set to transparent to avoid any background color
          //                 child: IconButton(
          //                   icon: const Icon(
          //                     Icons.menu,
          //                     color: Colors.white, // Color of the menu icon
          //                   ),
          //                   onPressed: () {
          //                     _scaffoldKey.currentState!
          //                         .openDrawer(); // Opens the drawer
          //                   },
          //                 ),
          //               ),
          //             ),
          //             Positioned(
          //               top: 200,
          //               left: 0,
          //               right: 0,
          //               bottom: 10,
          //               child: Padding(
          //                 padding:
          //                     const EdgeInsets.only(top: 12.0, bottom: 5.0),
          //                 child: Container(
          //                   alignment: Alignment.center,
          //                   child: ElevatedButton(
          //                     onPressed: () {
          //                       Navigator.push(
          //                         context,
          //                         MaterialPageRoute(builder: (context) {
          //                           return const SearchPage();
          //                         }),
          //                       );
          //                     },
          //                     style: ElevatedButton.styleFrom(
          //                       backgroundColor: Colors
          //                           .transparent, // Remove background color
          //                       foregroundColor: Colors.white, // Text color
          //                       padding: EdgeInsets.zero,
          //                       minimumSize: const Size(0, 0),
          //                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //                       shape: const RoundedRectangleBorder(
          //                         borderRadius: BorderRadius
          //                             .zero, // Shape to match TextButton
          //                       ),
          //                       elevation:
          //                           0, // Optional: remove the shadow if you want a flat appearance
          //                     ),
          //                     child: const Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         Icon(
          //                           Icons.search, // Magnifying glass icon
          //                           color: Colors.white,
          //                           size: 14.0,
          //                         ),
          //                         SizedBox(
          //                             width:
          //                                 4.0), // Adjust the width to reduce the space
          //                         Text(
          //                           "Advanced Search",
          //                           style: TextStyle(
          //                             color: Colors.white,
          //                             fontSize: 14.0,
          //                           ),
          //                           textAlign: TextAlign.center,
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //             )
          //           ],
          //         ),
          //         const SizedBox(height: 10.0),
          //       ],
          //     ),
          //     // Text(_latestProperties.toString()),
          //     FilterSearchWidget(
          //       properties: _latestProperties,
          //       onLocationSelected: _filterPropertiesByLocation,
          //     ),
          //     _isLoading
          //         ? _buildShimmerLoading(context)
          //         : LatestPropertiesWidget(
          //             latestProperties: _filteredProperties,
          //           ),
          //   ],
          // ),

          body: ListView(
            children: <Widget>[
              Column(
                children: [
                  Stack(
                    children: [
                      // FutureBuilder to fetch dynamic URL
                      FutureBuilder<Map<String, String>>(
                        future: Configuration()
                            .getCountryApiLink(), // Fetch country-specific API/WEB URL
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 270,
                              child: Text(''), // Show loading indicator
                            );
                          } else if (snapshot.hasError) {
                            return SizedBox(
                              height: 270,
                              child: Text(
                                  'Error: ${snapshot.error}'), // Show error message if any
                            );
                          } else if (!snapshot.hasData) {
                            return SizedBox
                                .shrink(); // Return an empty widget if no data is found
                          }

                          // Get the WEB_URL from the snapshot data
                          final webUrl = snapshot.data?['web'] ?? 'test';

                          return SizedBox(
                            height: 270,
                            child: FadeInImage.assetNetwork(
                              placeholder: 'images/back10.jpg',
                              image:
                                  '$webUrl/images/back10.jpg', // Dynamically use the web URL
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Image.asset(
                            'images/floating_logo.png',
                            height: 55,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Align(
                            alignment: Alignment.topRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _checkifUserisLoggedIn().then((result) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => result == 1
                                          ? const ProfilePage()
                                          : LoginPage(),
                                    ),
                                  );
                                });
                              },
                              icon: const Icon(
                                Icons.person_pin,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                islogdin == 1 ? 'Dashboard' : 'Login',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 3),
                                textStyle: const TextStyle(fontSize: 12),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            )),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Just Homes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30.0,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Search See Love',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.plus,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () async {
                                        int loginStatus =
                                            await _checkifUserisLoggedIn();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                loginStatus == 1
                                                    ? const PostPage()
                                                    : LoginPage(),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10.0, // Adjust this value to fit your layout
                        left: 10.0, // Adjust this value to fit your layout
                        child: Material(
                          color: Colors
                              .transparent, // Set to transparent to avoid any background color
                          child: IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white, // Color of the menu icon
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState!
                                  .openDrawer(); // Opens the drawer
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 200,
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 12.0, bottom: 5.0),
                          child: Container(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return const SearchPage();
                                  }),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Remove background color
                                foregroundColor: Colors.white, // Text color
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius
                                      .zero, // Shape to match TextButton
                                ),
                                elevation:
                                    0, // Optional: remove the shadow if you want a flat appearance
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search, // Magnifying glass icon
                                    color: Colors.white,
                                    size: 14.0,
                                  ),
                                  SizedBox(
                                      width:
                                          4.0), // Adjust the width to reduce the space
                                  Text(
                                    "Advanced Search",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                ],
              ),
              // Text(_latestProperties.toString()),
              FilterSearchWidget(
                properties: _latestProperties,
                onLocationSelected: _filterPropertiesByLocation,
              ),
              _isLoading
                  ? _buildShimmerLoading(context)
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

  Widget _buildShimmerLoading(BuildContext context) {
    // Determine colors based on the current theme
    final baseColor = Theme.of(context).colorScheme.secondary.withOpacity(0.3);
    final highlightColor =
        Theme.of(context).colorScheme.secondary.withOpacity(0.1);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
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
