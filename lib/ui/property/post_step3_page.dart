// import 'dart:convert';
// import 'dart:io';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:just_apartment_live/api/api.dart';
// import 'package:just_apartment_live/models/configuration.dart';
// import 'package:just_apartment_live/ui/loading.dart';
// import 'package:just_apartment_live/ui/property/details_page.dart';
// import 'package:just_apartment_live/widgets/header_main_widget.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

// class PostStep3Page extends StatefulWidget {
//   final propertyID;
//   const PostStep3Page({super.key, required this.propertyID});

//   @override
//   _PostStep3PageState createState() => _PostStep3PageState();
// }

// class _PostStep3PageState extends State<PostStep3Page> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//   final _youtubeLinkController = TextEditingController();

//   List<Map<String, dynamic>> _isChecked = [];
//   List _propertFeaturesList = [];

//   var data = [
//     {"id": 1, "value": "Owner"},
//     {"id": 2, "value": "Agent"},
//     {"id": 3, "value": "Company"}
//   ];

//   List _listings = ["Owner", "Agent", "Company"];
//   var _propertyDetails;
//   bool _initDataFetched = false;
//   var _selectedListing;
//   final _companyController = TextEditingController();
//   bool _isUploading = false;
//   bool _companyLogoChanged = false;

//   String? _companyLogo;

//   File? _logoImage;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _logoImage = File(pickedFile.path);
//       });
//       _uploadLogo(); // Automatically upload after selection
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _getInitData();
//   }

//   _getInitData() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     SharedPreferences localStorage = await SharedPreferences.getInstance();
//     var user = json.decode(localStorage.getString('user') ?? '{}');

//     var data = {
//       'user_id': user['id'],
//       'propertyID': widget.propertyID,
//     };

//     var res = await CallApi().postData(data, 'property/get-init-data-part-one');

//     if (res.statusCode == 200) {
//       var body = json.decode(res.body);

//       if (body['success']) {
//         setState(() {
//           _propertFeaturesList = body['data']['propertyFeaturesList'];
//           _propertyDetails = body['data']['propertyDetails'];
//           // _listings = List<Map<String, dynamic>>.from(body['data']['listings']);
//           _companyLogo = _propertyDetails['company_logo'] ??
//               body['data']['userDetails']['company_logo'] ??
//               '';
//           _companyController.text = _propertyDetails['company_name'] ??
//               body['data']['userDetails']['company_name'] ??
//               '';
//           _isChecked = _propertFeaturesList.map((fdData) {
//             return {
//               'id': fdData['id'],
//               'checked': false,
//             };
//           }).toList();
//           _initDataFetched = true;
//         });
//       }
//     }

//     Navigator.pop(context); // Close the progress dialog
//   }

//   _submitProperty(context) async {
//     _formKey.currentState!.save();

//     if (_selectedListing == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select Listing By.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } else {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       );

//       SharedPreferences localStorage = await SharedPreferences.getInstance();
//       var user = json.decode(localStorage.getString('user') ?? '{}');

//       var data = {
//         'step': '3',
//         'propertyID': widget.propertyID,
//         'userID': user['id'].toString(),
//         'youtubeLink': _youtubeLinkController.text,
//         'selectedListing': _selectedListing,
//         'selectedFeatures':
//             _isChecked.where((item) => item['checked']).toList(),
//         'companyLogoChanged': _companyLogoChanged,
//         'companyName': _companyController.text,
//         'listingAs': _selectedListing,
//       };

//       var res = await CallApi().postData(data, 'property/post');

//       Navigator.pop(context); // Close the progress dialog

//       if (res.statusCode == 200) {
//         var body = json.decode(res.body);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailsPage(
//               propertyID: widget.propertyID.toString(),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to submit property.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: buildDrawer(context),
//       backgroundColor: Theme.of(context).brightness == Brightness.dark
//           ? Colors.black // Background color in dark mode
//           : Colors.grey.shade100, // Background color in light mode
//       appBar: buildHeader(context),
//       body: _bodyBuild(context),
//     );
//   }

//   Widget _bodyBuild(context) {
//     return Padding(
//       padding: const EdgeInsets.all(3.0),
//       child: Card(
//         elevation: 1.0,
//         child: _buildPostForm(context),
//       ),
//     );
//   }

//   Widget _buildPostForm(context) {
//     return Padding(
//       padding: const EdgeInsets.all(5.0),
//       child: Form(
//         key: _formKey,
//         child: ListView(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10.0),
//               child: _buildTitle(context),
//             ),

