import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:searchable_dropdown/searchable_dropdown.dart';

class ContactAgentPage extends StatefulWidget {
  // ContactAgentPage({Key? key, required this.title}) : super(key: key);

  // final String title;

  final int propertyID;
  const ContactAgentPage({super.key, required this.propertyID});

  @override
  _ContactAgentPageState createState() => _ContactAgentPageState();
}

class _ContactAgentPageState extends State<ContactAgentPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _initDataFetched = false;

  var _propertyDetails;

  List _propertyImages = [];

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
          _initDataFetched = true;
        });
      }
    }
  }

  _submitMessage(context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Loading().loader(context, "Processing...Please wait");

    var data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text,
      'message': _messageController.text,
      'propertyID': widget.propertyID,
    };

    var res = await CallApi().postData(data, 'property/contact-agent');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (body['success']) {
        const snackBar = SnackBar(
          content: Text('Email Successfully Sent.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        // Navigator.pop(context);

        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(
              propertyID: widget.propertyID,
            ),
          ),
        );
      }
    } else {
      const snackBar = SnackBar(
        content: Text('Email Could not be Sent. Please try again later'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade300,
      appBar: buildHeader(context),
      // drawer: drawer(context),
      body: _bodyBuild(context),
    );
  }

  Widget _bodyBuild(context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: SizedBox(
              width: double.infinity, // Make the container take full width
              child: Card(
                color: Colors.white, // Set the background color of the card
                elevation: 4, // Adjust elevation as per your preference
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _initDataFetched
                          ? Text(
                              _propertyDetails['property_title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15, // Set font weight to bold
                              ),
                            )
                          : const Text(
                              "Loading Please wait...",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold, // Set font weight to bold
                              ),
                            ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "CONTACT THE AGENT/OWNER",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Set font weight to bold
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _initDataFetched
                              ? _propertyDetails['created_by_name']
                              : "",
                          style: const TextStyle(
                            fontSize: 14, // Set font weight to bold
                          ),
                        ),
                      ),
                      Divider(
                        // Add a Divider widget after the text
                        color: Colors.grey[
                            300], // Set the color of the divider to light grey
                        thickness: 1, // Set the thickness of the divider
                      ),
                      _initDataFetched
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone), // Telephone icon
                                  const SizedBox(
                                      width: 8), // Space between icon and text
                                  Text(
                                    _propertyDetails['created_by_telephone']
                                        .toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : const Text(""),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(vertical: 5.0),
                      //   child: Row(
                      //     children: [
                      //       Icon(Icons.email),
                      //       SizedBox(width: 8),
                      //       Text(
                      //         _initDataFetched
                      //             ? _propertyDetails['created_by_telephone']
                      //                 .toString()
                      //             : '',
                      //         style: TextStyle(fontSize: 14),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Set font weight to bold
                          ),
                        ),
                      ),
                      Form(
                          key: _formKey,
                          child: Column(children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                              child: Center(
                                child: Text(
                                  "Drop the owner a message",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: _nameController,
                                // keyboardType: TextInputType.number,
                                decoration: ThemeHelper().textInputDecoration(
                                    'Your First & Last Name',
                                    'Enter Your Name'),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter Your Full Names';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  _nameController.text = value!;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: _emailController,
                                // keyboardType: TextInputType.number,
                                decoration: ThemeHelper().textInputDecoration(
                                    'Email Address',
                                    'Enter Your Email Address'),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter Email Address';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  _emailController.text = value!;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: _telephoneController,
                                keyboardType: TextInputType.number,
                                decoration: ThemeHelper().textInputDecoration(
                                    'Telephone No',
                                    'Enter Your Telephone Number'),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter Telephone Number';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  _telephoneController.text = value!;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: _messageController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 7,
                                decoration: ThemeHelper().textInputDecoration(
                                    'Your  Message', 'Enter Your Message'),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter the message';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  _messageController.text = value!;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: SizedBox(
                                width:
                                    double.infinity, // Fills the entire width
                                child: ElevatedButton(
                                  onPressed: () => _submitMessage(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .purple, // Purple background color
                                    padding: const EdgeInsets.symmetric(
                                        vertical:
                                            16.0), // Adjust vertical padding as needed
                                    foregroundColor:
                                        Colors.white, // White text color
                                  ),
                                  child: const Text(
                                    'SUBMIT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
