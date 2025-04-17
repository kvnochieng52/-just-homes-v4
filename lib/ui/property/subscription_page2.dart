import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/profile/properties_page.dart';
import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

class SubscriptionPage2 extends StatefulWidget {
  final int propertyID;

  const SubscriptionPage2({Key? key, required this.propertyID})
      : super(key: key);

  @override
  State<SubscriptionPage2> createState() => _SubscriptionPage2State();
}

class _SubscriptionPage2State extends State<SubscriptionPage2> {
  dynamic selectedPlanId;
  bool _initDataFetched = false;
  bool _showUpgradeOptions = false;
  bool _showRenewOptions = false;
  bool _formSubmitted = false;

  List<dynamic> _subscriptions = [];
  Map<String, dynamic>? _userActiveSubscription;

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {'user_id': user['id'], 'propertyID': widget.propertyID};

    var res = await CallApi().postData(data, 'subscription/get-subscriptions');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (body['success']) {
        setState(() {
          _subscriptions = body['data'];
          _userActiveSubscription = body['userActiveSubscription'];
          _initDataFetched = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  @override
  Widget build(BuildContext context) {
    final active = _userActiveSubscription;
    bool hasActiveSubscription = active != null;
    int propertiesUsed = active?['properties_count'] ?? 0;
    int propertiesLimit = active?['properties_post_count'] ?? 0;
    bool isUnlimited = propertiesLimit == -1;
    bool hasExceededPropertyCount = hasActiveSubscription &&
        !isUnlimited &&
        propertiesUsed >= propertiesLimit;
    bool shouldShowRenewButton =
        !hasActiveSubscription || hasExceededPropertyCount;
    bool shouldShowUpgradeButton =
        hasActiveSubscription && !hasExceededPropertyCount;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Subscription', style: TextStyle(color: Colors.white)),
        backgroundColor: HexColor('#252742'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DashBoardPage()));
          },
        ),
      ),
      body: _initDataFetched
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildCurrentPlanCard(),
                  const SizedBox(height: 24),
                  if (shouldShowUpgradeButton &&
                      !_showUpgradeOptions &&
                      !_showRenewOptions)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showUpgradeOptions = true;
                          _showRenewOptions = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor('#4CAF50')),
                      child: const Text("Click here & select option to Upgrade",
                          style: TextStyle(color: Colors.white)),
                    ),
                  if (shouldShowRenewButton &&
                      !_showRenewOptions &&
                      !_showUpgradeOptions)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRenewOptions = true;
                          _showUpgradeOptions = false;
                        });
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                          "Click Here & Select your plan to Renew",
                          style: TextStyle(color: Colors.white)),
                    ),
                  if (_showUpgradeOptions || _showRenewOptions)
                    Expanded(
                      child: ListView(
                        children: _subscriptions
                            .where((sub) {
                              if (_showRenewOptions || _showUpgradeOptions) {
                                return sub['id'] !=
                                    _userActiveSubscription?['subscription_id'];
                              }
                              return false;
                            })
                            .map((sub) => buildPlanTile(
                                  id: sub['id'],
                                  title: sub['sbscription_title'],
                                  price: "KSH ${sub['amount']}",
                                  description: sub['description'],
                                ))
                            .toList(),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          _formSubmitted
                              ? null
                              : _submitData(); // Call your function here
                        },
                        child: _formSubmitted
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Continue",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  _submitData() async {
    //print("SELECTED ID: " + selectedPlanId.toString());

    final selectedPlanIdcon = selectedPlanId.toString();

    if (selectedPlanId != null && selectedPlanId > 0) {
      print("PASSING BY: HERE 1");
      setState(() {
        _formSubmitted = true;
      });
      final uniqueTransRef = PayWithPayStack().generateUuidV4();
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');
      var data = {
        'user_id': user['id'],
        'propertyID': widget.propertyID,
        'uniqueTransRef': uniqueTransRef,
        'subscription_id': selectedPlanIdcon,
      };

      var res = await CallApi().postData(data, 'subscription/process-payment');
      var body = json.decode(res.body);
      // print("BODY DATA" + body.toString());

      if (res.statusCode == 200) {
        if (selectedPlanIdcon == '1') {
          if (widget.propertyID != 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsPage(
                  propertyID: widget.propertyID.toString(),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            );
          }
        } else {
          if (body['success']) {
            //  print("DATA RES 2 " + res.statusCode.toString());
            PayWithPayStack().now(
              context: context,
              secretKey: "sk_live_d05f976d0f08c94ef8587b3dd59ccc1274a54e90",
              customerEmail: body['data']['email'].toString(),
              reference: uniqueTransRef,
              currency: "KES",
              amount: double.parse(body['data']['amount'].toString()),
              //amount: 1.toDouble(),
              callbackUrl: "https://justhomes.co.ke/",
              transactionCompleted: (paymentData) async {
                //debugPrint("PAYMENT DATA NEW" + paymentData.toString());

                if (paymentData.status == "success") {
                  try {
                    var res = await CallApi()
                        .postData(data, 'subscription/finish-payment');

                    if (res.statusCode == 200) {
                      var body = json.decode(res.body);

                      if (context.mounted) {
                        Navigator.pop(context);

                        if (widget.propertyID != 0) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                propertyID: widget.propertyID.toString(),
                              ),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );
                        }
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => DetailsPage(
                        //       propertyID: widget.propertyID.toString(),
                        //     ),
                        //   ),
                        // );
                      }
                    } else {
                      // debugPrint("Failed to post data: ${res.statusCode}");

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Error'),
                          content: Text(
                            "Failed to make the payment",
                            style: TextStyle(color: Colors.red),
                          ),
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PropertiesPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to post data. Please try again."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Failed to post data. Please try again."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to post data. Please try again."),
                        backgroundColor: Colors.red,
                      ),
                    );
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

            setState(() {
              _formSubmitted = false;
            });
          }
        }
      }
    } else {
      print("PASSING BY: HERE 2");
      setState(() {
        _formSubmitted = true;
      });
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');
      var data = {'user_id': user['id'], 'propertyID': widget.propertyID};

      var res =
          await CallApi().postData(data, 'subscription/process-subscription');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        if (body['success']) {
          if (widget.propertyID != 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsPage(
                  propertyID: widget.propertyID.toString(),
                ),
              ),
            );
          } else {
            setState(() {
              _formSubmitted = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('No Active Subscription'),
              content: Text(
                body['message'] ?? 'An error occurred',
                style: TextStyle(color: Colors.red),
              ),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PropertiesPage()),
                    );
                  },
                ),
              ],
            ),
          );

          setState(() {
            _formSubmitted = false;
          });
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(
              'Something went wrong. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
              ),
            ],
          ),
        );
      }

      setState(() {
        _formSubmitted = false;
      });
    }
  }

  Widget buildCurrentPlanCard() {
    final active = _userActiveSubscription;
    bool hasActiveSubscription = active != null;
    int propertiesUsed = active?['properties_count'] ?? 0;
    int propertiesLimit = active?['properties_post_count'] ?? 0;
    bool isUnlimited = propertiesLimit == -1;
    bool hasExceededPropertyCount = hasActiveSubscription &&
        !isUnlimited &&
        propertiesUsed >= propertiesLimit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveSubscription && !hasExceededPropertyCount
              ? Colors.green
              : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            hasActiveSubscription
                ? (hasExceededPropertyCount
                    ? "Subscription Limit Reached"
                    : "Current Plan: ${active?['sbscription_title']}")
                : "No Active Subscription",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: hasActiveSubscription
                  ? (hasExceededPropertyCount ? Colors.red : Colors.green)
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          if (hasActiveSubscription && !hasExceededPropertyCount)
            Text(
              "Utilized: $propertiesUsed / ${isUnlimited ? "Unlimited" : propertiesLimit} Properties",
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            Text(
              "Please renew your subscription for your properties to get Approved & Listed. Click on the Renew button to",
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          const SizedBox(height: 8),
          if (hasActiveSubscription && !hasExceededPropertyCount)
            Text(
                "Valid Until: ${active?['end_date']?.split(" ")?.first ?? 'N/A'}"),
        ],
      ),
    );
  }

  Widget buildPlanTile({
    required int id,
    required String title,
    required String price,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanId = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedPlanId == id
                ? HexColor('#252742')
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: id,
              groupValue: selectedPlanId,
              activeColor: HexColor('#252742'),
              onChanged: (value) {
                setState(() {
                  selectedPlanId = value!;
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(price,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
