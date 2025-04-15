import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'dart:convert';

import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

class SubscriptionPage extends StatefulWidget {
  final int userId;
  final int propertyID;
  final Map<String, dynamic> data;

  const SubscriptionPage(
      {Key? key,
      required this.userId,
      required this.propertyID,
      required this.data})
      : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? selectedPlan;
  bool isSubscribed = false;
  String currentPlan = '';
  int utilized = 0;
  int maxProperties = 0;
  String validUntil = '';
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> subscriptionOptions = [];
  String? userEmail;

  // API endpoints
  // static const String subscriptionsUrl =
  //     'https://justhomes.co.ke/api/subscription/get-subscriptions';
  // static const String userSubscriptionUrl =
  //     'https://justhomes.co.ke/api/subscription/user-active-subscription';

  String subscriptionsUrl = '';
  String userSubscriptionUrl = '';

  bool hasGotApiLink = false;

  var _webUrlFuture = '';

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      final webUrl = apiLink['web'].toString();

      subscriptionsUrl = '${webUrl}api/subscription/get-subscriptions';
      userSubscriptionUrl =
          '${webUrl}api/subscription/user-active-subscription';

      hasGotApiLink = true;
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWebUrl();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _getSubscriptionOptions();
      await _getUserActiveSubscription();
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        errorMessage = 'Failed to load subscription data';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getSubscriptionOptions() async {
    print('Fetching subscription options...');
    try {
      final url = Uri.parse('$subscriptionsUrl?user_id=${widget.userId}');
      final response = await http.post(url);

      print('Subscription options response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            subscriptionOptions = List<Map<String, dynamic>>.from(data['data']);
            userEmail = data['userDetails']['email'];
          });
        } else {
          print('API success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to load subscriptions');
        }
      } else {
        print('Server responded with status: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _getSubscriptionOptions: $e');
      throw e; // Re-throw to be caught in _fetchData
    }
  }

  Future<void> _getUserActiveSubscription() async {
    print('Fetching user active subscription...');
    try {
      final url = Uri.parse('$userSubscriptionUrl?user_id=${widget.userId}');
      final response = await http.post(url);

      print('User subscription response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            isSubscribed = true;
            currentPlan = data['data']['sbscription_title'] ?? 'Unknown Plan';
            utilized = data['data']['utilized'] ?? 0;
            maxProperties = data['data']['properties_post_count'] ?? 0;
            validUntil = data['data']['valid_until'] ?? 'N/A';
            selectedPlan = currentPlan;
          });
        } else {
          print('API success=false: ${data['message']}');
          // Not throwing error here as it's okay if user has no subscription
        }
      } else {
        print('Server responded with status: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _getUserActiveSubscription: $e');
      throw e; // Re-throw to be caught in _fetchData
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: _buildBodyContent(),
      ),
    );
  }

  // Widget _buildBodyContent() {
  //   if (isLoading) {
  //     return const Center(child: CircularProgressIndicator());
  //   }

  //   if (errorMessage != null) {
  //     return Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(errorMessage!),
  //           const SizedBox(height: 16),
  //           ElevatedButton(
  //             onPressed: _fetchData,
  //             child: const Text('Retry'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       if (isSubscribed) _buildCurrentPlanCard(),
  //       const SizedBox(height: 24),
  //       if (isSubscribed) _buildUpgradeButton(),
  //       const SizedBox(height: 24),
  //       _buildSubscriptionOptions(),
  //       const Spacer(),
  //       _buildContinueButton(),
  //     ],
  //   );
  // }

  Widget _buildBodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSubscribed) _buildCurrentPlanCard(),
          const SizedBox(height: 24),
          if (isSubscribed) _buildUpgradeButton(),
          const SizedBox(height: 24),
          _buildSubscriptionOptions(),
          const SizedBox(height: 24),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                currentPlan,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green),
              ),
              const Spacer(),
              Text(
                'Valid Until: $validUntil',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Utilized: $utilized / $maxProperties Properties (per Month)',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return ElevatedButton(
      onPressed: () {
        print('Upgrade button pressed');
        // Handle upgrade action
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Upgrade Subscription',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSubscriptionOptions() {
    if (subscriptionOptions.isEmpty) {
      return const Center(child: Text('No subscription options available'));
    }

    return Column(
      children: subscriptionOptions.map((option) {
        bool isSelected = selectedPlan == option['sbscription_title'];
        return _buildSubscriptionOption(
          option['sbscription_title'],
          'KSH ${option['amount']}',
          option['description'],
          isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionOption(
      String title, String price, String details, bool isSelected) {
    return GestureDetector(
      onTap: () {
        print('Selected plan: $title');
        setState(() {
          selectedPlan = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          border:
              Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(price,
                      style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.green : Colors.black87)),
                  Text(details,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(double amount) async {
    final uniqueTransRef = PayWithPayStack().generateUuidV4();

    PayWithPayStack().now(
      context: context,
      secretKey: "sk_live_d05f976d0f08c94ef8587b3dd59ccc1274a54e90",
      customerEmail: userEmail.toString(),
      reference: uniqueTransRef,
      currency: "KES",
      amount: amount,
      callbackUrl: hasGotApiLink ? _webUrlFuture : "https://justhomes.co.ke/",
      transactionCompleted: (paymentData) async {
        debugPrint(paymentData.toString());

        if (paymentData.status == "success") {
          try {
            var res = await CallApi().postData(widget.data, 'property/post');

            if (res.statusCode == 200) {
              var body = json.decode(res.body);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsPage(
                      propertyID: widget.propertyID.toString(),
                    ),
                  ),
                );
              }
            } else {
              debugPrint("Failed to post data: ${res.statusCode}");
            }
          } catch (e) {
            debugPrint("Error during postData: $e");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to post data. Please try again."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      transactionNotCompleted: (reason) {
        debugPrint("==> Transaction failed reason: $reason");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reason),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleFreePlan() async {
    try {
      var res = await CallApi().postData(widget.data, 'property/post');

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsPage(
                propertyID: widget.propertyID.toString(),
              ),
            ),
          );
        }
      } else {
        debugPrint("Failed to post data: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error during postData: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to post data. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: selectedPlan != null
          ? () {
              switch (selectedPlan) {
                case "Free":
                  _handleFreePlan();
                  break;
                case "Basic":
                  _handlePayment(1.toDouble());
                  break;
                case "Standard":
                  _handlePayment(2.toDouble());
                  break;
                case "Enterprise":
                  _handlePayment(3.toDouble());
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invalid Product"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  break;
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Continue',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
