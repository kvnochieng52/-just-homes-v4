// import 'package:flutter/material.dart';
// import 'package:pusher_client/pusher_client.dart'; // Add Pusher dependency in pubspec.yaml
// import 'dart:convert';
//
// class RealTimeUpdatePage extends StatefulWidget {
//   @override
//   _RealTimeUpdatePageState createState() => _RealTimeUpdatePageState();
// }
//
// class _RealTimeUpdatePageState extends State<RealTimeUpdatePage> {
//   PusherClient? pusher;
//   Channel? channel;
//
//   String videoId = "53"; // Replace with dynamic ID if needed
//   int likes = 0;
//   int shares = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializePusher();
//   }
//
//   @override
//   void dispose() {
//     // Disconnect Pusher when the page is disposed
//     pusher?.disconnect();
//     super.dispose();
//   }
//
//   Future<void> _initializePusher() async {
//     try {
//       pusher = PusherClient(
//         "9ef9c52e95cd55fb6ea2", // Replace with your Pusher key
//         PusherOptions(cluster: "ap2"),
//       );
//
//       pusher!.connect();
//
//       // Subscribe to the item channel
//       channel = pusher!.subscribe('item.$videoId');
//       channel!.bind('like_or_share.updated', (PusherEvent? event) {
//         if (event?.data != null) {
//           final data = json.decode(event!.data!);
//           setState(() {
//             likes = data['likes'];
//             shares = data['shares'];
//           });
//         }
//       });
//     } catch (e) {
//       print("Error initializing Pusher: $e");
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text("Real-Time Updates"),
//         ),
//         body: Padding(
//         padding: const EdgeInsets.all(16.0),
//     child: Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     crossAxisAlignment: CrossAxisAlignment.center,
//     children: [
//       Text(
//         "Video ID: $videoId",
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//       SizedBox(height: 20),
//       Text(
//         "Likes: $likes",
//         style: TextStyle(fontSize: 16),
//       ),
//       Text(
//         "Shares: $shares",
//         style: TextStyle(fontSize: 16),
//       ),
//       SizedBox(height: 20),
//       ElevatedButton(
//         onPressed: () {
//           // Simulate a manual refresh or test action
//           setState(() {
//             likes += 1;
//             shares += 1;
//           });
//         },
//         child: Text("Simulate Update"),
//       ),
//     ],
//     ),
//         ),
//     );
//   }
// }
