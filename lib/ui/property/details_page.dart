import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/property/light_box_page.dart';
import 'package:just_apartment_live/ui/report_ad/report_ad_page.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'schedule_tour_popup.dart';

class DetailsPage extends StatefulWidget {
  var propertyID;
  DetailsPage({super.key, required this.propertyID});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final int _currentIndex = 0;
  bool _init_data_fetched = false;

  List<bool> isChecked = List.generate(20, (index) => false);

  var _propertyDetails;

  List _propertyFeatures = [];

  List _propertyImages = [];
  List _filteredProperties = [];

  final List _issueReasonName = [];

  final List<Map<String, dynamic>> _reportIssueReasonsListData = [];

  List _reportIssueReasonsList = [];

  int _selectedFooterIndex = 0;

  var formattedAmount;

  @override
  void initState() {
    super.initState();
    _getInitData();
    _fetchWebUrl();
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

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'user_id': user['id'],
      'propertyID': widget.propertyID,
    };

    debugPrint(widget.propertyID.toString());
    var res = await CallApi().postData(data, 'property/details');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _propertyDetails = body['data']['propertyDetails'];
          _propertyImages = body['data']['propertyImages'];
          _filteredProperties = body['data']['similarProperties'];

          _propertyFeatures = body['data']['propertyFaetures'];
          _init_data_fetched = true;

          final numberFormat = NumberFormat("#,###");

          _reportIssueReasonsList = body['data']['reportIssueReasonsList'];

          List<Map<String, dynamic>> reportIssueReasonsListData =
              List<Map<String, dynamic>>.from(
                  body['data']['reportIssueReasonsList']);

          // Format the amount with thousand separators and append 'KSh'

