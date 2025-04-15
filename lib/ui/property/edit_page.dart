import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/GMaps.dart';
import 'package:just_apartment_live/ui/property/post_step2_page.dart';
import 'package:just_apartment_live/ui/property/subscription_status_card.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/submit_button.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_preview.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/town_input.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/image_upload_input.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/title.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/regions_input.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditPage extends StatefulWidget {
  final int propertyID;

  const EditPage({Key? key, required this.propertyID}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _propertySubmissionService = PropertySubmissionService();

  var _userTown = '';
  var _userRegion = '';
  var _userAddress = '';

  var _lat = 0.0;
  var _lon = 0.0;
  var _userId = 0;

  var _propertyID = 693;

  final _titleController = TextEditingController();

  bool _isSubRegionEnabled = false;
  bool _isLoadingSubRegions = false;

  List<File> _images = []; // List of selected image files
  List<AssetEntity> _assetEntities = []; // List of selected asset entities
  List<String> uploadedImagePaths = [];

  bool _initDataFetched = false;
  bool _showRegionsInput = false;

  List<Map<String, dynamic>> _townsList = [];
  List<Map<String, dynamic>> _subRegionsList = [];

  var _propertyDetails;
  var _propertyFeaturesList;
  Map<String, dynamic> selectedtown = {"id": 1, "value": "Apple"};

  var _defaultAddress = "";

  var property_images = "";

  List<String> _removedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchWebUrl();
    _getInitData();
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

  _getInitData() async {
    await clearSavedImages();

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
        final List<dynamic> townData = body['data']['townsList'];
        List<Map<String, dynamic>> towns = [];
        for (var tData in townData) {
          towns.add({
            'id': tData['id'],
            'value': tData['value'],
          });
        }

        setState(() {
          _townsList = towns;
          _initDataFetched = true;

          _titleController.text =
              body['data']['propertyDetails']['property_title'] ?? "";
          _defaultAddress =
              body['data']['propertyDetails']['google_address']?.toString() ??
                  "";

          property_images = body['data']['propertyDetails']['property_images'];

          //  print("DEFAULT ADDDDDRESSS: " + _defaultAddress.toString());
        });
      }
    }
  }

  List<String> get propertyImageList {
    return property_images
        .split(',')
        .map((img) => img.trim())
        .where((img) => img.isNotEmpty)
        .toList();
  }

  Future<void> clearSavedImages() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isRemoved = await prefs
          .remove('uploaded_images'); // Remove the stored image paths list
      if (isRemoved) {
        uploadedImagePaths.clear();
        print('Saved image paths cleared.');
      } else {
        print('No saved image paths found.');
      }
    } catch (e) {
      print('Error clearing saved image paths: $e');
    }
  }

  Future<void> pickAssets(BuildContext context) async {
    try {
      final PermissionState result =
          await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 20,
            requestType: RequestType.image,
            selectedAssets: _assetEntities,
          ),
        );

        if (result != null) {
          await clearSavedImages();
          final List<File> newImages = [];
          for (var asset in result) {
            final File? file = await asset.file;
            if (file != null && !_images.any((img) => img.path == file.path)) {
              newImages.add(file);
            }
          }

          setState(() {
            _images.addAll(newImages);
            _assetEntities = result;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required to pick images.'),
          ),
        );
      }
    } catch (e) {
      print("Error picking assets: $e");

      clearSavedImages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while picking images.'),
        ),
      );
    }
  }

  Future<void> uploadImages(File image) async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    print("Uploaded image: ${image.path}");
  }

  Future<void> uploadImage(File image) async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    print("Uploaded image: ${image.path}");
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
                  //SubscriptionStatusCard(),
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
          padding: EdgeInsets.only(top: 10),
          child: Text(
            _initDataFetched ? "Edit Property" : "Loading Please wait...",
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

  Future<void> _loadSavedImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uploadedImagePaths = prefs.getStringList('uploaded_images') ?? [];
    });
  }

  Widget _buildPostForm(context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ImagePreview(
          //   images: _images,
          //   onRemoveImage: (index) {
          //     setState(() {
          //       _images.removeAt(index);
          //       _assetEntities.removeAt(index);
          //     });
          //   },
          //   onAddImage: () => pickAssets(context),
          //   onUploadImage: uploadImages, // Only upload on form submission
          // ),

          ImagePreview(
            images: _images,
            onRemoveImage: (index) {
              setState(() {
                _images.removeAt(index);
              });
            },
            onAddImage: () => pickAssets(context),
            onUploadImage: uploadImages,
          ),

          _removedImagesSection(),

          TitleInput(
            titleController: _titleController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter property title';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          LocationFormField(
            apiKey: 'AIzaSyCVvR6ZMW_H-c2O6Tjpcu1_ko8QkmkCfPQ',
            hintText: "Enter property address",
            //  initialValue: _defaultAddress,
            // initialValue: "${_defaultAddress}",
            onSaved: (value) {
              if (value != null) {
                // print("Selected county: ${value['county']}");
                // print("Selected locality: ${value['locality']}");
                // print("Selected LAT: ${value['latitude']}");
                // print("Selected LON: ${value['longitude']}");
                _userTown = value['locality'] ?? "Nairobi";
                _userRegion = value['county'] ?? "Nairobi";
                _userAddress = value['mainText'];
                _lat = value['latitude'];
                _lon = value['longitude'];
              }
            },
          ),
          // NextButtonWidget(
          //   images: _images,
          //   userTown: _userTown,
          //   userRegion: _userRegion,
          //   titleController: _titleController,
          //   latitude: _lat,
          //   longitude: _lon,
          //   userId: _userId,
          //   propertySubmissionService: _propertySubmissionService,
          //   formKey: _formKey,
          // )
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: _initDataFetched
                ? () async {
                    _formKey.currentState!.save();

                    if (_userAddress == null || _userAddress!.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter property address."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // Don't proceed with form submission
                    }

                    if (uploadedImagePaths.isEmpty) {
                      _loadSavedImagePaths();
                      setState(() {});
                    }

                    SharedPreferences localStorage =
                        await SharedPreferences.getInstance();
                    var user =
                        json.decode(localStorage.getString('user') ?? '{}');
                    var userId = user['id'];

                    String imagesString = uploadedImagePaths.join(',');

                    final Map<String, dynamic> queryParams = {
                      "step": 1,
                      "propertyTitle": _titleController.text,
                      "town": _userRegion,
                      "subRegion": _userTown,
                      "latitude": _lat,
                      "longitude": _lon,
                      "country": "KENYA",
                      "countryCode": "KE",
                      "address": _userAddress ?? "",
                      "user_id": userId.toString(),
                      "images": imagesString,
                      "removedImages": _removedImages,
                      "propertyID": widget.propertyID.toString()
                    };

                    var res = await CallApi()
                        .postData(queryParams, 'property/edit-property');
                    var body = json.decode(res.body);

                    print("DATA SUBMITTED: " + body.toString());

                    if (res.statusCode == 200) {
                      var body = json.decode(res.body);

                      if (body['success']) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostStep2Page(
                              propertyID: widget.propertyID.toString(),
                            ),
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(_initDataFetched ? "Continue" : "Loading Please Wait"),
          ),
        ],
      ),
    );
  }

  Widget _removedImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start, // Aligns images from the left
          spacing: 6,
          runSpacing: 6,
          children: propertyImageList.map((imagePath) {
            return Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage("$_webUrlFuture/$imagePath"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Add to removed images list
                        _removedImages.add(imagePath);
                        // Remove from displayed images
                        List<String> updatedList = List.from(propertyImageList);
                        updatedList.remove(imagePath);
                        property_images = updatedList.join(', ');
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
