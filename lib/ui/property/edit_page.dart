import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_edit_property.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';
import 'package:just_apartment_live/ui/property/post_step2_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_preview.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/title.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/GMaps.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class EditPage extends StatefulWidget {
  final int propertyID;

  const EditPage({Key? key, required this.propertyID}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _propertySubmissionService = PropertySubmissionService();

  List<File> _images = [];
  List<String> _uploadedImageUrls = [];
  List<String> _removedImages = [];
  String _propertyImages = "";

  var _userTown = '';
  var _userRegion = '';
  var _userAddress = '';
  var _lat = 0.0;
  var _lon = 0.0;
  var _defaultAddress = "";

  bool _isUploading = false;
  bool _initDataFetched = false;
  bool _hasGotApiLink = false;
  bool _isSubmitting = false; // New loading state for form submission
  String _webUrl = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchWebUrl();
    _getInitData();
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

  Future<void> _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'user_id': user['id'],
      'propertyID': widget.propertyID,
    };

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _titleController.text =
              body['data']['propertyDetails']['property_title'] ?? "";
          _defaultAddress =
              body['data']['propertyDetails']['google_address']?.toString() ??
                  "";
          _propertyImages =
              body['data']['propertyDetails']['property_images'] ?? "";
          _initDataFetched = true;
        });
      }
    }
  }

  List<String> get propertyImageList {
    return _propertyImages
        .split(',')
        .map((img) => img.trim())
        .where((img) => img.isNotEmpty)
        .toList();
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

    // Compress the image
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

  void _handleExistingImageRemove(String imagePath) {
    setState(() {
      _removedImages.add(imagePath);
      _propertyImages = _propertyImages
          .replaceAll(imagePath, '')
          .replaceAll(',,', ',')
          .trim();
      if (_propertyImages.endsWith(',')) {
        _propertyImages =
            _propertyImages.substring(0, _propertyImages.length - 1);
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_userAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter property address."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true; // Show loading indicator
      });

      try {
        final localStorage = await SharedPreferences.getInstance();
        final user = json.decode(localStorage.getString('user') ?? '{}');
        final userId = user['id'];

        // Combine existing and new images
        final existingImages = propertyImageList
            .where((img) => !_removedImages.contains(img))
            .toList();
        final allImages = [...existingImages, ..._uploadedImageUrls];
        final imagesString = allImages.join(',');

        final response = await _propertySubmissionService.editProperty(
          step: 1,
          propertyTitle: _titleController.text,
          town: _userRegion,
          subRegion: _userTown,
          latitude: _lat,
          longitude: _lon,
          country: "KENYA",
          countryCode: "KE",
          address: _userAddress,
          userId: userId,
          images: imagesString,
          removedImages: _removedImages.join(','),
          propertyID: widget.propertyID,
          context: context,
          link: _hasGotApiLink ? _webUrl : '',
        );

        if (response['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostStep2Page(
                propertyID: widget.propertyID.toString(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update property'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            _initDataFetched ? "Edit Property" : "Loading...",
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const Padding(
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
          if (propertyImageList.isNotEmpty) _buildExistingImagesSection(),
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
            hintText: "Enter property address",
            initialValue: _defaultAddress,
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
            onPressed: (_isUploading || !_initDataFetched || _isSubmitting)
                ? null
                : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : _isUploading
                    ? const Text("Uploading Images...")
                    : Text(_initDataFetched ? "Continue" : "Loading..."),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Existing Images (Tap to remove)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: propertyImageList.map((imagePath) {
            return Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage("$_webUrl/$imagePath"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _handleExistingImageRemove(imagePath),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
