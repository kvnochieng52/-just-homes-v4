// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';

// class NextButtonWidget extends StatelessWidget {
//   final GlobalKey<FormState> formKey;
//   final List<File> images;
//   final String userTown;
//   final String userRegion;
//   final TextEditingController titleController;
//   final PropertySubmissionService _propertySubmissionService;
//   final double latitude;
//   final double longitude;
//   final int userId;

//   const NextButtonWidget({
//     super.key,
//     required this.formKey,
//     required this.images,
//     required this.userTown,
//     required this.userRegion,
//     required this.titleController,
//     required this.latitude,
//     required this.longitude,
//     required this.userId,
//     required PropertySubmissionService propertySubmissionService,
//   }) : _propertySubmissionService = propertySubmissionService;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 30.0),
//       child: SizedBox(
//         width: double.infinity, // Full width of the parent
//         child: ElevatedButton(
//           onPressed: () {
//             formKey.currentState!.save();

//             _propertySubmissionService.submitProperty(
//               step: 1,
//               propertyTitle: titleController.text,
//               town: userRegion,
//               subRegion: userTown,
//               latitude: latitude,
//               longitude: longitude,
//               country: "Kenya",
//               countryCode: "KE",
//               address: userTown,
//               userId: userId,
//               images: images.map((e) => e.path).toList(),
//               context: context,

//             );
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.purple, // Purple background color
//             foregroundColor: Colors.white, // White font color
//             minimumSize:
//                 const Size(double.infinity, 50), // Set a minimum height
//           ),
//           child: const Text("Next"),
//         ),
//       ),
//     );
//   }
// }
