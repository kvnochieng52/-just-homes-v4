import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Sign-In Demo'),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Sign in"),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () => signIn(),
              child: Text('SIGN IN'),
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  Future<void> signIn() async {
    try {
      final user = await GoogleSignInApi.login();
      if (user != null) {
        // Get the providerId
        final providerId =
            user.id; // This is the providerId (unique to the Google account)

        // Show a dialog with the user details
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('User Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Name: ${user.displayName ?? "N/A"}'),
                  Text('Email: ${user.email}'),
                  Text('Provider ID: $providerId'), // Display providerId here
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        print('User signed in: ${user.displayName}');
        print('Email: ${user.email}');
        print('Provider ID: $providerId');

        // Send user details and providerId to the server (optional)
        // final response =
        //     await sendDetailsToServer(user.displayName, user.email, providerId);
        // print('Server response: ${response.body}');
      } else {
        print('Sign in aborted by user');
      }
    } catch (error) {
      print('Sign in failed: $error');

      // Show a dialog with the error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign-In Error'),
            content: Text('Failed to sign in: $error'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<http.Response> sendDetailsToServer(
      String? name, String email, String? providerId) {
    const String url =
        'https://yourserver.com/api/authenticate'; // Replace with your server URL
    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: <String, String>{
        'name': name ?? '',
        'email': email,
        'providerId': providerId ?? '',
      },
    );
  }
}

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'email', // Ensure 'email' scope is included
      'profile', // Ensure 'profile' scope is included
      'openid', // Ensure 'openid' scope is included to retrieve ID token
    ],
  );

  static Future<GoogleSignInAccount?> login() => _googleSignIn.signIn();
}
