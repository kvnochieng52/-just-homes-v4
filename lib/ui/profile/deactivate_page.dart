import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DeactivateAccountPage extends StatefulWidget {
  @override
  _DeactivateAccountPageState createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  // Function to show confirmation dialog
  Future<void> _showConfirmationDialog(
      BuildContext context, String action) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text(
            'This action cannot be undone. Are you sure you want to $action?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Perform the action based on the action type
                if (action == 'deactivate') {
                  _deactivateAccount();
                } else if (action == 'delete') {
                  _deleteAccount();
                }
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  // Deactivate account function
  Future<void> _deactivateAccount() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {'user_id': user['id'], 'action': 'deactivate'};

    var res = await CallApi().postData(data, 'user/delete-profile');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        // Clear user data from SharedPreferences after successful deletion
        await localStorage.remove('user');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Account successfully Deactivated.'),
            ));
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Failed to Deactivate Account. Please try again later.'),
          ));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Failed to connect to the server. Please try again later.'),
        ));
      }
    }
  }

  Future<void> _deleteAccount() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {'user_id': user['id'], 'action': 'delete'};

    var res = await CallApi().postData(data, 'user/delete-profile');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        // Clear user data from SharedPreferences after successful deletion
        await localStorage.remove('user');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Account successfully deleted.'),
            ));
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete Account. Please try again later.'),
          ));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Failed to connect to the server. Please try again later.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Dynamic background color
      appBar: buildHeader(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Deactivate Account Section
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Title for Deactivate Account
                  Text(
                    'Deactivate Account',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Deactivate your account then reactivate it back anytime.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context, 'deactivate');
                    },
                    child: Text('Deactivate Account'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.0),

            // Delete Account Section
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Title for Delete Account
                  Text(
                    'Delete Account',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Deleting your account will delete all your profile, all your properties, statistics, leads, appointments etc. Please proceed with caution.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context, 'delete');
                    },
                    child: Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
