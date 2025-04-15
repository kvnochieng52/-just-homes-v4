import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

bool _isUploading = false;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List _userProperties = [];
  bool _initDataFetched = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  var islogdin = 0;

  String? _userProfilePhoto;

  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
      _uploadLogo(); // Automatically upload after selection
    }
  }

  _checkifUserisLoggedIn() async {
    int isLoggedIn = 0;
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    isLoggedIn = user['id'] != null ? 1 : 0;
    return isLoggedIn;
  }

  @override
  void initState() {
    super.initState();
    _getInitData();
    _fetchWebUrl();
  }

  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-user-properties');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (body['success']) {
        setState(() {
          _userProperties = body['data']['properties'];
          _emailController.text = body['data']['userDetails']['email'] ?? '';
          _userProfilePhoto = body['data']['userDetails']['avatar'] ?? '';

          _emailController.text = body['data']['userDetails']['email'] ?? '';
          _initDataFetched = true;
        });
      }
    }
  }

  _updatePassword(context) async {
    if (!_settingsFormKey.currentState!.validate()) {
      return;
    }
    _settingsFormKey.currentState!.save();

    if (_passwordController.text != _repeatPasswordController.text) {
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Your Password does not match.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Okay'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          });
    } else {
      Loading().loader(context, "Processing...Please wait");

      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      var data = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'user_id': user['id'],
      };

      var res = await CallApi().postData(data, 'user/update-password');
      var body = json.decode(res.body);

      if (res.statusCode == 200) {
        if (body['success']) {
          showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Success'),
                  content: const Text('Profile successfully updated.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Okay'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        }
      } else {
        Navigator.pop(context);
        print('Failed to upload images');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: HexColor('#252742'),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black87),
        ),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: HexColor('#252742'),
          secondary: HexColor('#800080'),
        ),
      ),
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: HexColor('#252742'),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: HexColor('#252742'),
          secondary: HexColor('#800080'),
        ),
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              "Account Settings",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white), // Set color to white
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                color: Colors.white,
                onPressed: () {
                  _checkifUserisLoggedIn().then((result) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            result == 1 ? const PostPage() : LoginPage(),
                      ),
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_pin),
                color: Colors.white,
                onPressed: () {
                  _checkifUserisLoggedIn().then((result) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _initDataFetched ? _buildForm() : _buildShimmerEffect(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _settingsFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 15.0),
            child: Center(
              child: Text("Account Settings",
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "Enter Email Address",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                labelStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter Your Email Address';
                }
                final emailRegExp =
                    RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                if (!emailRegExp.hasMatch(value)) {
                  return 'Enter a valid Email Address';
                }
                return null;
              },
              onSaved: (value) {
                _emailController.text = value!;
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Enter Password",
                hintText: "Enter Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context)
                        .iconTheme
                        .color, // Set icon color based on theme
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                labelStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter Your Password';
                }
                return null;
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: TextFormField(
              controller: _repeatPasswordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Repeat Password",
                hintText: "Repeat Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context)
                        .iconTheme
                        .color, // Set icon color based on theme
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                labelStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please repeat the password';
                }
                return null;
              },
            ),
          ),
          _buildUploadProfilePhoto(),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 10.0, right: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor('#800080'), // Purple color
                ),
                onPressed: () => _updatePassword(context),
                child: const Text(
                  "Update Profile",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    Color baseColor;
    Color highlightColor;

    // Choose colors based on the current theme
    if (theme.brightness == Brightness.dark) {
      baseColor = Colors.grey[850]!; // Darker base color for dark mode
      highlightColor =
          Colors.grey[700]!; // Lighter highlight color for dark mode
    } else {
      baseColor = Colors.grey[300]!; // Base color for light mode
      highlightColor = Colors.grey[100]!; // Highlight color for light mode
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
            child: Container(
              height: 60.0,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadProfilePhoto() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: double.infinity, // Full screen width
        padding: const EdgeInsets.all(10), // Padding inside the border
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey, width: 1), // Border color and width
          borderRadius: BorderRadius.circular(5), // Border radius
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Upload the Profile Photo"),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _getImageProvider(),
                    child: _logoImage == null &&
                            (_userProfilePhoto == null ||
                                _userProfilePhoto!.isEmpty)
                        ? Icon(Icons.add_a_photo,
                            size: 30, color: Colors.grey[700])
                        : null,
                  ),
                  if (_logoImage != null ||
                      (_userProfilePhoto != null &&
                          _userProfilePhoto!.isNotEmpty))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _removeImage, // Call updated remove function
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_isUploading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  bool hasGotApiLink = false;

  var _webUrlFuture = '';

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      _webUrlFuture = apiLink['web'].toString();
      hasGotApiLink = true;
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  ImageProvider<Object>? _getImageProvider() {
    // print(
    //     "IMAGE LINK: " + Configuration.WEB_URL + _userProfilePhoto.toString());
    if (_logoImage != null) {
      return FileImage(_logoImage!);
    } else if (_userProfilePhoto != null && _userProfilePhoto!.isNotEmpty) {
      return NetworkImage(
        _userProfilePhoto!.startsWith("http")
            ? _userProfilePhoto!
            : hasGotApiLink
                ? _webUrlFuture + _userProfilePhoto!
                : 'https://justhomes.co.ke/images/back6.jpg',
      );
    }
    return null;
  }

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;

    setState(() {
      _isUploading = true;
    });

    // Retrieve user ID from SharedPreferences
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var userId = user['id'];

    // final uri = Uri.parse('${Configuration.API_URL}user/upload-profile-photo');

    // final request = http.MultipartRequest('POST', uri)
    //   ..fields['user_id'] = userId.toString() // Add user ID to request fields
    //   ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    final links = await Configuration().getCountryApiLink();
    final apiUrl = links['api']!;
    final uri = Uri.parse('${apiUrl}user/upload-profile-photo');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId.toString() // Add user ID to request fields
      ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Logo uploaded successfully. Click on update profile to finish",
            ),
            duration: const Duration(
                seconds: 3), // Delay the disappearance (adjust as needed)
            action: SnackBarAction(
              label: 'X',
              textColor:
                  Colors.white, // Optional: Customize the "X" button color
              onPressed: () {
                // Dismiss the SnackBar when the user presses the "X" button
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload logo: $responseBody")),
        );

        print("Failed to upload logo: $responseBody");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
      print("An error occurred: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _logoImage = null; // Clear locally selected image
      _userProfilePhoto = ''; // Clear existing uploaded image URL from network
    });
  }
}
