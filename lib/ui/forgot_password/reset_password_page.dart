import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';

class ResetPasswordPage extends StatefulWidget {
  final dynamic userDetails;

  const ResetPasswordPage({super.key, required this.userDetails});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userDetails['email'];
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Loading().loader(context, "Resetting Password Please wait");

    var data = {
      'user_id': widget.userDetails['id'], // Add user_id to data
      'password': _passwordController.text,
    };
    var res = await CallApi().postData(data, 'user/reset-password');

    var body = json.decode(res.body);

    Navigator.pop(context); // Remove the loading indicator

    if (res.statusCode == 200 && body['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Password reset successful. Please login to continue.'),
        ),
      );
      // Redirect to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginPage(), // Replace with your login page widget
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(body['message'] ?? 'Password reset failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: HexColor('#252742'),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                const Text(
                  'Reset your password using the form below.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30.0),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: ThemeHelper().textInputDecoration(
                      'Email', 'Enter your email address.'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: ThemeHelper()
                      .textInputDecoration(
                        'Password',
                        'Enter your new password.',
                      )
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password should be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: ThemeHelper()
                      .textInputDecoration(
                        'Confirm Password',
                        'Re-enter your new password.',
                      )
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),
                Container(
                  decoration: ThemeHelper().buttonBoxDecoration(context),
                  child: ElevatedButton(
                    style: ThemeHelper().buttonStyle(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                      child: Text(
                        'Reset Password'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    onPressed: () => _resetPassword(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
