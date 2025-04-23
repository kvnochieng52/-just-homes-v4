import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/forgot_password/forgot_password.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/register/activation_page.dart';
import 'package:just_apartment_live/ui/register/register.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_meta_sdk/flutter_meta_sdk.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  int selectedOption = 1;

  bool _obscureText = true;

  String _deepLink = "Waiting for deep link...";
  String? token;

  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

  void initState() {
    super.initState();

    _initDeepLinkListener();
  }

  Future<void> _initDeepLinkListener() async {
    try {
      // Handle the initial deep link if the app is opened via a link
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _processDeepLink(initialLink);

        // Set the initial link to null after processing
        setState(() {
          _deepLink = "Link processed and cleared.";
        });
      }

      // Listen to deep link changes while the app is active
      linkStream.listen((String? deepLink) {
        if (deepLink != null) {
          _processDeepLink(deepLink);
        }
      });
    } catch (e) {
      print("Error initializing deep link listener: $e");
    }
    // }
  }

  // Process deep links
  void _processDeepLink(String deepLink) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var google_sign_initiated = localStorage.getString('google_sign_initiated');

    if (google_sign_initiated == '1') {
      Uri uri = Uri.parse(deepLink);
      String? tokenParam = uri.queryParameters['token'];

      if (tokenParam != null) {
        // Decode the token
        String decodedToken = utf8.decode(base64.decode(tokenParam));
        setState(() {
          token = decodedToken;
        });
        print("Decoded Token: $decodedToken");

        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('user', decodedToken);

        // Navigate to the Dashboard
        _navigateToDashboard(decodedToken);
      } else {
        // Handle invalid token or logout case
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        await localStorage.clear();

        // Navigate back to LoginPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashBoardPage()),
          (route) => false,
        );
      }

      // Indicate link has been processed
      setState(() {
        _deepLink = "Processed and cleared: $deepLink";
      });
    }
  }

  void _navigateToDashboard(String decodedToken) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashBoardPage(),
      ),
    );
  }

  Future _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      Loading().loader(context, "Logging in...Please wait");

      var data = {
        'name': credential.givenName ?? 'User',
        'email': credential.email ?? '',
        'user_id': credential.userIdentifier,
        'profile_photo': '', // Apple doesn't provide a profile photo
      };

      var res = await CallApi().postData(data, 'user/social-media-login');
      var body = json.decode(res.body);

      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('user', json.encode(body['data']));
        Navigator.pop(context);
        FlutterMetaSdk().logEvent(
          name: 'customerLoginApple',
          parameters: {
            'button_id': 'loggin with Apple button was clicked',
          },
        );
        return Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashBoardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 8000),
            content: Text(body['message'].toString()),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
      }
      Navigator.pop(context);
    } catch (error) {
      print("Apple Sign-In Error: $error");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign-In Error'),
            content: Text(
              'An error occurred during Apple Sign-In:\n\n$error',
              style: const TextStyle(color: Colors.red),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
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

  Widget _loginWithApple(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleAppleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                FontAwesomeIcons.apple,
                color: Colors.white,
                size: 20,
              ),
            ),
            Text(
              'Login with Apple',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    var data = {};
    // if (selectedOption == 1) {

    if (_emailController.text == "" || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 8000),
          content: const Text("Email address cannot be empty"),
          action: SnackBarAction(
            label: 'X',
            textColor: Colors.orange,
            onPressed: () {},
          ),
        ),
      );
      return;
    } else {
      data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim()
      };
    }
    // } else {
    //   if (_phoneNumberController.text == "" ||
    //       _phoneNumberController.text.isEmpty) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         backgroundColor: Colors.red,
    //         duration: const Duration(milliseconds: 8000),
    //         content: const Text("Phone Number cannot be empty"),
    //         action: SnackBarAction(
    //           label: 'X',
    //           textColor: Colors.orange,
    //           onPressed: () {},
    //         ),
    //       ),
    //     );
    //     return;
    //   } else {
    //     data = {
    //       'telephone': _phoneNumberController.text,
    //       'password': _passwordController.text
    //     };
    //   }
    // }

    var res = await CallApi().postData(data, 'user/login');
    Loading().loader(context, "Logging in...Please wait");

    var body = json.decode(res.body);

    if (res.statusCode == 200) {
      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('user', json.encode(body['data']));
        Navigator.pop(context);

        FlutterMetaSdk().logEvent(
          name: 'customerLogin',
          parameters: {
            'button_id': 'loggin button was clicked',
          },
        );

        return Navigator.push(context,
            MaterialPageRoute(builder: (context) => const DashBoardPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 8000),
            content: Text(body['message'].toString()),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
      }
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 8000),
          content: Text("Server Error! ${res.statusCode}"),
          action: SnackBarAction(
            label: 'X',
            textColor: Colors.orange,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Future _handleGoogleSignIn() async {
  //   try {
  //     final user = await GoogleSignInApi.login();
  //     if (user != null) {
  //       // Get the providerId
  //       final providerId =
  //           user.id; // This is the providerId (unique to the Google account)

  //       var data = {
  //         'name': user.displayName,
  //         'email': user.email,
  //         'user_id': providerId,
  //         'profile_photo': user.photoUrl,
  //       };

  //       var res = await CallApi().postData(data, 'user/social-media-login');
  //       var body = json.decode(res.body);

  //       if (body['success']) {
  //         SharedPreferences localStorage =
  //             await SharedPreferences.getInstance();
  //         localStorage.setString('user', json.encode(body['data']));
  //         Navigator.pop(context);
  //         return Navigator.push(context,
  //             MaterialPageRoute(builder: (context) => const DashBoardPage()));
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             backgroundColor: Colors.red,
  //             duration: const Duration(milliseconds: 8000),
  //             content: Text(body['message'].toString()),
  //             action: SnackBarAction(
  //               label: 'X',
  //               textColor: Colors.orange,
  //               onPressed: () {},
  //             ),
  //           ),
  //         );
  //       }
  //     } else {
  //       print('Sign in aborted by user');
  //     }
  //   } catch (error) {
  //     print('Sign in failed: $error');

  //     // Show a dialog with the error message
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Text('Sign-In Error'),
  //           content: Text('Failed to sign in: $error'),
  //           actions: <Widget>[
  //             TextButton(
  //               child: Text('OK'),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }

  Future<void> _handleGoogleSignIn() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.setString('google_sign_initiated', '1');

    final Uri deepLinkUrl =
        Uri.parse('https://justhomes.co.ke/login/google-android');

    FlutterMetaSdk().logEvent(
      name: 'customerLoginGoogle',
      parameters: {
        'button_id': 'loggin with Google button was clicked',
      },
    );

    if (await canLaunchUrl(deepLinkUrl)) {
      await launchUrl(
        deepLinkUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $deepLinkUrl';
    }
  }

  Widget _loginWithGoogle(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                FontAwesomeIcons.google,
                color: Colors.white,
                size: 20,
              ),
            ),
            Text(
              'Login with Google',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleLogin(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padding(
            //   padding: const EdgeInsets.only(right: 8.0),
            //   child: Icon(
            //     FontAwesomeIcons.accessibleIcon,
            //     color: Colors.white,
            //     size: 20,
            //   ),
            // ),
            Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildEmail(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _emailController,
        style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface), // Dynamic text color
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Email/Phone',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your Email | Phone.',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Enter Email to continue';
          }
          return null;
        },
        onSaved: (value) {
          _emailController.text = value!;
        },
      ),
    );
  }

  _buildPhone(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _phoneNumberController,
        style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface), // Dynamic text color
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Phone',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your Phone Number.',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter phone number to continue';
          }
          return null;
        },
        onSaved: (value) {
          _emailController.text = value!;
        },
      ),
    );
  }

  _buildPassword(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _passwordController,
        style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface), // Dynamic text color
        obscureText: _obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Password',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your password',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Enter Password to continue';
          }
          return null;
        },
        onSaved: (value) {
          _passwordController.text = value!;
        },
      ),
    );
  }

  _buildForgetPassword(context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
          );
        },
        child: Text(
          "Forgot your password?",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary, // Dynamic text color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildHeader(context),
      drawer: buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 60, 20, 10),
                child: Column(
                  children: [
                    Text(
                      'LOGIN',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 25), // Dynamic text color
                    ),
                    Text(
                      'Login into your account',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface), // Dynamic text color
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildEmail(context),
                          const SizedBox(height: 30.0),
                          _buildPassword(context),
                          const SizedBox(height: 15.0),
                          _buildForgetPassword(context),
                          _loginButton(context),
                          const SizedBox(height: 15.0),
                          _buildRegisterButton(context),
                          const SizedBox(height: 30.0),
                          Platform.isAndroid
                              ? _loginWithGoogle(context)
                              : Container(),
                          const SizedBox(height: 15.0),
                          Platform.isIOS
                              ? _loginWithApple(context)
                              : Container(),
                        ],
                      ),
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

Widget _buildForgetPassword(BuildContext context) {
  return Container(
    margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
    alignment: Alignment.topRight,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
        );
      },
      child: Text(
        "Forgot your password?",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary, // Dynamic text color
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildRegisterButton(BuildContext context) {
  return TextButton(
    onPressed: () {
      // Navigate to registration page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const RegisterPage()), // Replace with your RegisterPage widget
      );
    },
    child: Text(
      'Don’t have an account? Register',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildPassword(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      decoration: const InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      onChanged: (value) {
        // Handle password input logic if needed
      },
    ),
  );
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