//             DropdownSearch<Map<String, dynamic>>(
//               items: data, // Explicit cast
//               itemAsString: (Map<String, dynamic> item) => item['value'] ?? '',
//               onChanged: (Map<String, dynamic>? selectedItem) {
//                 setState(() {
//                   _selectedListing = selectedItem?['id'];
//                 });
//               },
//               dropdownBuilder: (context, selectedItem) => Text(
//                 selectedItem?['value'] ?? 'Select Listing',
//                 style: const TextStyle(fontSize: 14),
//               ),
//               dropdownDecoratorProps: const DropDownDecoratorProps(
//                 dropdownSearchDecoration: InputDecoration(
//                   labelText: 'Listing By:',
//                   hintText: 'Select Listing Type',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),

//             if (_selectedListing == 2 || _selectedListing == 3) ...[
//               Column(
//                 children: [
//                   _buildTextField(_companyController, 'Agency or Company Name',
//                       'Enter Agency or Company Name', false),
//                   _buildUploadCompanyLogo(),
//                 ],
//               )
//             ],
//             const Padding(
//               padding: EdgeInsets.only(top: 8.0),
//               child: Text(
//                 "Select Features",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),

//             if (_initDataFetched)
//               if (_propertyDetails['type_id'] != 7)
//                 Column(
//                   children: List.generate(_propertFeaturesList.length, (index) {
//                     return CheckboxListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 0.0), // Remove padding
//                       title: Text(
//                         _propertFeaturesList[index]['feature_name'],
//                         style: TextStyle(
//                             fontSize: 14.0,
//                             color: Theme.of(context).brightness ==
//                                     Brightness.dark
//                                 ? Colors.white
//                                 : Colors
//                                     .black), // Adjust text color based on theme
//                       ),
//                       controlAffinity: ListTileControlAffinity.leading,
//                       value: _isChecked[index]['checked'],
//                       onChanged: (value) {
//                         setState(() {
//                           _isChecked[index]['checked'] = value!;
//                         });
//                       },
//                       visualDensity: VisualDensity
//                           .compact, // Reduce density for tighter layout
//                     );
//                   }),
//                 ),
//             const SizedBox(height: 20), // Space between features and Dropdown