          formattedAmount =
              'KSH ${numberFormat.format(_propertyDetails['amount'])}';
        });
      }

      //print(_propertyFeatures);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashBoardPage()),
          (Route<dynamic> route) => false, // Disable going back
        );
        return false; // Prevent going back to the previous screen
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey.shade300,
        appBar: buildHeader(context),
        body: _bodyBuild(context),
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
      ),
    );
  }

  // Widget _bodyBuild(context) {
  //   return Expanded(
  //     child: SingleChildScrollView(
  //       child: Column(
  //         children: [
  //           _init_data_fetched
  //               ? _buildDetailsView(context)
  //               : _buildShimmerEffect(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _bodyBuild(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _init_data_fetched
              ? _buildDetailsView(context)
              : _buildShimmerEffect(context),
        ],
      ),
    );
  }

  Widget _buildDetailsView(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSlider(context),
        Padding(
          padding: const EdgeInsets.all(0),
          child: Card(
            elevation: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align items at the start
                    children: [
                      Expanded(
                        child: Text(
                          _propertyDetails['property_title'].toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines:
                              2, // You can adjust the number of lines as needed
                          overflow: TextOverflow
                              .visible, // Ensure the text wraps and is fully visible
                        ),
                      ),

                      const SizedBox(
                          width:
                              10), // Add some spacing between the title and the amount
                      Text(
                        formattedAmount.toString(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange // Orange color for dark mode
                              : Colors.purple, // Purple color for light mode
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.house,
                                    size: 18, color: Colors.grey),
                                const SizedBox(
                                    width: 3), // Adjust the space here
                                Text(
                                    _propertyDetails['property_type_name']
                                        .toString(),
                                    style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 25),
                        Column(
                          children: [
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.locationPin,
                                    size: 18, color: Colors.grey),
                                const SizedBox(
                                    width: 3), // Adjust the space here
                                Text(
                                  "${capitalize(_propertyDetails['google_address'].toString())}, ${_propertyDetails['town_name']}",

                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Ensures text doesn't overflow
                                  maxLines:
                                      2, // Limits the title to 2 lines, wrapping if necessary
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_propertyDetails['type_id'] != 7)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface, // Dynamic background color
                        border:
                            Border.all(color: Colors.grey.shade500, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 60, // Adjust the icon size as needed
                                    height:
                                        60, // Adjust the icon size as needed
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface, // Adjust based on theme
                                    ),
                                    child: Container(
                                      width: 100, // Adjust the width as needed
                                      height:
                                          100, // Adjust the height as needed
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan border for dark mode
                                              : Colors
                                                  .purple, // Purple border for light mode
                                        ),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.star,
                                          size:
                                              20, // Adjust the icon size as needed
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan icon for dark mode
                                              : Colors
                                                  .purple, // Purple icon for light mode
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 9.0),
                                    child: Text(
                                      'Condition: ${_propertyDetails['condition_name']}' ??
                                          "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface, // Dynamic text color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 60, // Adjust the icon size as needed
                                    height:
                                        60, // Adjust the icon size as needed
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface, // Adjust based on theme
                                    ),
                                    child: Container(
                                      width: 100, // Adjust the width as needed
                                      height:
                                          100, // Adjust the height as needed
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan border for dark mode
                                              : Colors
                                                  .purple, // Purple border for light mode
                                        ),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.bed,
                                          size:
                                              20, // Adjust the icon size as needed
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan icon for dark mode
                                              : Colors
                                                  .purple, // Purple icon for light mode
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${_propertyDetails['bedrooms']} Bedroom',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface, // Dynamic text color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _propertyDetails['parking_spaces'] != null
                                ? Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          width:
                                              60, // Adjust the icon size as needed
                                          height:
                                              60, // Adjust the icon size as needed
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface, // Adjust based on theme
                                          ),
                                          child: Container(
                                            width:
                                                100, // Adjust the width as needed
                                            height:
                                                100, // Adjust the height as needed
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan border for dark mode
                                                    : Colors
                                                        .purple, // Purple border for light mode
                                              ),
                                            ),
                                            child: Center(
                                              child: FaIcon(
                                                FontAwesomeIcons.car,
                                                size:
                                                    20, // Adjust the icon size as needed
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan icon for dark mode
                                                    : Colors
                                                        .purple, // Purple icon for light mode
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${_propertyDetails['parking_spaces']} Parking',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface, // Dynamic text color
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 60, // Adjust the icon size as needed
                                    height:
                                        60, // Adjust the icon size as needed
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface, // Adjust based on theme
                                    ),
                                    child: Container(
                                      width: 100, // Adjust the width as needed
                                      height:
                                          100, // Adjust the height as needed
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan border for dark mode
                                              : Colors
                                                  .purple, // Purple border for light mode
                                        ),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.briefcase,
                                          size:
                                              20, // Adjust the icon size as needed
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .cyan // Cyan icon for dark mode
                                              : Colors
                                                  .purple, // Purple icon for light mode
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _propertyDetails['furnish_name']
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface, // Dynamic text color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _propertyDetails['property_description'],
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            textAlign:
                                TextAlign.left, // Set text alignment to justify
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey.shade400,
                    thickness: 1,
                    height: 20,
                  ),
                  const Row(
                    children: [
                      Text(
                        "Specifications",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                  if (_propertyFeatures.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _propertyFeatures.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of columns in the grid
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio:
                              3, // Adjust aspect ratio to control item height
                        ),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 0.0),
                              leading: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.purple,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                              title: Text(
                                _propertyFeatures[index]['feature_name'],
                                style: const TextStyle(fontSize: 14.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_propertyFeatures.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      height: 1.0,
                      color: Colors.grey,
                    ),
                  if (_propertyDetails['listing_as'] == 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: Row(
                        children: [
                          // Round network image

                          CircleAvatar(
                            radius: 30, // Adjust the radius as needed
                            backgroundImage: NetworkImage(
                              _propertyDetails['created_by_avatar'] != null &&
                                      _propertyDetails['created_by_avatar']
                                          .isNotEmpty
                                  ? (_propertyDetails['created_by_avatar']
                                          .startsWith("http")
                                      ? _propertyDetails[
                                          'created_by_avatar'] // Use as-is if starts with http
                                      : hasGotApiLink
                                          ? '${_webUrlFuture}${_propertyDetails['created_by_avatar']}'
                                          : defaultImage) // Prefix if not
                                  : hasGotApiLink
                                      ? '${_webUrlFuture}images/no_user.png'
                                      : defaultImage, // Default image if empty or null
                            ),
                          ),

                          const SizedBox(
                              width:
                                  8), // Add some space between the image and text
                          Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Align all children to the left
                            children: [
                              const Text(
                                "Listed By:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _propertyDetails['created_by_name'] ?? '',
                                style: const TextStyle(fontSize: 18),
                              ), // Handle null case
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Align all children to the left
                            children: [
                              const Text(
                                "Company By:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _propertyDetails['created_by_name'] ?? '',
                                style: const TextStyle(fontSize: 18),
                              ), // Handle null case
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_propertyDetails['listing_as'] == 2 ||
                      _propertyDetails['listing_as'] == 3) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: Row(
                        children: [
                          // Round network image
                          CircleAvatar(
                            radius: 30, // Adjust the radius as needed
                            backgroundImage: NetworkImage(
                              _propertyDetails['company_logo'] != null &&
                                      _propertyDetails['company_logo']
                                          .isNotEmpty
                                  ? hasGotApiLink
                                      ? '${_webUrlFuture}${_propertyDetails['company_logo']}'
                                      : defaultImage
                                  : hasGotApiLink
                                      ? '${_webUrlFuture}images/no_user.png'
                                      : defaultImage,
                            ),
                          ),
                          const SizedBox(
                              width:
                                  8), // Add some space between the image and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Align all children to the left
                            children: [
                              const Text(
                                "Listed By:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _propertyDetails['company_name'] ??
                                    'Unknown Company',
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                "Created By: ${_propertyDetails['created_by_name']}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Row(
                          children: [
                            // ClipRRect(
                            //   borderRadius: BorderRadius.circular(100.0),
                            //   child: Image.network(
                            //     _propertyDetails['created_by_avatar'] ??
                            //         'https://placehold.co/100x100.jpeg',
                            //     width: 80,
                            //     height: 80,
                            //     fit: BoxFit.cover,
                            //   ),
                            // ),
                            Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .stretch, // Ensures buttons take full width
                                  children: [
                                    // Add some spacing between rows
                                    OutlinedButton(
                                      onPressed: () {
                                        _launchDialer(_propertyDetails[
                                                'created_by_telephone']
                                            .toString());
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors
                                            .purple, // Solid background color for phone
                                        foregroundColor:
                                            Colors.white, // White text and icon
                                        side: BorderSide
                                            .none, // No border for solid background
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const FaIcon(
                                            FontAwesomeIcons.phone,
                                            color: Colors.white,
                                            size:
                                                15, // White icon color for phone
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _propertyDetails[
                                                    'created_by_telephone']
                                                .toString(), // Replace with actual phone number
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white, // White text
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            10), // Add some spacing between rows

                                    OutlinedButton(
                                      onPressed: () {
                                        launchWhatsAppLink(
                                            _propertyDetails[
                                                    'created_by_telephone']
                                                .toString(),
                                            _propertyDetails['property_title']
                                                .toString(),
                                            _propertyDetails['created_by_name']
                                                .toString());
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors
                                            .green, // Solid background color for WhatsApp
                                        foregroundColor:
                                            Colors.white, // White text and icon
                                        side: BorderSide
                                            .none, // No border for solid background
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          FaIcon(
                                            FontAwesomeIcons.whatsapp,
                                            color: Colors
                                                .white, // White icon color for WhatsApp
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'WhatsApp',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white, // White text
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => shareContent(
                                                  _propertyDetails),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors
                                                          .cyan // Cyan border for dark mode
                                                      : Colors
                                                          .purple, // Purple border for light mode
                                                ),
                                                foregroundColor: Theme.of(
                                                                context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan icon color for dark mode
                                                    : Colors
                                                        .purple, // Purple icon color for light mode
                                              ),
                                              child: FaIcon(
                                                FontAwesomeIcons.share,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan icon color for dark mode
                                                    : Colors
                                                        .purple, // Purple icon color for light mode
                                                size:
                                                    18.0, // Adjust the size to your preference
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () => {
                                                launchEmail(
                                                  _propertyDetails[
                                                      'property_title'],
                                                  _propertyDetails['email'],
                                                  _propertyDetails[
                                                      'created_by_name'],
                                                )
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors
                                                          .cyan // Cyan border for dark mode
                                                      : Colors
                                                          .purple, // Purple border for light mode
                                                ),
                                                foregroundColor: Theme.of(
                                                                context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan icon color for dark mode
                                                    : Colors
                                                        .purple, // Purple icon color for light mode
                                              ),
                                              child: FaIcon(
                                                FontAwesomeIcons.envelope,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .cyan // Cyan icon color for dark mode
                                                    : Colors
                                                        .purple, // Purple icon color for light mode
                                                size:
                                                    18.0, // Adjust the size to your preference
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return ScheduleTourPopup(
                                                  propertyId:
                                                      _propertyDetails['id']
                                                          .toString(),
                                                );
                                              },
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors
                                                      .cyan // Cyan border for dark mode
                                                  : Colors
                                                      .purple, // Purple border for light mode
                                            ),
                                            foregroundColor: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors
                                                    .cyan // Cyan icon color for dark mode
                                                : Colors
                                                    .purple, // Purple icon color for light mode
                                          ),
                                          icon: Icon(
                                            Icons.access_time,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors
                                                    .cyan // Cyan icon color for dark mode
                                                : Colors
                                                    .purple, // Purple icon color for light mode
                                            size: 16,
                                          ),
                                          label: Text(
                                            'SCHEDULE TOUR',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors
                                                      .cyan // Cyan text color for dark mode
                                                  : Colors
                                                      .purple, // Purple text color for light mode
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .start, // Aligns children to the start (left)
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons
                              .share, // Replace with the appropriate icon if needed
                          color: Colors.blue,
                        ),
                        label: const Text(
                          "Share Agent Details",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold, // Make the text bold
                          ),
                        ),
                        onPressed: () => _shareAgentDetails(
                          _propertyDetails['created_by_name'],
                          _propertyDetails['created_by_telephone'].toString(),
                          _propertyDetails['email'].toString(),
                          _propertyDetails['created_by'],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.help, // Use the help icon for reporting
                          color: Colors.blue,
                        ),
                        label: const Text(
                          "Report Ad",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold, // Make the text bold
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ReportAdDialog(
                                propertyDetails: _propertyDetails,
                                // reportIssueReasonsList:
                                //     _reportIssueReasonsListData,
                              ); // Pass the property details
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Center(
            child: Text(
              "Similar properties",
              style: TextStyle(
                fontSize: 20,
                // color: Colors.white,
              ),
            ),
          ),
        ),
        LatestPropertiesWidget(
          latestProperties: _filteredProperties,
        ),
      ],
    );
  }

  // Widget _buildImageSlider(context) {
  //   return Column(
  //     children: _propertyImages.map((imageUrl) {
  //       return Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 2.0),
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 2.0),
  //           child: Container(
  //             width: double.infinity,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(10.0),
  //               color: Colors.grey[200], // Optional: Set a background color
  //             ),
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(0.0),
  //               child: Image.network(
  //                 Configuration.WEB_URL + imageUrl['app_image'],
  //                 fit: BoxFit.cover,
  //                 height: 250, // Set the height of the image
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  void _openLightbox(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LightboxPage(
          initialIndex: initialIndex,
          images: _propertyImages
              .map((img) => hasGotApiLink
                      ? _webUrlFuture + img['app_image']
                      : defaultImage

                  // Configuration.WEB_URL + img['app_image']
                  )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildImageSlider(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: _propertyImages.asMap().entries.map((entry) {
        int index = entry.key;
        var imageUrl = entry.value;

        return GestureDetector(
          onTap: () => _openLightbox(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: isDarkMode
                      ? Colors.grey[850]
                      : Colors
                          .grey[200], // Set background color based on the theme
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      10.0), // Adjust the radius to match the container
                  child: Image.network(
                    //  Configuration.WEB_URL + imageUrl['app_image'],
                    hasGotApiLink
                        ? _webUrlFuture + imageUrl['app_image']
                        : defaultImage,
                    fit: BoxFit.cover,
                    height: 250, // Set the height of the image
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // If the image has loaded, return it.
                      }
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: isDarkMode
                            ? Colors.grey[850]
                            : Colors.grey[200], // Placeholder color for loading
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: isDarkMode
                            ? Colors.grey[850]
                            : Colors.grey[200], // Error placeholder color
                        child: Center(
                          child: Icon(Icons.error,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.black), // Error icon
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> shareContent(Map<String, dynamic> propertyDetails) async {
    try {
      // Split the description into paragraphs and take the first one
      String description =
          propertyDetails['property_description'].split('\n').first;
      String linkUrl = hasGotApiLink
          ? _webUrlFuture
          : '' +
              propertyDetails['property_type_slug'] +
              '/' +
              propertyDetails['slug'];

      await Share.share(
        '$description\n\n$linkUrl',
        subject: propertyDetails['property_title'],
      );
    } catch (e) {
      print('Error sharing content: $e');
    }
  }

  void _launchDialer(String phoneNumber) async {
    final url = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildShimmerEffect(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey.shade100,
      child: Column(
        children: [
          // Example shimmer blocks
          Container(
            margin: const EdgeInsets.all(16.0),
            height: 200.0,
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.white, // Background color of shimmer item
          ),
          const SizedBox(height: 16.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 20.0,
            width: double.infinity,
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.white, // Background color of shimmer item
          ),
          const SizedBox(height: 16.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 20.0,
            width: double.infinity,
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.white, // Background color of shimmer item
          ),
          const SizedBox(height: 16.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 100.0,
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.white, // Background color of shimmer item
          ),
        ],
      ),
    );
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void launchWhatsAppLink(
      String phone, String propertyTitle, String name) async {
    try {
      // Clean and format the phone number
      String formattedPhone = phone.replaceAll(RegExp('^0+'), '');
      formattedPhone = formattedPhone.replaceAll(' ', '');
      formattedPhone = '254$formattedPhone';

      // Construct the message
      String message = Uri.encodeComponent(
          "Hi $name, I am interested in the $propertyTitle");

      // Construct the URL
      final url = Uri.parse("https://wa.me/$formattedPhone?text=$message");

      // Check if the URL can be launched
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }

  void launchEmail(String propertyTitle, String email, String name) async {
    try {
      // Construct the email parameters
      final String subject =
          Uri.encodeComponent('Inquiry about $propertyTitle');
      final String body =
          Uri.encodeComponent('Hi $name,  I am interested in $propertyTitle.');

      // Construct the URL
      final url = Uri.parse("mailto:$email?subject=$subject&body=$body");

      // Check if the URL can be launched
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching email: $e');
    }
  }

  void _shareAgentDetails(name, telephone, email, agentID) {
    final link = hasGotApiLink ? _webUrlFuture : '';
    final message = 'Check out this agent:\n'
        'Name: $name\n'
        'Telephone: $telephone\n'
        'Email: $email\n'
        'Profile Link: ${link}profile/$agentID';
    Share.share(message);
  }
}
