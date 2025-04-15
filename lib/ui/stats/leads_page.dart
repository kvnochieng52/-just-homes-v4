import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/main.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  _LeadsPageState createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  var loggedin = 0;

  var telephoneLeadsCount = 0;
  var messagesCount = 0;
  var appartmentsCount = 0;
  var housesCount = 0;
  var officeCount = 0;
  var landCount = 0;
  var townHouseCount = 0;
  var shopsCoiunt = 0;
  var villasCount = 0;

  var landsCount = 0;
  var townHousesCount = 0;
  var shopsCount = 0;
  List recentMessages = [];
  bool _initDataFetched = false;

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-stats');

    if (res.statusCode == 200) {
      setState(() {
        var body = json.decode(res.body);
        telephoneLeadsCount = body['data']['telephoneLeadsCount'];
        messagesCount = body['data']['messagesCount'];
        appartmentsCount = body['data']['appartmentsCount'];
        housesCount = body['data']['housesCount'];
        officeCount = body['data']['officeCount'];
        landsCount = body['data']['landsCount'];
        townHousesCount = body['data']['townHousesCount'];
        shopsCount = body['data']['shopsCount'];
        villasCount = body['data']['villasCount'];

        recentMessages = body['data']['recentMessages'];

        _initDataFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stats Page',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16), // White text color for the title
        ),
        backgroundColor: HexColor('#252742'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor:
          Theme.of(context).colorScheme.surface, // Dark mode background
      //  appBar: header(context),
      body: ListView(
        children: [
          leadsList(),
          propertyStatistics(),
        ],
      ),
    );
  }

  leadsList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface, // Card color
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Leads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onSurface, // Text color
                    ),
                  ),
                ),
              ),
              if (!_initDataFetched)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(), // Loading indicator
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('TITLE')),
                      DataColumn(label: Text('CONTACT')),
                      DataColumn(label: Text('EMAIL')),
                      DataColumn(label: Text('ROOMS')),
                      DataColumn(label: Text('DATE')),
                    ],
                    rows: recentMessages.map((message) {
                      return DataRow(cells: [
                        DataCell(Text(message['property_title'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface))), // Title text color
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message['name'] ?? '',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)), // Contact name color
                            Text(message['telephone'] ?? '',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)), // Contact telephone color
                          ],
                        )),
                        DataCell(Text(message['email'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface))), // Email color
                        const DataCell(
                            Text('-')), // Replace with appropriate data cell
                        DataCell(Text(message['date'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface))), // Date color
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  propertyStatistics() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface, // Card color
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Text(
                  'Property Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).colorScheme.onSurface, // Text color
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(16.0),
                children: [
                  propertyStatBox(appartmentsCount.toString(), 'Apartments',
                      FontAwesomeIcons.building),
                  propertyStatBox(
                      housesCount.toString(), 'Houses', FontAwesomeIcons.home),
                  propertyStatBox(officeCount.toString(), 'Office Spaces',
                      FontAwesomeIcons.city),
                  propertyStatBox(landCount.toString(), 'Lands',
                      FontAwesomeIcons.map), // or FontAwesomeIcons.mountain

                  propertyStatBox(townHouseCount.toString(), 'Town House',
                      FontAwesomeIcons.houseUser),
                  propertyStatBox(
                      shopsCount.toString(), 'Shops', FontAwesomeIcons.store),
                  propertyStatBox(
                      villasCount.toString(), 'Villas', FontAwesomeIcons.hotel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget propertyStatBox(String count, String type, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Card color
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Light grey border
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xfff8b250)), // Icon color
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).colorScheme.onSurface, // Count text color
            ),
          ),
          Text(
            type,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600, // Dark mode text color
            ),
          ),
        ],
      ),
    );
  }
}