//             TextFormField(
//               controller: _youtubeLinkController,
//               decoration: InputDecoration(
//                 labelText: 'YouTube Link (optional)',
//                 hintText: 'Enter YouTube Link',
//                 labelStyle: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.dark
//                       ? Colors.white70 // Label text color in dark mode
//                       : Colors.black54, // Label text color in light mode
//                 ),
//                 hintStyle: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.dark
//                       ? Colors.white54 // Hint text color in dark mode
//                       : Colors.black38, // Hint text color in light mode
//                 ),
//                 filled: true,
//                 fillColor: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.grey[800] // Background color in dark mode
//                     : Colors.white, // Background color in light mode
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onSaved: (value) {
//                 _youtubeLinkController.text = value!;
//               },
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => _submitProperty(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple,
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: <Widget>[
//                   Text(
//                     'Submit',
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.white,
//                     ),
//                   ),
//                   Icon(
//                     Icons.arrow_forward,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTitle(context) {
//     return Column(
//       children: [
//         const Padding(
//           padding: EdgeInsets.only(top: 10),
//         ),
//         Text(
//           "Post A Property",
//           style: TextStyle(
//               fontSize: 20,
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? Colors.white
//                   : Colors.black),
//         ),
//         const Padding(
//           padding: EdgeInsets.only(top: 5),
//         ),
//         Text(
//           "Step 3 of 3",
//           style: TextStyle(
//               fontSize: 13,
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? Colors.white70
//                   : Colors.black54),
//         ),
//       ],
//     );
//   }

//   Widget _buildUploadCompanyLogo() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey, width: 1),
//         borderRadius: BorderRadius.circular(5),
//       ),
//       padding: const EdgeInsets.all(10),
//       width: double.infinity,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text("Upload the Company Logo"),
//           GestureDetector(
//             onTap: _pickImage,
//             child: Stack(
//               alignment: Alignment.topRight,
//               children: [
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.grey[300],
//                   child: _logoImage == null &&
//                           (_companyLogo == null || _companyLogo!.isEmpty)
//                       ? Icon(Icons.add_a_photo,
//                           size: 30, color: Colors.grey[700])
//                       : null,
//                 ),
//                 if (_logoImage != null ||
//                     (_companyLogo != null && _companyLogo!.isNotEmpty))
//                   Positioned(
//                     right: 0,
//                     top: 0,
//                     child: IconButton(
//                       icon: const Icon(Icons.close, color: Colors.red),
//                       onPressed: _removeImage,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (_isUploading) const CircularProgressIndicator(),
//         ],
//       ),
//     );
//   }

//   Future<void> _uploadLogo() async {
//     if (_logoImage == null) return;

//     setState(() {
//       _isUploading = true;
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     var propertyId = _propertyDetails['id'];

//     final uri = Uri.parse(
//         '${Configuration.API_URL}property/upload-property-company-logo');
//     final request = http.MultipartRequest('POST', uri)
//       ..fields['property_id'] = propertyId.toString()
//       ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();

//       Navigator.pop(context); // Close the progress dialog

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 "Logo uploaded successfully. Click on Submit once finished"),
//             duration: Duration(seconds: 3),
//             action: SnackBarAction(
//               label: 'X',
//               textColor: Colors.white,
//               onPressed: () {
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
//               },
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to upload logo: $responseBody")),
//         );
//       }
//     } catch (e) {
//       Navigator.pop(context); // Close the progress dialog
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("An error occurred: $e")),
//       );
//     } finally {
//       setState(() {
//         _isUploading = false;
//         _companyLogoChanged = true;
//       });
//     }
//   }

//   void _removeImage() {
//     setState(() {
//       _logoImage = null;
//       _companyLogo = '';
//     });
//   }

//   Widget _buildTextField(TextEditingController controller, String labelText,
//       String hintText, bool isRequired,
//       [TextInputType inputType = TextInputType.text]) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: inputType,
//         decoration: InputDecoration(
//           labelText: labelText,
//           hintText: hintText,
//           fillColor: Theme.of(context).colorScheme.surface,
//           filled: true,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//             borderSide: BorderSide(
//               color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
//             ),
//           ),
//         ),
//         style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
//         validator: (value) {
//           if (isRequired && (value == null || value.isEmpty)) {
//             return '$labelText is required';
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/payments/SubscriptionPage.dart';
import 'package:just_apartment_live/ui/property/details_page.dart';
import 'package:just_apartment_live/ui/property/subscription_page2.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PostStep3Page extends StatefulWidget {
  final propertyID;
  const PostStep3Page({super.key, required this.propertyID});

  @override
  _PostStep3PageState createState() => _PostStep3PageState();
}

