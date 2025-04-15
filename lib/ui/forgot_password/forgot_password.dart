import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/forgot_password/code_verification_page.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  var _resetCode = '';
  var _userDeatils;

  _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Background color
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.1), // Shadow color
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface), // Text color
        decoration: ThemeHelper()
            .textInputDecoration(
              'Email Address',
              'Enter your Email Address.',
            )
            .copyWith(
              fillColor: Theme.of(context)
                  .colorScheme
                  .surface, // Background color for input
              filled: true,
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6), // Hint text color
              ),
            ),
        validator: (value) {
          final email = value?.trim(); // Trim whitespace
          if (email == null || email.isEmpty) {
            return 'Please Enter your Email Address';
          }
          // Improved regex for email validation
          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
          if (!emailRegex.hasMatch(email)) {
            return 'Please Enter a Valid Email Address';
          }
          return null;
        },
      ),
    );
  }

  _buildResetPasswordButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple, // Set the background color to purple
        foregroundColor: Colors.white, // Set the text color to white
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10.0), // Adjusts the button's shape
        ),
        padding: const EdgeInsets.fromLTRB(40, 10, 40, 10), // Button padding
        minimumSize: const Size(double.infinity, 50), // Full width button
      ),
      child: Text(
        'Reset Password'.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () => _resetPassword(),
    );
  }

  _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Loading().loader(context, "Sending Email...Please wait");

    var data = {'email': _emailController.text};
    var res = await CallApi().postData(data, 'user/forgot-password');

    var body = json.decode(res.body);

    if (body['success']) {
      setState(() {
        _resetCode = body['data']['resetCode'].toString();
        _userDeatils = body['data']['userDetails'];
      });

      print(_resetCode);
      print(_userDeatils);

      // Ensure any existing SnackBar is dismissed before navigation
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 8000),
          content: Text(body['message'].toString()),
          action: SnackBarAction(
            label: 'X',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      // Push the CodeVerificationPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CodeVerificationPage(
            resetCode: _resetCode,
            userDetails: _userDeatils,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 8000),
          content: Text(body['message'].toString()),
          action: SnackBarAction(
            label: 'X',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }

    // Remove this redundant pop call
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.white, // Set the text color to white
          ),
        ),
        backgroundColor: HexColor('#252742'),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
          child: Column(
            children: [
              const SizedBox(height: 20.0),
              const Text(
                'Enter your email address to receive password reset instructions.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEmailField(),
                    const SizedBox(height: 30.0),
                    _buildResetPasswordButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
