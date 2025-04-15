import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/property/subscription_page2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionStatusCard extends StatefulWidget {
  const SubscriptionStatusCard({Key? key}) : super(key: key);

  @override
  State<SubscriptionStatusCard> createState() => _SubscriptionStatusCardState();
}

class _SubscriptionStatusCardState extends State<SubscriptionStatusCard> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _subscriptionData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson == null) {
        throw Exception('User not logged in');
      }

      final user = json.decode(userJson);
      final response = await CallApi().postData(
        {'user_id': user['id']},
        'subscription/user-active-subscription',
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() {
            _subscriptionData = body['data'];
            _isLoading = false;
          });
          return;
        }
        throw Exception(body['message'] ?? 'No active subscription found');
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Subscription load error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Text("Loading Subscription..."));
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error: $_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        if (_subscriptionData == null) renewCard(),
        if (_subscriptionData != null) upgradeCard(),
      ],
    );
  }

  Widget renewCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently don\'t have an active subscription. Renew to get Approved & Listed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPage2(
                        propertyID: int.parse(0.toString()),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(150, 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'Renew Subscription',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget upgradeCard() {
    final plan = _subscriptionData?['sbscription_title'] ?? 'N/A';
    //print("SUBSCRIPTION DATA"+_subscriptionData.toString());

    final propertyCount = _subscriptionData?['properties_count'] ?? '0';
    final validUntil = _subscriptionData?['end_date'] ?? 'N/A';
    final properties_post_count =
        _subscriptionData?['properties_post_count'] ?? '0';

    if (propertyCount >= properties_post_count) {
      return renewCard();
    } else {
      return Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.green, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subscription Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Plan: $plan',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Utilized: $propertyCount / $properties_post_count',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Valid Until: ${_formatDate(validUntil)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionPage2(
                          propertyID: int.parse(0.toString()),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(150, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Upgrade Subscription',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
