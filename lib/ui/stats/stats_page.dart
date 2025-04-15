import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/main.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashBoardPage(),
              ),
            );
          },
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      // appBar: header(context),
      body: ListView(
        children: [
          leadsChart(),
          propertyStatistics(),
        ],
      ),
    );
  }

  leadsChart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 20),
                child: Text(
                  'Lead Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(
                height: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_initDataFetched)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 60,
                            sections: showingSections(),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            const Color.fromARGB(255, 115, 4, 125),
                            'Telephone Leads',
                          ),
                          _buildLegendItem(
                            const Color(0xfff8b250),
                            'Email Leads',
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
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  propertyStatistics() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Text(
                  'Property Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Wrap GridView with SingleChildScrollView
              SingleChildScrollView(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    propertyStatBox(appartmentsCount.toString(), 'Apartments',
                        FontAwesomeIcons.building),
                    propertyStatBox(housesCount.toString(), 'Houses',
                        FontAwesomeIcons.home),
                    propertyStatBox(officeCount.toString(), 'Office Spaces',
                        FontAwesomeIcons.city),
                    propertyStatBox(landsCount.toString(), 'Lands',
                        FontAwesomeIcons.map), // or FontAwesomeIcons.mountain

                    propertyStatBox(townHouseCount.toString(), 'Town House',
                        FontAwesomeIcons.houseUser),
                    propertyStatBox(
                        shopsCount.toString(), 'Shops', FontAwesomeIcons.store),
                    propertyStatBox(villasCount.toString(), 'Villas',
                        FontAwesomeIcons.hotel),
                  ],
                ),
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
        color: Colors.grey.shade200, // Light grey background
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
          Icon(icon, size: 40, color: Colors.purple), // Icon color
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface, // Text color
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

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (i) {
      const double fontSize = 16;
      const double radius = 50;

      final totalLeads = telephoneLeadsCount + messagesCount;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color.fromARGB(255, 115, 4, 125),
            value: totalLeads == 0 ? 1 : telephoneLeadsCount.toDouble(),
            radius: radius,
            title: '$telephoneLeadsCount',
            titleStyle: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xffffffff),
            ),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xfff8b250),
            value: messagesCount.toDouble(),
            radius: radius,
            title: '$messagesCount',
            titleStyle: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xffffffff),
            ),
          );
        default:
          throw Error();
      }
    });
  }
}
