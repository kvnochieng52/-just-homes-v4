import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:just_apartment_live/ui/property/property_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class LatestPropertiesWidget extends StatefulWidget {
  final List<dynamic> latestProperties;

  const LatestPropertiesWidget({super.key, required this.latestProperties});

  @override
  _LatestPropertiesWidgetState createState() => _LatestPropertiesWidgetState();
}

class _LatestPropertiesWidgetState extends State<LatestPropertiesWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List _userFavorites = []; // Changed to List<int> for better type safety
  Map<int, bool> _favoriteStatus = {};
  @override
  void initState() {
    super.initState();
    _getInitData();
    _fetchWebUrl();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latestProperties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
            top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "No properties found, please check your query and try again.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      reverse: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 5.0, bottom: 15.0),
      itemCount: widget.latestProperties.length,
      itemBuilder: (BuildContext context, int index) {
        var address = widget.latestProperties[index]['address'] ?? "";
        int propertyID = widget.latestProperties[index]['id'];
        List<String> propertyImagesList =
            (widget.latestProperties[index]['property_images'] ?? '')
                .split(", ")
                .toList();

        print("^^^^^^^^^^^^^^^^^");

        print(propertyImagesList);

        print("^^^^^^^^^^^^^^^^^");

        int currentImageIndex = 0;

        // Determine the icon color based on local favorite status
        Color faviconColor = _favoriteStatus[propertyID] == true
            ? Colors.red.shade500
            : Colors.white;

        return Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 15),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return DetailsPage(propertyID: propertyID);
                          }),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          topRight: Radius.circular(10.0),
                        ),
                        child: PropertySlider(
                          propertyImagesList: propertyImagesList,
                        ),

                        // CarouselSlider(
                        //   options: CarouselOptions(
                        //     height: 220,
                        //     aspectRatio: 16 / 9,
                        //     viewportFraction: 1.0,
                        //     initialPage: 0,
                        //     enableInfiniteScroll: true,
                        //     reverse: false,
                        //     autoPlay: false,
                        //     autoPlayInterval: const Duration(seconds: 3),
                        //     autoPlayAnimationDuration:
                        //         const Duration(milliseconds: 800),
                        //     autoPlayCurve: Curves.fastOutSlowIn,
                        //     enlargeCenterPage: false,
                        //     scrollDirection: Axis.horizontal,
                        //     onPageChanged: (index, reason) {
                        //       setState(() {
                        //         currentImageIndex = index;
                        //       });
                        //     },
                        //   ),
                        //   items: propertyImagesList.map((String imageUrl) {
                        //     return Builder(
                        //       builder: (BuildContext context) {
                        //         return ClipRRect(
                        //           borderRadius: const BorderRadius.only(
                        //             topLeft: Radius.circular(10.0),
                        //             topRight: Radius.circular(10.0),
                        //           ),
                        //           child: CachedNetworkImage(
                        //             imageUrl: Configuration.WEB_URL + imageUrl,
                        //             width: double.infinity,
                        //             fit: BoxFit.cover,
                        //           ),
                        //         );
                        //       },
                        //     );
                        //   }).toList(),
                        // ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 15,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            color: Colors.purple,
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              widget.latestProperties[index]['on_auction'] == 1
                                  ? "Auction"
                                  : (widget.latestProperties[index]
                                              ['on_offplan'] ==
                                          1
                                      ? "OffPlan"
                                      : "For " +
                                          (widget.latestProperties[index]
                                                  ['lease_type_name'] ??
                                              "Unknown")),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(context, propertyID),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HexColor('#252742'),
                          ),
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.favorite,
                            color: faviconColor,
                          ),
                        ),
                      ),
                    ),
                    // Positioned(
                    //   bottom: 8,
                    //   left: 0,
                    //   right: 0,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(vertical: 10.0),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: propertyImagesList.map((url) {
                    //         int index = propertyImagesList.indexOf(url);
                    //         return Container(
                    //           width: 8.0,
                    //           height: 8.0,
                    //           margin: const EdgeInsets.symmetric(
                    //               vertical: 10.0, horizontal: 2.0),
                    //           decoration: BoxDecoration(
                    //             shape: BoxShape.circle,
                    //             color: currentImageIndex == index
                    //                 ? Colors.white
                    //                 : Colors.grey,
                    //           ),
                    //         );
                    //       }).toList(),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return DetailsPage(propertyID: propertyID);
                      }),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 10.0, left: 5, bottom: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.latestProperties[index]['property_title']
                                .toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Ensures text doesn't overflow
                            maxLines:
                                2, // Limits the title to 2 lines, wrapping if necessary
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                      widget.latestProperties[index]['property_type_name']),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, left: 0, bottom: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Colors.purple,
                        size: 15,
                      ),
                      Expanded(
                        child: Text(
                          "${capitalize(widget.latestProperties[index]['google_address'] ?? '')}, ${widget.latestProperties[index]['town_name'] ?? ''}",

                          style: const TextStyle(
                            fontSize: 12,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Ensures text doesn't overflow
                          maxLines:
                              2, // Limits the title to 2 lines, wrapping if necessary
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 5, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.latestProperties[index]['amount'] != null
                              ? "KSH ${NumberFormat('#,##0').format(widget.latestProperties[index]['amount'])}"
                              : "-", // You can change this to any placeholder text if amount is null
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _launchDialer(widget.latestProperties[index]
                                    ['created_by_telephone']
                                .toString());
                          },
                          child: Row(
                            children: [
                              const SizedBox(width: 7),
                              const Icon(
                                Icons.phone,
                                size: 12,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.latestProperties[index]
                                        ['created_by_telephone']
                                    .toString(),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(width: 7),
                            GestureDetector(
                              onTap: () {
                                launchWhatsAppLink(
                                    widget.latestProperties[index]
                                            ['created_by_telephone']
                                        .toString(),
                                    widget.latestProperties[index]
                                            ['property_title']
                                        .toString(),
                                    widget.latestProperties[index]
                                            ['created_by_name']
                                        .toString());
                              },
                              child: const Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    size: 18,
                                    color: Colors.purple,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Chat",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    child: SingleChildScrollView(
                      // Added this
                      scrollDirection:
                          Axis.horizontal, // Allow horizontal scrolling
                      child: Row(
                        children: [
                          if (widget.latestProperties[index]['type_id'] != 7)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Row(
                                children: [
                                  if (widget.latestProperties[index]
                                          ['type_id'] !=
                                      7)
                                    Container(
                                      decoration: BoxDecoration(
                                        // Adjust container color based on theme
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey
                                                .shade800 // Dark mode color
                                            : Colors.grey
                                                .shade200, // Light mode color
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: FaIcon(
                                        FontAwesomeIcons.star,
                                        size: 14,
                                        // Change icon color based on the theme
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors
                                                .white70 // Light color for dark mode
                                            : Colors
                                                .grey, // Default grey for light mode
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      widget.latestProperties[index]
                                              ['condition_name'] ??
                                          "",
                                      style: TextStyle(
                                        fontSize: 14,
                                        // Adjust text color for dark mode
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.latestProperties[index]['type_id'] != 7)
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    // Adjust container color based on theme
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors
                                            .grey.shade800 // Dark mode color
                                        : Colors
                                            .grey.shade200, // Light mode color
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: FaIcon(
                                    FontAwesomeIcons.bed,
                                    size: 16,
                                    // Change icon color based on the theme
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors
                                            .white70 // Light color for dark mode
                                        : Colors
                                            .grey, // Default grey for light mode
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    "${widget.latestProperties[index]['bedrooms']} Bedrooms",
                                    style: TextStyle(
                                      fontSize: 14,
                                      // Adjust text color for dark mode
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          TextButton(
                              child: const Icon(
                                Icons.email,
                                color: Colors.purple,
                                size: 18.0,
                              ),
                              onPressed: () {
                                launchEmail(
                                    widget.latestProperties[index]
                                        ['property_title'],
                                    widget.latestProperties[index]['email'],
                                    widget.latestProperties[index]
                                        ['created_by_name']);
                              }),
                          TextButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.share,
                              color: Colors.purple,
                              size: 18.0,
                            ),
                            label: const Text(
                              '',
                              style: TextStyle(color: Colors.purple),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 1.0),
                            ),
                            onPressed: () =>
                                shareContent(widget.latestProperties[index]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _toggleFavorite(BuildContext context, int propertyID) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user['id'] != null) {
      // Update local state immediately
      bool isFavorite = _favoriteStatus[propertyID] ?? false;
      setState(() {
        _favoriteStatus[propertyID] = !isFavorite;
      });

      var data = {
        'user_id': user['id'],
        'propertyID': propertyID,
      };

      var res;
      if (isFavorite) {
        // Remove from favorites
        res = await CallApi().postData(data, 'property/remove-favorite');
        // print("Remove");
        // print(data);
      } else {
        // Add to favorites
        res = await CallApi().postData(data, 'property/add-favorite');
      }

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (!body['success']) {
          // If server response is not successful, revert the change
          setState(() {
            _favoriteStatus[propertyID] = isFavorite;
          });
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Login First!'),
            content: const Text('Please Login First to add Favorites.'),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Grey background color
                  foregroundColor: Colors.white, // Text color
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // Purple background color
                  foregroundColor: Colors.white, // Text color
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const LoginPage();
                    }),
                  );
                },
                child: const Text('Login'),
              )
            ],
          );
        },
      );
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

  // void launchWhatsAppLink(String phone) async {
  //   try {
  //     // Clean and format the phone number
  //     String formattedPhone = phone.replaceAll(RegExp('^0+'), '');
  //     formattedPhone = formattedPhone.replaceAll(' ', '');
  //     formattedPhone = '254$formattedPhone';

  //     // Construct the URL
  //     final url = "https://wa.me/$formattedPhone";

  //     // Check if the URL can be launched
  //     if (await canLaunch(url)) {
  //       await launch(url);
  //     } else {
  //       print('Could not launch $url');
  //     }

  //   } catch (e) {
  //     print('Error launching WhatsApp: $e');
  //   }
  // }

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

  Future<void> shareContent(propertyDetails) async {
    try {
      print("WEB URL " + _webUrlFuture);
      // Split the description into paragraphs and take the first one
      String description =
          propertyDetails['property_description'].split('\n').first;

      final link = hasGotApiLink ? _webUrlFuture : '';
      String linkUrl = link +
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

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-favorite');
    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _userFavorites = body['data']['properties'];
          _favoriteStatus = {
            for (var item in _userFavorites) item as int: true
          };
        });
      }
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _launchDialer(String phoneNumber) async {
    final url = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