class _PostStep3PageState extends State<PostStep3Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _youtubeLinkController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  List<Map<String, dynamic>> _isChecked = [];
  List _propertFeaturesList = [];
  List _listings = [];
  var _propertyDetails;
  bool _initDataFetched = false;
  var _selectedListing;
  final _companyController = TextEditingController();
  bool _isUploading = false;
  bool _companyLogoChanged = false;
  var data = [
    {"id": 1, "value": "Owner"},
    {"id": 2, "value": "Agent"},
    {"id": 3, "value": "Company"}
  ];

  String? _companyLogo;

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

  @override
  void initState() {
    super.initState();
    _fetchWebUrl();
    _getInitData();
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

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    _phoneNumberController.text = user['telephone'];

    var data = {
      'user_id': user['id'],
      'propertyID': widget.propertyID,
    };

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        setState(() {
          _propertFeaturesList = body['data']['propertyFeaturesList'];
          _propertyDetails = body['data']['propertyDetails'];

          _listings = List<Map<String, dynamic>>.from(body['data']['listings']);

          // _companyLogo = body['data']['userDetails']['company_logo'] ?? '';

          if (_propertyDetails['company_logo'] != null &&
              _propertyDetails['company_logo'].isNotEmpty) {
            _companyLogo = _propertyDetails['company_logo'];
          } else if (body['data']['userDetails']['company_logo'] != null &&
              body['data']['userDetails']['company_logo'].isNotEmpty) {
            _companyLogo = body['data']['userDetails']['company_logo'];
          } else {
            _companyLogo = ''; // Assign an empty string if both are empty
          }

          // _companyController.text =
          //     body['data']['userDetails']['company_name']?.toString() ?? '';

          if (_propertyDetails['company_name'] != null &&
              _propertyDetails['company_name'].isNotEmpty) {
            _companyController.text = _propertyDetails['company_name'];
          } else if (body['data']['userDetails']['company_name'] != null &&
              body['data']['userDetails']['company_name'].isNotEmpty) {
            _companyController.text =
                body['data']['userDetails']['company_name'];
          } else {
            _companyController.text =
                ''; // Assign an empty string if both are empty
          }

          _isChecked = _propertFeaturesList.map((fdData) {
            return {
              'id': fdData['id'],
              'checked': false,
            };
          }).toList();

          _initDataFetched = true;
        });
      }
    }
  }

  _submitProperty(context) async {
    _formKey.currentState!.save();

    if (_phoneNumberController.text.isNotEmpty) {
      _updatePhoneNumber(_phoneNumberController.text);

      if (_selectedListing == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Listing By.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if ((_selectedListing == 2 || _selectedListing == 3) &&
            _companyController.text == '') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter The Company Name.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          Loading().loader(context, "Submitting...Please wait");

          SharedPreferences localStorage =
              await SharedPreferences.getInstance();
          var user = json.decode(localStorage.getString('user') ?? '{}');

          var data = {
            'step': '3',
            'propertyID': widget.propertyID,
            'userID': user['id'].toString(),
            'youtubeLink': _youtubeLinkController.text,
            'selectedListing': _selectedListing,
            'selectedFeatures':
                _isChecked.where((item) => item['checked']).toList(),
            'companyLogoChanged': _companyLogoChanged,
            'companyName': _companyController.text,
            'listingAs': _selectedListing,
          };

          var res = await CallApi().postData(data, 'property/post');

          if (res.statusCode == 200) {
            var body = json.decode(res.body);
            Navigator.pop(context);
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => DetailsPage(
            //       propertyID: widget.propertyID.toString(),
            //     ),
            //   ),
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => SubscriptionPage(
            //       userId: user['id'],
            //       propertyID: int.parse(widget.propertyID.toString()),
            //       data: data,
            //     ),
            //   ),
            // );

            if (_propertyDetails['prop_subscription_id'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsPage(
                    propertyID: int.parse(widget.propertyID.toString()),
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionPage2(
                    propertyID: int.parse(widget.propertyID.toString()),
                  ),
                ),
              );
            }
          } else {
            Navigator.pop(context);
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: buildDrawer(context),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black // Background color in dark mode
          : Colors.grey.shade100, // Background color in light mode
      appBar: buildHeader(context),
      body: _bodyBuild(context),
    );
  }

  Widget _bodyBuild(context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Card(
        elevation: 1.0,
        child: _buildPostForm(context),
      ),
    );
  }

  Widget _buildPostForm(context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildTitle(context),
            ),

            DropdownSearch<Map<String, dynamic>>(
              items: data, // Explicit cast
              itemAsString: (Map<String, dynamic> item) => item['value'] ?? '',
              onChanged: (Map<String, dynamic>? selectedItem) {
                setState(() {
                  _selectedListing = selectedItem?['id'];
                });
              },
              dropdownBuilder: (context, selectedItem) => Text(
                selectedItem?['value'] ?? 'Select Listing',
                style: const TextStyle(fontSize: 14),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Listing By:',
                  hintText: 'Select Listing Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            if (_selectedListing == 2 || _selectedListing == 3) ...[
              Column(
                children: [
                  _buildTextField(_companyController, 'Agency or Company Name',
                      'Enter Agency or Company Name', false),
                  // _buildUploadCompanyLogo(),
                ],
              )
            ],
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Select Features",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (_initDataFetched)
              if (_propertyDetails['type_id'] != 7)
                GridView.builder(
                  shrinkWrap: true, // Ensure it takes only the necessary space
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling if inside a parent scroll view
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns in the grid
                    crossAxisSpacing:
                        5.0, // Horizontal space between grid items
                    mainAxisSpacing: 5.0, // Vertical space between grid items
                    childAspectRatio:
                        4, // Width to height ratio of the grid items
                  ),
                  itemCount: _propertFeaturesList.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 0.0),
                      title: Text(
                        _propertFeaturesList[index]['feature_name'],
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _isChecked[index]['checked'],
                      onChanged: (value) {
                        setState(() {
                          _isChecked[index]['checked'] = value!;
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),

            const SizedBox(height: 20), // Space between features and Dropdown

            // Add the DropdownSearch widget for listing selection

            const SizedBox(
                height: 20), // Space between DropdownSearch and TextFormField

            TextFormField(
              controller: _youtubeLinkController,
              decoration: InputDecoration(
                labelText: 'YouTube Link (optional)',
                hintText: 'Enter YouTube Link',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70 // Label text color in dark mode
                      : Colors.black54, // Label text color in light mode
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54 // Hint text color in dark mode
                      : Colors.black38, // Hint text color in light mode
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800] // Background color in dark mode
                    : Colors.white, // Background color in light mode
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSaved: (value) {
                _youtubeLinkController.text = value!;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller:
                  _phoneNumberController, // Add a controller for the phone number
              decoration: InputDecoration(
                labelText: 'Preferred Phone Number',
                hintText: 'Enter your preferred phone number',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70 // Label text color in dark mode
                      : Colors.black54, // Label text color in light mode
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54 // Hint text color in dark mode
                      : Colors.black38, // Hint text color in light mode
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800] // Background color in dark mode
                    : Colors.white, // Background color in light mode
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType:
                  TextInputType.phone, // Set the keyboard type to phone
              onSaved: (value) {
                _phoneNumberController.text = value!;
              },
            ),
            // Space between TextFormField and ElevatedButton
            ElevatedButton(
              onPressed: () => _submitProperty(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePhoneNumber(String phoneNumber) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    var userId = user['id'];

    var webLink = hasGotApiLink ? _webUrlFuture : '';

    final uri = Uri.parse(
        '${webLink}api/user/update-telephone?telephone=$phoneNumber&user_id=$userId');

    logger.e(uri.toString());

    try {
      var response = await http.post(uri);

      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        if (body['success']) {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => SubscriptionPage(
          //       userId: user['id'],

          //       propertyID: int.parse(widget.propertyID.toString()),
          //     ),
          //   ),
          // );
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Success!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to update phone number: ${body['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to update phone number: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTitle(context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10),
        ),
        Text(
          "Post A Property",
          style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 5),
        ),
        Text(
          "Step 3 of 3",
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54),
        ),
      ],
    );
  }

  Widget _buildUploadCompanyLogo() {
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey, width: 1), // Border color and width
        borderRadius: BorderRadius.circular(5), // Border radius
      ),
      padding: const EdgeInsets.all(10), // Padding inside the container
      width: double.infinity, // Make the container full width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Upload the Company Logo"),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  // backgroundImage: _logoImage != null
                  //     ? FileImage(_logoImage!) // Display selected image
                  //     : (_companyLogo != null && _companyLogo!.isNotEmpty
                  //         ? NetworkImage(Configuration.WEB_URL +
                  //             _companyLogo!) // Display logo from network if exists
                  //         : null),
                  child: _logoImage == null &&
                          (_companyLogo == null || _companyLogo!.isEmpty)
                      ? Icon(Icons.add_a_photo,
                          size: 30, color: Colors.grey[700])
                      : null,
                ),
                if (_logoImage != null ||
                    (_companyLogo != null && _companyLogo!.isNotEmpty))
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
    );
  }

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;

    setState(() {
      _isUploading = true;
    });

    var propertyId = _propertyDetails['id'];

    // Replace with your server's upload endpoint
    // final uri = Uri.parse(
    //     '${Configuration.API_URL}property/upload-property-company-logo');
    // final request = http.MultipartRequest('POST', uri)
    //   ..fields['property_id'] =
    //       propertyId.toString() // Add user ID to request fields
    //   ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    final links = await Configuration().getCountryApiLink();
    final apiUrl = links['api']!;
    final uri = Uri.parse('${apiUrl}property/upload-property-company-logo');

    final request = http.MultipartRequest('POST', uri)
      ..fields['property_id'] =
          propertyId.toString() // Add property ID to request fields
      ..files.add(await http.MultipartFile.fromPath('logo', _logoImage!.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Logo uploaded successfully. Click on Submit once finished",
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
        _companyLogoChanged = true;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _logoImage = null; // Clear locally selected image
      _companyLogo = ''; // Clear existing uploaded image URL from network
    });
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      String hintText, bool isRequired,
      [TextInputType inputType = TextInputType.text]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          fillColor: Theme.of(context)
              .colorScheme
              .surface, // Background color based on theme
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[300]!, // Border color based on theme
            ),
          ),
        ),
        style: TextStyle(
            color: isDarkMode
                ? Colors.white
                : Colors.black), // Text color based on theme
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
