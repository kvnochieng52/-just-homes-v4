import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/agents/agent_profile.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key});

  @override
  _AgentsPageState createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  List<dynamic> agents = [];
  List<dynamic> filteredAgents = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAgents();
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

  Future<void> _fetchAgents() async {
    try {
      // const uri = '${Configuration.API_URL}agent/list';

      // final response = await http.post(
      //   Uri.parse(uri),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({}),
      // );

      final links = await Configuration().getCountryApiLink();
      final apiUrl = links['api']!;
      final uri = '${apiUrl}agent/list';

      final response = await http.post(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}), // Empty body as in the original
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        setState(() {
          agents = responseBody['data'];

          filteredAgents =
              List.from(agents); // Initialize filtered list with all agents
          isLoading = false;
        });
      } else {
        print("Failed to fetch agents: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching agents: $e");
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

  Color _generateRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  void _filterAgents(String query) {
    setState(() {
      searchQuery = query;
      filteredAgents = agents.where((agent) {
        final agentName = agent['name'].toLowerCase();
        return agentName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: buildHeader(context),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[300],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Wrap entire body with SingleChildScrollView
              child: Column(
                children: [
                  // Card at the top displaying total agents and search field
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Search TextField with reduced height and full width
                          SizedBox(
                            height: 40, // Reduced height
                            width:
                                MediaQuery.of(context).size.width, // Full width
                            child: TextField(
                              onChanged: _filterAgents,
                              decoration: const InputDecoration(
                                labelText: 'Search by name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // List of agents
                  ListView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable internal scrolling
                    shrinkWrap: true, // Use only the necessary height
                    itemCount: filteredAgents.length,
                    itemBuilder: (context, index) {
                      final agent = filteredAgents[index];
                      final String? avatarUrl = agent['avatar'];
                      final bool hasValidAvatar =
                          avatarUrl != null && avatarUrl.isNotEmpty;
                      final String agentInitial =
                          agent['name']?.isNotEmpty == true
                              ? agent['name'][0]
                              : '';

                      return GestureDetector(
                        onTap: () {
                          // Navigate to AgentDetailsPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AgentProfilePage(agent: agent),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // CircleAvatar(
                                //   radius: 40,
                                //   backgroundImage:
                                //       _getAvatarImageProvider(avatarUrl),
                                //   backgroundColor: !hasValidAvatar
                                //       ? _generateRandomColor()
                                //       : null,
                                //   child: !hasValidAvatar
                                //       ? Text(
                                //           agentInitial.toUpperCase(),
                                //           style: const TextStyle(
                                //               color: Colors.white,
                                //               fontSize: 30),
                                //         )
                                //       : null,
                                // ),

                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: !hasValidAvatar
                                      ? _generateRandomColor()
                                      : null,
                                  child: !hasValidAvatar
                                      ? Text(
                                          agentInitial.toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 30),
                                        )
                                      : FutureBuilder<ImageProvider<Object>?>(
                                          future: _getAvatarImageProvider(
                                              avatarUrl),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return CircularProgressIndicator(); // Show a loading indicator while the image is being fetched
                                            } else if (snapshot.hasError) {
                                              return Icon(Icons.error,
                                                  color: Colors
                                                      .white); // Show error icon if something goes wrong
                                            } else if (snapshot.hasData) {
                                              return CircleAvatar(
                                                radius: 40,
                                                backgroundImage: snapshot.data,
                                              );
                                            } else {
                                              return Icon(Icons.account_circle,
                                                  color: Colors
                                                      .white); // Fallback for no data
                                            }
                                          },
                                        ),
                                ),

                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            agent['name'],
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const FaIcon(
                                                FontAwesomeIcons.share,
                                                size: 20,
                                                color: Colors.purple),
                                            onPressed: () {
                                              // Construct the message for sharing
                                              final webLink = hasGotApiLink
                                                  ? _webUrlFuture
                                                  : '';
                                              final message =
                                                  'Check out this agent:\n'
                                                  'Name: ${agent['name']}\n'
                                                  'Properties Posted: ${agent['properties_count']}\n'
                                                  'Telephone: ${agent['telephone']}\n'
                                                  'Email: ${agent['email']}\n'
                                                  'Profile Link:${webLink}${agent['id']}';
                                              Share.share(message);
                                            },
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "${agent['properties_count']} Properties",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (agent['profile'] != null)
                                        Text(agent['profile']),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            icon: const FaIcon(
                                                FontAwesomeIcons.phone,
                                                size: 16,
                                                color: Colors.purple),
                                            label: const Text(
                                              "Call",
                                              style: TextStyle(
                                                  color: Colors.purple),
                                            ),
                                            onPressed: () =>
                                                _launchCall(agent['telephone']),
                                          ),
                                          const SizedBox(width: 8.0),
                                          TextButton.icon(
                                            icon: const FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                size: 16,
                                                color: Colors.purple),
                                            label: const Text(
                                              "WhatsApp",
                                              style: TextStyle(
                                                  color: Colors.purple),
                                            ),
                                            onPressed: () {
                                              // Construct the message for WhatsApp
                                              final webLink = hasGotApiLink
                                                  ? _webUrlFuture
                                                  : '';
                                              final message =
                                                  'Check out this agent:\n'
                                                  'Name: ${agent['name']}\n'
                                                  'Properties Posted: ${agent['properties_count']}\n'
                                                  'Telephone: ${agent['telephone']}\n'
                                                  'Email: ${agent['email']}\n'
                                                  'Profile Link:${webLink}${agent['id']}';

                                              // ignore: unused_local_variable
                                              final whatsappUrl = Uri.parse(
                                                  "whatsapp://send?text=$message");
                                              _launchWhatsApp(
                                                  agent['telephone']);
                                            },
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
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // ImageProvider<Object>? _getAvatarImageProvider(String? avatarUrl) {
  //   if (avatarUrl != null && avatarUrl.isNotEmpty) {
  //     return NetworkImage(avatarUrl.startsWith("http")
  //         ? avatarUrl
  //         : Configuration.WEB_URL + avatarUrl);
  //   }
  //   return null;
  // }

  Future<ImageProvider<Object>?> _getAvatarImageProvider(
      String? avatarUrl) async {
    final links = await Configuration()
        .getCountryApiLink(); // Fetch country-specific links
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Use the country-specific WEB_URL instead of API_URL
      return NetworkImage(
          avatarUrl.startsWith("http") ? avatarUrl : links['web']! + avatarUrl);
    }
    return null;
  }
}
