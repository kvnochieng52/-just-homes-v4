import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/forgot_password/reset_password_page.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';

class CodeVerificationPage extends StatefulWidget {
  final String resetCode;
  final dynamic userDetails;

  const CodeVerificationPage(
      {super.key, required this.resetCode, required this.userDetails});

  @override
  _CodeVerificationPageState createState() => _CodeVerificationPageState();
}

class _CodeVerificationPageState extends State<CodeVerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _code = '';
  bool _isResending = false;

  _verifyCode() {
    if (_code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter the complete code.'),
        ),
      );
      return;
    }

    if (_code == widget.resetCode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(
            userDetails: widget.userDetails,
          ),
        ),
      );
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

    var data = {
      'user_id': widget.userDetails['id'],
      'resetCode': widget.resetCode
    };
    var res = await CallApi().postData(data, 'user/resend-verify-code');

    var body = json.decode(res.body);

    if (body['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(body['message']),
        ),
      );
    }

    // Simulate email resend logic
    // await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Code',
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
                'Enter the reset code sent to your email address to reset your password.',
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
              'Resend Code',
              style: TextStyle(
                color: HexColor('#252742'),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }
}
