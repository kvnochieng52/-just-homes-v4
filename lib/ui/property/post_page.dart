import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/GMaps.dart';
import 'package:just_apartment_live/ui/property/subscription_status_card.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_preview.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/town_input.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/title.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _propertySubmissionService = PropertySubmissionService();

  var _userTown = '';
  var _userRegion = '';
  var _userAddress = '';
  var _lat = 0.0;
  var _lon = 0.0;

  final _titleController = TextEditingController();
  List<File> _images = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  var _webUrl = '';
  bool _hasGotApiLink = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchWebUrl();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var user_id = user['id'];

    if (user_id == null) {
      // User not logged in, navigate to LoginPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      setState(() {
        _webUrl = apiLink['web'].toString();
        _hasGotApiLink = true;
      });
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  Future<void> _handleImageSelection(List<File> newImages) async {
    setState(() {
      _images = newImages;
      _isUploading = true;
    });

    try {
      final uploadedUrls = await _uploadImages(_images);
      setState(() {
        _uploadedImageUrls = uploadedUrls;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload images: $e')),
      );
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    final uploadedUrls = <String>[];

    for (final image in images) {
      try {
        final url = await _uploadSingleImage(image);
        uploadedUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }

    return uploadedUrls;
  }

  Future<String> _uploadSingleImage(File image) async {
    final link = _hasGotApiLink ? _webUrl : '';
    final uri = Uri.parse('${link}api/property/upload-property-image');

    final dir = await getTemporaryDirectory();
    final targetPath =
        path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      quality: 60,
    );

    if (compressedFile == null) {
      throw Exception('Failed to compress image');
    }

    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', compressedFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(responseData);
      return data['image_path'];
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }

  void _handleImageRemove(int index) {
    setState(() {
      _images.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildHeader(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 1.0,
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildTitle(context),
                  const SubscriptionStatusCard(),
                  _buildPostForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Post A Property",
            style: TextStyle(fontSize: 20),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
            "Step 1 of 3",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPostForm(context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ImagePreview(
            images: _images,
            uploadedImageUrls: _uploadedImageUrls,
            isUploading: _isUploading,
            onImagesChanged: _handleImageSelection,
            onRemoveImage: _handleImageRemove,
          ),
          TitleInput(
            titleController: _titleController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter property title';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          LocationFormField(
            apiKey: 'AIzaSyCVvR6ZMW_H-c2O6Tjpcu1_ko8QkmkCfPQ',
            hintText: "Enter your location",
            onSaved: (value) {
              if (value != null) {
                _userTown = value['locality'] ?? "Nairobi";
                _userRegion = value['county'] ?? "Nairobi";
                _userAddress = value['mainText'];
                _lat = value['latitude'];
                _lon = value['longitude'];
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_isUploading || _isSubmitting)
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      if (_uploadedImageUrls.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please upload at least one image'),
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      final localStorage =
                          await SharedPreferences.getInstance();
                      final user =
                          json.decode(localStorage.getString('user') ?? '{}');
                      final userId = user['id'];

                      await _propertySubmissionService.submitProperty(
                        step: 1,
                        propertyTitle: _titleController.text,
                        town: _userRegion,
                        subRegion: _userTown,
                        latitude: _lat,
                        longitude: _lon,
                        country: "Kenya",
                        countryCode: "KE",
                        address: _userAddress,
                        userId: userId,
                        images: _uploadedImageUrls,
                        context: context,
                        link: _hasGotApiLink ? _webUrl : '',
                      );

                      setState(() => _isSubmitting = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: (_isUploading || _isSubmitting)
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Next"),
          )
        ],
      ),
    );
  }
}
