import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

bool _isUploading = false;

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _initDataFetched = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _instagramController = TextEditingController();
  final _profileController = TextEditingController();

  String? _companyLogo;
  String? _userProfilePhoto;
  File? _logoImage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getInitData();
    _fetchWebUrl();
  }

  Future<void> _pickImage({bool isProfile = false}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _logoImage = File(pickedFile.path);
        }
      });
      if (isProfile) {
        _uploadProfilePhoto();
      } else {
        _uploadLogo();
      }
    }
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var data = {'user_id': user['id']};

    var res = await CallApi().postData(data, 'property/get-user-properties');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _nameController.text = body['data']['userDetails']['name'] ?? '';
          _emailController.text = body['data']['userDetails']['email'] ?? '';
          _mobileController.text =
              body['data']['userDetails']['telephone'] ?? '';
          _companyController.text =
              body['data']['userDetails']['company_name']?.toString() ?? '';
          _facebookController.text =
              body['data']['userDetails']['facebook'] ?? '';
          _twitterController.text =
              body['data']['userDetails']['twitter'] ?? '';
          _tiktokController.text = body['data']['userDetails']['tiktok'] ?? '';
          _instagramController.text =
              body['data']['userDetails']['instagram'] ?? '';
          _profileController.text =
              body['data']['userDetails']['profile'] ?? '';

          _companyLogo = body['data']['userDetails']['company_logo'] ?? '';
          _userProfilePhoto = body['data']['userDetails']['avatar'] ?? '';
          _initDataFetched = true;
        });
      }
    }
  }

  _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    Loading().loader(context, "Processing...Please wait");

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'telephone': _mobileController.text,
      'company': _companyController.text,
      'facebook': _facebookController.text,
      'twitter': _twitterController.text,
      'tiktok': _tiktokController.text,
      'instagram': _instagramController.text,
      'profile': _profileController.text,
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'user/update-profile');

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
                      Navigator.of(dialogContext).pop(); // Close the dialog
                      Navigator.of(context).pop(); // Close the profile page
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

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;

    setState(() {
      _isUploading = true;
    });

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var userId = user['id'];

    // final uri = Uri.parse('${Configuration.API_URL}user/upload-company-logo');
    // final request = http.MultipartRequest('POST', uri)
    //   ..fields['user_id'] = userId.toString()
    //   ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    final links = await Configuration().getCountryApiLink();
    final apiUrl = links['api']!;
    final uri = Uri.parse('${apiUrl}user/upload-company-logo');

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
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.white,
              onPressed: () {
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

  Future<void> _uploadProfilePhoto() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploading = true;
    });

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var userId = user['id'];

    // final uri = Uri.parse('${Configuration.API_URL}user/upload-profile-photo');

    final links = await Configuration().getCountryApiLink();
    final uri = Uri.parse('${links['api']}user/upload-profile-photo');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId.toString()
      ..files
          .add(await http.MultipartFile.fromPath('logo', _profileImage!.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Profile photo uploaded successfully. Click on update profile to finish",
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to upload profile photo: $responseBody")),
        );
        print("Failed to upload profile photo: $responseBody");
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

  void _removeImage({bool isProfile = false}) {
    setState(() {
      if (isProfile) {
        _profileImage = null;
        _userProfilePhoto = '';
      } else {
        _logoImage = null;
        _companyLogo = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: HexColor('#252742'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_initDataFetched)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        8,
                        (index) => Container(
                          height: 40.0,
                          width: double.infinity,
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          margin: const EdgeInsets.only(bottom: 16.0),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_initDataFetched) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 15.0),
                  child: Center(
                    child: Text("Edit Profile",
                        style: TextStyle(
                            color: Theme.of(context)
                                .appBarTheme
                                .titleTextStyle
                                ?.color)),
                  ),
                ),
                _buildUploadProfilePhoto(),
                _buildTextField(_nameController, 'First & Last Name',
                    'Enter Your Name', true),
                _buildTextField(_emailController, 'Email Address',
                    'Enter Email Address', true),
                _buildTextField(_mobileController, 'Mobile Number',
                    'Enter Mobile Number', true, TextInputType.phone),
                _buildTextField(_companyController, 'Company Name (optional)',
                    'Enter Company Name', false),
                _buildUploadCompanyLogo(),
                _buildTextField(_facebookController, 'Facebook Link (optional)',
                    'Enter Facebook Link', false),
                _buildTextField(_twitterController, 'Twitter Link (optional)',
                    'Enter Twitter Link', false),
                _buildTextField(_tiktokController, 'TikTok Link (optional)',
                    'Enter TikTok Link', false),
                _buildTextField(_instagramController,
                    'Instagram Link (optional)', 'Enter Instagram Link', false),
                _buildTextField(
                    _profileController,
                    'Profile Description (optional)',
                    'Enter Profile Description',
                    false),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _submitForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Update Profile",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  var defaultImage = 'https://justhomes.co.ke/images/back6.jpg';
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

  Widget _buildUploadCompanyLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Upload the Company Logo"),
        GestureDetector(
          onTap: () => _pickImage(isProfile: false),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                  image: _logoImage != null
                      ? DecorationImage(
                          image: FileImage(_logoImage!),
                          fit: BoxFit.cover,
                        )
                      : (_companyLogo != null && _companyLogo!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(hasGotApiLink
                                  ? _webUrlFuture + _companyLogo!
                                  : defaultImage),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: _logoImage == null &&
                        (_companyLogo == null || _companyLogo!.isEmpty)
                    ? Icon(Icons.add_a_photo, size: 30, color: Colors.grey[700])
                    : null,
              ),
              if (_logoImage != null ||
                  (_companyLogo != null && _companyLogo!.isNotEmpty))
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _removeImage(isProfile: false),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_isUploading) CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildUploadProfilePhoto() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Upload the Profile Photo"),
            GestureDetector(
              onTap: () => _pickImage(isProfile: true),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _getImageProvider(),
                    child: _profileImage == null &&
                            (_userProfilePhoto == null ||
                                _userProfilePhoto!.isEmpty)
                        ? Icon(Icons.add_a_photo,
                            size: 30, color: Colors.grey[700])
                        : null,
                  ),
                  if (_profileImage != null ||
                      (_userProfilePhoto != null &&
                          _userProfilePhoto!.isNotEmpty))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeImage(isProfile: true),
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

  ImageProvider<Object>? _getImageProvider() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_userProfilePhoto != null && _userProfilePhoto!.isNotEmpty) {
      return NetworkImage(
        _userProfilePhoto!.startsWith("http")
            ? _userProfilePhoto!
            : hasGotApiLink
                ? _webUrlFuture + _userProfilePhoto!
                : defaultImage,
      );
    }
    return null;
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      String hintText, bool isRequired,
      [TextInputType inputType = TextInputType.text]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
        ),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '$labelText is required';
          }
          return null;
        },
      ),
    );
  }
}
