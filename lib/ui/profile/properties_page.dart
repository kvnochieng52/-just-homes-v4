import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:just_apartment_live/ui/property/edit_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/ui/property/post_step2_page.dart';
import 'package:just_apartment_live/ui/property/subscription_status_card.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  _PropertiesPageState createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List _userProperties = [];
  bool _initDataFetched = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();
  bool _isDeleting = false;

  var islogdin = 0;

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

  @override
  void initState() {
    super.initState();
    _getInitData();
    _fetchWebUrl();
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-user-properties');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _userProperties = body['data']['properties'];

          print("PROPERTIES LOADED: " + _userProperties.toString());
          _initDataFetched = true;
        });
      }
    }
  }

  Widget _buildPropertyItem(Map<String, dynamic> property) {
    return Column(
      children: [
        ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailsPage(
                    propertyID: property['id'],
                  );
                }),
              );
            },
            child: Image.network(
              //Configuration.WEB_URL + property['thumbnail'].toString(),

              hasGotApiLink
                  ? _webUrlFuture + property['thumbnail'].toString()
                  : defaultImage,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailsPage(
                    propertyID: property['id'],
                  );
                }),
              );
            },
            child: Text(
              property['property_title'],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color, // Updated
              ),
            ),
          ),
          subtitle: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailsPage(
                    propertyID: property['id'],
                  );
                }),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${property['google_address']}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _hexToColor(
                            property['status_color_code']), // e.g. "#27C781"
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property['status_name'],
                        style: TextStyle(
                          color: _hexToColor(property[
                              'status_text_color_code']), // e.g. "#FFFFFF"
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: _isDeleting
              ? const CircularProgressIndicator()
              : PopupMenuButton<String>(
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    if (value == 'edit') {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPage(
                            propertyID: property['id'],
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(property);
                    }
                  },
                ),
        ),
        const Divider(),
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // add full opacity if missing
    return Color(int.parse(hex, radix: 16));
  }

  _showDeleteConfirmationDialog(Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this property?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProperty(property['id']);
              },
            ),
          ],
        );
      },
    );
  }

  _deleteProperty(id) async {
    setState(() {
      _isDeleting = true; // Start loading
    });

    var data = {
      'property_id': id,
    };

    var res = await CallApi().postData(data, 'property/delete-property');

    setState(() {
      _isDeleting = false; // End loading
    });

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property successfully deleted.'),
            backgroundColor: Colors.purple,
          ),
        );

        _getInitData();
      }
    }
  }

  Widget _noPropertiesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No Properties Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'It looks like you have not added any properties yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const PostPage();
                }),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Post Property',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Properties',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            backgroundColor: HexColor('#252742'),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0.0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                color: Colors.white,
                onPressed: () {
                  _checkifUserisLoggedIn().then((result) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return result == 1 ? PostPage() : LoginPage();
                      }),
                    );
                  });
                },
              ),
            ],
          ),
          body: _initDataFetched
              ? _userProperties.isNotEmpty
                  ? CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(
                          child: SubscriptionStatusCard(),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildPropertyItem(_userProperties[
                                  _userProperties.length - 1 - index]);
                            },
                            childCount: _userProperties.length,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const SubscriptionStatusCard(),
                        Expanded(child: _noPropertiesWidget()),
                      ],
                    )
              : Column(
                  children: [
                    const SubscriptionStatusCard(),
                    Expanded(child: _shimmerEffect()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _shimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
      highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 60,
              height: 60,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.2), // Updated from onBackground to onSurface
            ),
            title: Container(
              height: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.2), // Updated from onBackground to onSurface
            ),
            subtitle: Container(
              height: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.2), // Updated from onBackground to onSurface
            ),
          );
        },
      ),
    );
  }
}
