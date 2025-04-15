import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/forgot_password/forgot_password.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/register/activation_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _acceptTerms = false;

  var _userDetails;
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url); // Convert the string to a Uri object
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  _buildTelephone(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _telephoneController,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, // Dynamic text color
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Telephone',
          labelStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7), // Dynamic label color
          ),
          hintText: 'Enter your Telephone No.',
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.5), // Dynamic hint color
          ),
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
            return 'Please Enter your Telephone Number.';
          }
          return null;
        },
        onSaved: (value) {
          _telephoneController.text = value!;
        },
      ),
    );
  }

  _buildFullName(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, // Dynamic text color
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Full Names',
          labelStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7), // Dynamic label color
          ),
          hintText: 'Enter your Full Names.',
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.5), // Dynamic hint color
          ),
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
            return 'Please Enter your Full Names';
          }
          return null;
        },
        onSaved: (value) {
          _nameController.text = value!;
        },
      ),
    );
  }

  _buildEmail(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _emailController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, // Dynamic text color
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Email Address',
          labelStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7), // Dynamic label color
          ),
          hintText: 'Enter your Email Address.',
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.5), // Dynamic hint color
          ),
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
            return 'Please Enter your Email Address';
          }
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please Enter a Valid Email Address';
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
        obscureText: !_passwordVisible,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, // Dynamic text color
        ),
        decoration: ThemeHelper()
            .textInputDecoration(
              'Password',
              'Enter your password',
            )
            .copyWith(
              filled: true,
              fillColor: Theme.of(context)
                  .scaffoldBackgroundColor, // Background color of the input
              labelStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7), // Dynamic label color
              ),
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5), // Dynamic hint color
              ),
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Focused border color
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).colorScheme.onSurface, // Icon color
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Enter Password';
          }
          return null;
        },
        onSaved: (value) {
          _passwordController.text = value!;
        },
      ),
    );
  }

  _buildConfirmPassword(context) {
    return Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_confirmPasswordVisible,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, // Dynamic text color
        ),
        decoration: ThemeHelper()
            .textInputDecoration(
              'Confirm Password',
              'Enter your password again',
            )
            .copyWith(
              filled: true,
              fillColor: Theme.of(context)
                  .scaffoldBackgroundColor, // Background color of the input
              labelStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7), // Dynamic label color
              ),
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5), // Dynamic hint color
              ),
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Focused border color
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Theme.of(context).colorScheme.onSurface, // Icon color
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Confirm Password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        onSaved: (value) {
          _confirmPasswordController.text = value!;
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

  _buildTermsAndPrivacyCheckbox(context) {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (bool? value) {
            setState(() {
              _acceptTerms = value!;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary, // Checkbox color
          checkColor: Theme.of(context).colorScheme.onPrimary, // Check color
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I accept the ',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface), // Dynamic text color
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                ),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary, // Dynamic color
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final links = await Configuration().getCountryApiLink();
                      String webUrl = links['web']!;
                      _launchUrl("${webUrl}terms-of-service");
                    },
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface), // Dynamic text color
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary, // Dynamic color
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final links = await Configuration().getCountryApiLink();
                      String webUrl = links['web']!;
                      _launchUrl("${webUrl}privacy-policy");
                    },
                ),
                TextSpan(
                  text: '',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface), // Dynamic text color
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildLoginButton(context) {
    return SizedBox(
      width: double.infinity, // Makes the button full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple, // Set the background color to purple
          foregroundColor: Colors.white, // Set the text color to white
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10.0), // Adjusts the button's shape
          ),
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 10), // Button padding
        ),
        child: Text(
          'Register'.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          // Check if the form is valid
          if (_formKey.currentState!.validate()) {
            if (_acceptTerms) {
              _registerUser(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                      'Please accept the Terms & Conditions and Privacy Policy'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  _buildRegisterButton(context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: "Have an Account? ",
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface, // Dynamic text color
            ),
          ),
          TextSpan(
            text: 'Login Now',
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary, // Dynamic color
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: buildHeader(context),
      //drawer: public_drawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 40, 20, 10),
                child: Column(
                  children: [
                    Text(
                      'REGISTER',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey,
                        fontSize: 25,
                      ),
                    ),
                    Text(
                      'Register your Free Account',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildFullName(context),
                          const SizedBox(height: 20.0),
                          _buildEmail(context),
                          const SizedBox(height: 20.0),
                          _buildTelephone(context),
                          const SizedBox(height: 20.0),
                          _buildPassword(context),
                          const SizedBox(height: 20.0),
                          _buildConfirmPassword(context),
                          const SizedBox(height: 15.0),
                          _buildForgetPassword(context),
                          _buildTermsAndPrivacyCheckbox(context),
                          _buildLoginButton(context),
                          _buildRegisterButton(context),
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

  _registerUser(context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Loading().loader(context, "Registering...Please wait");

    var data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text,
      'password': _passwordController.text
    };
    var res = await CallApi().postData(data, 'user/register');

    var body = json.decode(res.body);

    if (body['success']) {
      setState(() {
        _userDetails = body['data'];
      });

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
      Navigator.pop(context);
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivationPage(
            userDetails: _userDetails,
          ),
        ),
      );
    } else {
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
      Navigator.pop(context);
    }
  }
}
