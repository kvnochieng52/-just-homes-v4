import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';

class ActivationPage extends StatefulWidget {
  @override
  _ActivationPageState createState() => _ActivationPageState();

  final dynamic userDetails;

  const ActivationPage({super.key, required this.userDetails});
}

class _ActivationPageState extends State<ActivationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _code = '';
  bool _isResending = false;

  _verifyCode() async {
    if (_code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter the complete code.'),
        ),
      );
      return;
    }
    // Ensure both codes are trimmed and converted to strings before comparison
    String enteredCode = _code.trim();
    String actualCode = widget.userDetails['activation_code'].toString().trim();

    if (enteredCode == actualCode) {
      Loading().loader(context, "Activating...Please wait");

      var data = {
        'user_id': widget.userDetails['id'],
        'activation_code': widget.userDetails['activation_code']
      };
      var res = await CallApi().postData(data, 'user/activate-account');

      var body = json.decode(res.body);

      if (body['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(body['message']),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('The reset code is incorrect.'),
        ),
      );
    }
  }

  void _resendEmail() async {
    setState(() {
      _isResending = true;
    });

    Loading().loader(context, "Sending Email...Please wait");

    var data = {
      'user_id': widget.userDetails['id'],
      //'activation_code': widget.userDetails['activation_code']
    };
    var res = await CallApi().postData(data, 'user/resend-activate-code');

    var body = json.decode(res.body);

    if (body['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(body['message']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Email could not be sent. Please try later"),
        ),
      );
    }

    Navigator.pop(context);

    setState(() {
      _isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activate Account',
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
                'Enter the Activation code sent to your email address to activate your Account.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    PinCodeTextField(
                      appContext: context,
                      length: 4, // Number of boxes
                      obscureText: false,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(5),
                        fieldHeight: 50,
                        fieldWidth: 50,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: Colors.grey,
                        inactiveColor: Colors.grey,
                      ),
                      cursorColor: Colors.black,
                      animationDuration: const Duration(milliseconds: 300),
                      onChanged: (value) {
                        setState(() {
                          _code = value;
                        });
                      },
                      onCompleted: (value) {
                        _verifyCode();
                      },
                    ),
                    const SizedBox(height: 30.0),
                    _buildVerifyCodeButton(),
                    const SizedBox(height: 20.0),
                    _buildResendEmailButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildVerifyCodeButton() {
    return Container(
      decoration: ThemeHelper().buttonBoxDecoration(context),
      child: ElevatedButton(
        style: ThemeHelper().buttonStyle(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
          child: Text(
            'Verify Code'.toUpperCase(),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        onPressed: () => _verifyCode(),
      ),
    );
  }

  _buildResendEmailButton() {
    return _isResending
        ? const CircularProgressIndicator()
        : TextButton(
            onPressed: () => _resendEmail(),
            child: Text(
              'Resend Email',
              style: TextStyle(
                color: HexColor('#252742'),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }
}
