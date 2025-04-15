import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/dashboard/widgets/latest_properties_widget.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AgentProfilePage extends StatefulWidget {
  final Map<String, dynamic> agent;

  const AgentProfilePage({super.key, required this.agent});

  @override
  _AgentProfilePageState createState() => _AgentProfilePageState();
}

class _AgentProfilePageState extends State<AgentProfilePage> {
  List<dynamic> properties = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgentProperties();
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

  void _shareAgentDetails() {
    final webLink = hasGotApiLink ? _webUrlFuture : '';
    final message = 'Check out this agent:\n'
        'Name: ${widget.agent['name']}\n'
        'Properties Posted: ${widget.agent['properties_count']}\n'
        'Telephone: ${widget.agent['telephone']}\n'
        'Email: ${widget.agent['email']}\n'
        'Profile Link: ${webLink}${widget.agent['id']}';
    Share.share(message);
  }

  Future<void> _fetchAgentProperties() async {
    try {
      // const uri = '${Configuration.API_URL}agent/agent-properties';
      // final response = await http.post(
      //   Uri.parse(uri),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'agentID': widget.agent['id']}), // Pass agent ID
      // );

      final links = await Configuration().getCountryApiLink();
      final apiUrl = links['api']!;
      final uri = '${apiUrl}agent/agent-properties';

      final response = await http.post(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'agentID': widget.agent['id']}), // Pass agent ID
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        setState(() {
          properties = responseBody['data']; // Store fetched properties
          isLoading = false;
        });
      } else {
        print("Failed to fetch properties: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching properties: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String telephone) async {
    // Check if the number is 13 digits
    if (telephone.length == 13) {
      // If so, use the number as is
      final whatsappUrl = Uri.parse("whatsapp://send?phone=$telephone");
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        print("Could not launch WhatsApp");
      }
    } else {
      // For numbers less than 13 digits, remove the first zero and prepend 254
      String modifiedTelephone = telephone.startsWith('0')
          ? '254${telephone.substring(1)}'
          : '254$telephone';

      final whatsappUrl = Uri.parse("whatsapp://send?phone=$modifiedTelephone");
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        print("Could not launch WhatsApp");
      }
    }
  }

  Future<void> _launchCall(String telephone) async {
    final callUrl = Uri.parse("tel:$telephone");
    if (await canLaunchUrl(callUrl)) {
      await launchUrl(callUrl);
    } else {
      print("Could not launch call");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agent['name'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: HexColor('#252742'), // Purple background color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[300],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // First card displaying agent details
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent thumbnail on the left
                    // Agent thumbnail on the left
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: widget.agent['avatar'] != null &&
                              widget.agent['avatar'].isNotEmpty
                          ? NetworkImage(widget.agent['avatar'])
                          : null,
                      backgroundColor: widget.agent['avatar'] == null ||
                              widget.agent['avatar'].isEmpty
                          ? Colors.grey
                          : null,
                      child: widget.agent['avatar'] == null ||
                              widget.agent['avatar'].isEmpty
                          ? Text(
                              widget.agent['name'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 30),
                            )
                          : null, // Don't show initial if avatar exists
                    ),

                    const SizedBox(width: 16.0),
                    // Agent details on the right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.agent['name'],
                                style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w400),
                              ),
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.share,
                                  color: Colors.purple,
                                ),
                                onPressed: _shareAgentDetails,
                              ),
                            ],
                          ),
                          Text(
                              "Properties Posted: ${widget.agent['properties_count']}"),
                          if (widget.agent['profile'] != null)
                            Text("Profile: ${widget.agent['profile']}"),
                          const SizedBox(height: 16.0),
                          // WhatsApp and Call buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.phone,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                label: const Text(
                                  "Call",
                                  style: TextStyle(color: Colors.purple),
                                ),
                                onPressed: () =>
                                    _launchCall(widget.agent['telephone']),
                              ),
                              const SizedBox(width: 8.0),
                              OutlinedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                label: const Text(
                                  "WhatsApp",
                                  style: TextStyle(color: Colors.purple),
                                ),
                                onPressed: () =>
                                    _launchWhatsApp(widget.agent['telephone']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Second card displaying properties posted by agents
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator()) // Show loading indicator
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, left: 8.0),
                            child: Text(
                              "Properties Posted:",
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.w300),
                            ),
                          ),
                          // Display the fetched properties
                          LatestPropertiesWidget(
                            latestProperties: properties,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
