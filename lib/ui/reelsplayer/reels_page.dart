// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:just_apartment_live/models/configuration.dart';
// import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
// import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
// import 'package:just_apartment_live/ui/reelsplayer/comment_popup.dart';
// import 'package:just_apartment_live/ui/reelsplayer/video.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:logger/logger.dart';
//
// import '../login/login.dart';
// import '../reels/comment.dart';
//
// final logger = Logger();
//
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:image_picker/image_picker.dart';
// // import 'package:just_apartment_live/models/configuration.dart';
// // import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
// // import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
// // import 'package:just_apartment_live/ui/reelsplayer/video.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import 'package:logger/logger.dart';
// // import '../login/login.dart';
//
// // final logger = Logger();
//
// class ReelsPage extends StatefulWidget {
//   const ReelsPage({super.key});
//
//   @override
//   _ReelsPageState createState() => _ReelsPageState();
// }
//
// class _ReelsPageState extends State<ReelsPage> {
//   final PageController _pageController = PageController();
//   final ImagePicker _picker = ImagePicker();
//   int _currentPageIndex = 0;
//   List<Video> videos = [];
//   bool _hasLoggedIn = false;
//   int _userID = 0;
//   String username = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _checkCachedVideos();
//     _fetchVideos();
//     _loadUser();
//   }
//
//   Future<void> _loadUser() async {
//     SharedPreferences localStorage = await SharedPreferences.getInstance();
//     var user = json.decode(localStorage.getString('user') ?? '{}');
//     if (user.isNotEmpty) {
//       setState(() {
//         _hasLoggedIn = true;
//         _userID = user['id'];
//         username = user['name'];
//       });
//     }
//   }
//
//   Future<void> _checkCachedVideos() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     bool isConnected = connectivityResult != ConnectivityResult.none;
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? cachedVideos = prefs.getString('cachedVideos');
//
//     setState(() {
//       videos = (json.decode(cachedVideos!) as List)
//           .map((videoData) => Video.fromJson(videoData))
//           .toList();
//     });
//     logger.i("Loaded cached videos, count: ${videos.length}");
//
//     if (isConnected) {
//       await _fetchVideos();
//     } else if (cachedVideos == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No internet connection")),
//       );
//     }
//   }
//
//   Future<void> _fetchVideos() async {
//     try {
//       final postData = {'key': 'value'};
//       final response = await http.post(
//         Uri.parse('${Configuration.API_URL}reels/get-videos'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(postData),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success']) {
//           List<Video> newVideos = (data['data'] as List).map((video) {
//             return Video(
//               id: video['id'],
//               url: 'https://justhomes.co.ke/${video['video_path']}',
//               user: video['user']['name'],
//               caption: video['description'] ?? '',
//               likes: video['likes'],
//               shares: video['shares'],
//               comments: video['comments'],
//             );
//           }).toList();
//
//           setState(() {
//             videos = newVideos;
//           });
//
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           prefs.setString('cachedVideos',
//               json.encode(newVideos.map((video) => video.toJson()).toList()));
//           logger.i("Caching videos, count: ${newVideos.length}");
//         }
//       } else {
//         logger.e("Failed to fetch videos, status code: ${response.statusCode}");
//       }
//     } catch (e) {
//       logger.e("Error fetching videos: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 35.0),
//         child: FloatingActionButton(
//           onPressed: _showVideoOptions,
//           backgroundColor: Colors.purple,
//           child: const FaIcon(
//             FontAwesomeIcons.plus,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       body: PageView.builder(
//         controller: _pageController,
//         scrollDirection: Axis.vertical,
//         itemCount: videos.length,
//         onPageChanged: (index) {
//           setState(() {
//             _currentPageIndex = index;
//           });
//         },
//         itemBuilder: (context, index) {
//           final video = videos[index];
//           return CachedVlcPlayerWidget(
//             videoID: video.id,
//             username: username,
//             videoUrl: video.url,
//             user: video.user,
//             caption: video.caption,
//             likes: video.likes.toString(),
//             shares: video.shares.toString(),
//             comments: video.comments,
//           );
//         },
//       ),
//     );
//   }
//
//   void _showVideoOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           height: 150,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ListTile(
//                   leading:
//                       const Icon(Icons.fiber_manual_record, color: Colors.red),
//                   title: const Text('Live'),
//                   onTap: () {
//                     // Navigator.of(context).pop();
//                     //
//                     _hasLoggedIn
//                         ? {Navigator.of(context).pop(), _recordVideo()}
//                         : showDialog(
//                             context: context,
//                             builder: (context) {
//                               return AlertDialog(
//                                 title: const Text(
//                                   'Please log in or create an account first',
//                                   style: TextStyle(fontSize: 15),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               const LoginPage(),
//                                         ),
//                                       );
//                                     },
//                                     child: const Text('Log in'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.video_library),
//                   title: const Text('Add Video'),
//                   onTap: () {
//                     _hasLoggedIn
//                         ? {Navigator.of(context).pop(), _pickVideoFromGallery()}
//                         : showDialog(
//                             context: context,
//                             builder: (context) {
//                               return AlertDialog(
//                                 title: const Text(
//                                   'Please log in or create an account first',
//                                   style: TextStyle(fontSize: 15),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               const LoginPage(),
//                                         ),
//                                       );
//                                     },
//                                     child: const Text('Log in'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _pickVideoFromGallery() async {
//     final XFile? videoFile =
//         await _picker.pickVideo(source: ImageSource.gallery);
//
//     if (videoFile != null) {
//       final file = File(videoFile.path);
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => TrimmerView(file),
//         ),
//       );
//     }
//   }
//
//   Future<void> _recordVideo() async {
//     final XFile? videoFile = await _picker.pickVideo(
//       source: ImageSource.camera,
//       maxDuration: const Duration(minutes: 5),
//     );
//
//     if (videoFile != null) {
//       final file = File(videoFile.path);
//       logger.i("videoFile.path: ${videoFile.path}");
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => TrimmerView(
//             file,
//             isLiveVideo: true,
//           ),
//         ),
//       );
//     }
//   }
//
//   Future<void> _showLoginPrompt() async {
//     return showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Please log in or create an account first',
//               style: TextStyle(fontSize: 15)),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => const LoginPage()));
//               },
//               child: const Text('Log in'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class CachedVlcPlayerWidget extends StatefulWidget {
//   final int videoID;
//   final String videoUrl;
//   final String user;
//   final String caption;
//   final String likes;
//   final String shares;
//   final String username;
//   final List comments;
//
//   const CachedVlcPlayerWidget({
//     super.key,
//     required this.videoID,
//     required this.videoUrl,
//     required this.user,
//     required this.caption,
//     required this.likes,
//     required this.shares,
//     required this.username,
//     required this.comments,
//   });
//
//   @override
//   _CachedVlcPlayerWidgetState createState() => _CachedVlcPlayerWidgetState();
// }
//
// class _CachedVlcPlayerWidgetState extends State<CachedVlcPlayerWidget> {
//   late VlcPlayerController _vlcPlayerController;
//   bool _isMuted = false;
//   bool _isPlaying = true;
//   File? _cachedFile;
//   bool _isLiked = false;
//   late int _likesCount;
//   late int _shareCount;
//   bool _hasLoggedIn = false;
//   int? _userID = 0;
//   String userName = '';
//   late Timer _likeCountTimer;
//   final ValueNotifier<int> _likesCountNotifier = ValueNotifier<int>(0);
//   final ValueNotifier<int> _shareCountNotifier = ValueNotifier<int>(0);
//   late Future<Map<String, dynamic>> _likeStatusFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _likesCount = int.parse(widget.likes);
//     _shareCount = int.parse(widget.shares);
//     _loadUser();
//     _loadVideo();
//     _loadLikeStatus();
//     _likeStatusFuture = _fetchLikeStatus(false);
//   }
//
//   Future<void> _loadUser() async {
//     SharedPreferences localStorage = await SharedPreferences.getInstance();
//     var user = json.decode(localStorage.getString('user') ?? '{}');
//     print('User Details: $user');
//     print('User id: ${user['id']}');
//
//     if (user.isEmpty) {
//       setState(() {
//         _hasLoggedIn = false;
//         _userID = user['id'];
//         userName = '';
//       });
//     } else {
//       setState(() {
//         _hasLoggedIn = true;
//         _userID = user['id'];
//         userName = user['name'];
//       });
//     }
//   }
//
//   Future<void> _shareVideo() async {
//     // Local state update
//     setState(() {
//       _shareCount++;
//     });
//
//     // Update the ValueNotifier for share count
//     _shareCountNotifier.value = _shareCount;
//     // API call to update share count on the server
//     final Uri shareUri = Uri.parse(
//         'https://justhomes.co.ke/api/reels/update-shares?shares=$_shareCount&videoId=${widget.videoID}&user_id=$_userID');
//
//     try {
//       final response = await http.post(shareUri);
//       if (response.statusCode != 200) {
//         print("Failed to update share status: ${response.reasonPhrase}");
//         // If the API fails, revert the UI change
//         setState(() {
//           _shareCount--;
//         });
//         _shareCountNotifier.value = _shareCount;
//       }
//     } catch (e) {
//       print("Error updating share status: $e");
//       // If the API fails, revert the UI change
//       setState(() {
//         _shareCount--;
//       });
//       _shareCountNotifier.value = _shareCount;
//     }
//   }
//
//   Future<void> _loadVideo() async {
//     final cachedFile =
//         await DefaultCacheManager().getSingleFile(widget.videoUrl);
//     _cachedFile = cachedFile;
//     _vlcPlayerController = VlcPlayerController.file(
//       _cachedFile!,
//       hwAcc: HwAcc.full,
//       autoPlay: true,
//       options: VlcPlayerOptions(),
//     );
//
//     _vlcPlayerController.addListener(_onPlayerStateChange);
//   }
//
//   void _onPlayerStateChange() {
//     if (_vlcPlayerController.value.isEnded) {
//       setState(() {
//         _isPlaying = false;
//       });
//     } else {
//       setState(() {
//         _isPlaying = true;
//       });
//     }
//   }
//
//   Future<void> _loadLikeStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _isLiked = prefs.getBool('isLiked_${widget.videoID}') ?? false;
//     setState(() {});
//   }
//
//   void _toggleMute() {
//     setState(() {
//       _isMuted = !_isMuted;
//       _vlcPlayerController.setVolume(_isMuted ? 0 : 100);
//     });
//   }
//
//   @override
//   void dispose() {
//     _vlcPlayerController.removeListener(_onPlayerStateChange);
//     _vlcPlayerController.dispose();
//     _likesCountNotifier.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: GestureDetector(
//             onTap: () {},
//             child: _cachedFile == null
//                 ? const Center(child: CircularProgressIndicator())
//                 : VlcPlayer(
//                     controller: _vlcPlayerController,
//                     aspectRatio: MediaQuery.of(context).size.aspectRatio,
//                     placeholder:
//                         const Center(child: CircularProgressIndicator()),
//                   ),
//           ),
//         ),
//         if (!_isPlaying)
//           const Center(
//             child: Icon(
//               Icons.play_arrow,
//               color: Colors.white,
//               size: 80,
//             ),
//           ),
//         _buildInteractiveLayer(),
//       ],
//     );
//   }
//
//   Future<void> _showLoginPrompt() async {
//     return showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Please log in or create an account first',
//               style: TextStyle(fontSize: 15)),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => const LoginPage()));
//               },
//               child: const Text('Log in'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<Map<String, dynamic>> _fetchLikeStatus(bool hasLiked) async {
//     try {
//       final response = await http.post(Uri.parse(
//           'https://justhomes.co.ke/api/reels/get-likes-status?videoId=${widget.videoID}'));
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         return {
//           'isLiked': hasLiked,
//           'likes': responseData['likes']
//         }; // Default fallback
// // Assume it returns {"isLiked": bool, "likesCount": int}
//       } else {
//         throw Exception('Failed to load like status');
//       }
//     } catch (e) {
//       logger.e("Failed to fetch like status:"
//           '   --->https://justhomes.co.ke/api/reels/like-status?videoId=${widget.videoID}');
//       return {'isLiked': false, 'likes': 0}; // Default fallback
//     }
//   }
//
//   Future<void> _toggleLike(bool currentLikeStatus, int likesCount) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       if (_userID == null) {
//         _showLoginPrompt();
//       } else {
//         String videoKey = 'liked_${widget.videoID}'; // Unique key for the video
//         bool hasLiked = prefs.getBool(videoKey) ?? false; // Default to false
//
//         if (!hasLiked) {
//           // Save new like status and increment likes
//           await _saveLikeStatus(widget.videoID, true);
//           likesCount++;
//         } else {
//           // Remove like status and decrement likes
//           await _saveLikeStatus(widget.videoID, false);
//           likesCount--;
//         }
//
//         // Call the API to update the server
//         final response = await http.post(
//           Uri.parse(
//               'https://justhomes.co.ke/api/reels/update-likes?likes=$likesCount&videoId=${widget.videoID}&user_id=$_userID'),
//         );
//
//         if (response.statusCode == 200) {
//           logger.i(response.body);
//
//           setState(() {
//             _likeStatusFuture = _fetchLikeStatus(hasLiked);
//           });
//         } else {
//           logger.e("Failed to update like status on server.");
//         }
//       }
//     } catch (e) {
//       logger.e("Error toggling like status: $e");
//     }
//   }
//
//   Future<void> _saveLikeStatus(int videoID, bool isLiked) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String videoKey = 'liked_$videoID'; // Create a unique key for the video
//       await prefs.setBool(videoKey, isLiked); // Save the like status
//       logger.i("Saved like status: Video $videoID isLiked: $isLiked");
//     } catch (e) {
//       logger.e("Error saving like status: $e");
//     }
//   }
//
//   Future<bool> _getLikeStatus(String videoID) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String videoKey = 'liked_$videoID'; // Unique key for the video
//       return prefs.getBool(videoKey) ?? false; // Default to false if not found
//     } catch (e) {
//       logger.e("Error retrieving like status: $e");
//       return false;
//     }
//   }
//
//   Widget _buildInteractiveLayer() {
//     return Positioned(
//       bottom: 55,
//       right: 20,
//       child: Column(
//         children: [
//           // Like Button and Likes Count
//           FutureBuilder<Map<String, dynamic>>(
//             future: _likeStatusFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const CircularProgressIndicator(); // Loading state
//               } else if (snapshot.hasError) {
//                 // Handle error gracefully
//                 return Container();
//               } else if (snapshot.hasData) {
//                 final data = snapshot.data!;
//                 final isLiked = data['isLiked'] as bool? ?? false;
//                 final likesCount = data['likes'] as int? ?? 0;
//
//                 return Column(
//                   children: [
//                     IconButton(
//                       icon: FaIcon(
//                         isLiked
//                             ? FontAwesomeIcons.solidHeart
//                             : FontAwesomeIcons.heart,
//                         color: isLiked ? Colors.red : Colors.white,
//                       ),
//                       onPressed: () => _toggleLike(
//                           isLiked, isLiked ? likesCount + 1 : likesCount - 1),
//                     ),
//                     Text(
//                       'Likes: $likesCount',
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ],
//                 );
//               }
//               return const SizedBox(); // Fallback
//             },
//           ),
//
//           // Share Button and Share Count
//           ValueListenableBuilder<int>(
//             valueListenable: _shareCountNotifier,
//             builder: (context, value, child) {
//               return Column(
//                 children: [
//                   IconButton(
//                     icon: const FaIcon(FontAwesomeIcons.share,
//                         color: Colors.white),
//                     onPressed: _shareVideo,
//                   ),
//                   Text(
//                     'Shares: $value',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ],
//               );
//             },
//           ),
//
//           // Comment Button
//           IconButton(
//             icon: const Icon(Icons.comment, color: Colors.white),
//             onPressed: () {
//               if (widget.username.isEmpty) {
//                 _showLoginPrompt();
//               } else {
//                 showDialog(
//                   context: context,
//                   builder: (context) {
//                     return CommentPopup(
//                       comments: widget.comments,
//                       onCommentAdded: (String comment) {
//                         print("New Comment: $comment");
//                       },
//                       videoID: widget.videoID.toString(),
//                     );
//                   },
//                 );
//               }
//             },
//           ),
//
//           // Mute/Unmute Button
//           IconButton(
//             icon: Icon(
//               _isMuted ? Icons.volume_off : Icons.volume_up,
//               color: Colors.white,
//             ),
//             onPressed: _toggleMute,
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/comment_popup.dart';
import 'package:just_apartment_live/ui/reelsplayer/video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../login/login.dart';
import '../reels/comment.dart';

final logger = Logger();

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:just_apartment_live/models/configuration.dart';
// import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
// import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
// import 'package:just_apartment_live/ui/reelsplayer/video.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:logger/logger.dart';
// import '../login/login.dart';

// final logger = Logger();

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  int _currentPageIndex = 0;
  List<Video> videos = [];
  bool _hasLoggedIn = false;
  int _userID = 0;
  String username = '';

  @override
  void initState() {
    super.initState();
    _checkCachedVideos();
    _fetchVideos();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    if (user.isNotEmpty) {
      setState(() {
        _hasLoggedIn = true;
        _userID = user['id'];
        username = user['name'];
      });
    }
  }

  Future<void> _checkCachedVideos() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedVideos = prefs.getString('cachedVideos');

    setState(() {
      videos = (json.decode(cachedVideos!) as List)
          .map((videoData) => Video.fromJson(videoData))
          .toList();
    });
    logger.i("Loaded cached videos, count: ${videos.length}");

    if (isConnected) {
      await _fetchVideos();
    } else if (cachedVideos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No internet connection")),
      );
    }
  }

  Future<void> _fetchVideos() async {
    try {
      // final postData = {'key': 'value'};
      // final response = await http.post(
      //   Uri.parse('${Configuration.API_URL}reels/get-videos'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode(postData),
      // );

      final links = await Configuration().getCountryApiLink();
      final postData = {'key': 'value'};

      final response = await http.post(
        Uri.parse('${links['api']}reels/get-videos'), // Use dynamic API URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Video> newVideos = (data['data'] as List).map((video) {
            return Video(
              id: video['id'],
              url: 'https://justhomes.co.ke/${video['video_path']}',
              user: video['user']['name'],
              caption: video['description'] ?? '',
              likes: video['likes'],
              shares: video['shares'],
              comments: video['comments'],
            );
          }).toList();

          setState(() {
            videos = newVideos;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('cachedVideos',
              json.encode(newVideos.map((video) => video.toJson()).toList()));
          logger.i("Caching videos, count: ${newVideos.length}");
        }
      } else {
        logger.e("Failed to fetch videos, status code: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Error fetching videos: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final video = videos[index];
          return CachedVlcPlayerWidget(
            videoID: video.id,
            username: username,
            videoUrl: video.url,
            user: video.user,
            caption: video.caption,
            likes: video.likes.toString(),
            shares: video.shares.toString(),
            comments: video.comments,
          );
        },
      ),
    );
  }

  Future<void> _showLoginPrompt() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Please log in or create an account first',
              style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              child: const Text('Log in'),
            ),
          ],
        );
      },
    );
  }
}

class CachedVlcPlayerWidget extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final String likes;
  final String shares;
  final String username;
  final List comments;

  const CachedVlcPlayerWidget({
    super.key,
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.username,
    required this.comments,
  });

  @override
  _CachedVlcPlayerWidgetState createState() => _CachedVlcPlayerWidgetState();
}

class _CachedVlcPlayerWidgetState extends State<CachedVlcPlayerWidget> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  File? _cachedFile;
  bool _isLiked = false;
  late int _likesCount;
  late int _shareCount;
  bool _hasLoggedIn = false;
  int? _userID = 0;
  String userName = '';
  late Timer _likeCountTimer;
  final ValueNotifier<int> _likesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _shareCountNotifier = ValueNotifier<int>(0);
  late Future<Map<String, dynamic>> _likeStatusFuture;

  @override
  void initState() {
    super.initState();
    _likesCount = int.parse(widget.likes);
    _shareCount = int.parse(widget.shares);
    _loadUser();
    _loadVideo();
    _loadLikeStatus();
    _likeStatusFuture = _fetchLikeStatus(false);
  }

  Future<void> _loadUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    print('User Details: $user');
    print('User id: ${user['id']}');

    if (user.isEmpty) {
      setState(() {
        _hasLoggedIn = false;
        _userID = user['id'];
        userName = '';
      });
    } else {
      setState(() {
        _hasLoggedIn = true;
        _userID = user['id'];
        userName = user['name'];
      });
    }
  }

  Future<void> _shareVideo() async {
    // Local state update
    setState(() {
      _shareCount++;
    });

    // Update the ValueNotifier for share count
    _shareCountNotifier.value = _shareCount;
    // API call to update share count on the server
    final Uri shareUri = Uri.parse(
        'https://justhomes.co.ke/api/reels/update-shares?shares=$_shareCount&videoId=${widget.videoID}&user_id=$_userID');

    try {
      final response = await http.post(shareUri);
      if (response.statusCode != 200) {
        print("Failed to update share status: ${response.reasonPhrase}");
        // If the API fails, revert the UI change
        setState(() {
          _shareCount--;
        });
        _shareCountNotifier.value = _shareCount;
      }
    } catch (e) {
      print("Error updating share status: $e");
      // If the API fails, revert the UI change
      setState(() {
        _shareCount--;
      });
      _shareCountNotifier.value = _shareCount;
    }
  }

  Future<void> _loadVideo() async {
    final cachedFile =
        await DefaultCacheManager().getSingleFile(widget.videoUrl);
    _cachedFile = cachedFile;
    _vlcPlayerController = VlcPlayerController.file(
      _cachedFile!,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcPlayerController.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_vlcPlayerController.value.isEnded) {
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _loadLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLiked = prefs.getBool('isLiked_${widget.videoID}') ?? false;
    setState(() {});
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _vlcPlayerController.setVolume(_isMuted ? 0 : 100);
    });
  }

  @override
  void dispose() {
    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _vlcPlayerController.dispose();
    _likesCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: _cachedFile == null
                ? const Center(child: CircularProgressIndicator())
                : VlcPlayer(
                    controller: _vlcPlayerController,
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    placeholder:
                        const Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
        if (!_isPlaying)
          const Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 80,
            ),
          ),
        _buildInteractiveLayer(),
      ],
    );
  }

  Future<void> _showLoginPrompt() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Please log in or create an account first',
              style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              child: const Text('Log in'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchLikeStatus(bool hasLiked) async {
    try {
      final response = await http.post(Uri.parse(
          'https://justhomes.co.ke/api/reels/get-likes-status?videoId=${widget.videoID}'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        return {
          'isLiked': hasLiked,
          'likes': responseData['likes']
        }; // Default fallback
// Assume it returns {"isLiked": bool, "likesCount": int}
      } else {
        throw Exception('Failed to load like status');
      }
    } catch (e) {
      logger.e("Failed to fetch like status:"
          '   --->https://justhomes.co.ke/api/reels/like-status?videoId=${widget.videoID}');
      return {'isLiked': false, 'likes': 0}; // Default fallback
    }
  }

  Future<void> _toggleLike(bool currentLikeStatus, int likesCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_userID == null) {
        _showLoginPrompt();
      } else {
        String videoKey = 'liked_${widget.videoID}'; // Unique key for the video
        bool hasLiked = prefs.getBool(videoKey) ?? false; // Default to false

        if (!hasLiked) {
          // Save new like status and increment likes
          await _saveLikeStatus(widget.videoID, true);
          likesCount++;
        } else {
          // Remove like status and decrement likes
          await _saveLikeStatus(widget.videoID, false);
          likesCount--;
        }

        // Call the API to update the server
        final response = await http.post(
          Uri.parse(
              'https://justhomes.co.ke/api/reels/update-likes?likes=$likesCount&videoId=${widget.videoID}&user_id=$_userID'),
        );

        if (response.statusCode == 200) {
          logger.i(response.body);

          setState(() {
            _likeStatusFuture = _fetchLikeStatus(hasLiked);
          });
        } else {
          logger.e("Failed to update like status on server.");
        }
      }
    } catch (e) {
      logger.e("Error toggling like status: $e");
    }
  }

  Future<void> _saveLikeStatus(int videoID, bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String videoKey = 'liked_$videoID'; // Create a unique key for the video
      await prefs.setBool(videoKey, isLiked); // Save the like status
      logger.i("Saved like status: Video $videoID isLiked: $isLiked");
    } catch (e) {
      logger.e("Error saving like status: $e");
    }
  }

  Future<bool> _getLikeStatus(String videoID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String videoKey = 'liked_$videoID'; // Unique key for the video
      return prefs.getBool(videoKey) ?? false; // Default to false if not found
    } catch (e) {
      logger.e("Error retrieving like status: $e");
      return false;
    }
  }

  Widget _buildInteractiveLayer() {
    return Positioned(
      bottom: 55,
      right: 20,
      child: Column(
        children: [
          // Like Button and Likes Count
          FutureBuilder<Map<String, dynamic>>(
            future: _likeStatusFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Loading state
              } else if (snapshot.hasError) {
                // Handle error gracefully
                return Container();
              } else if (snapshot.hasData) {
                final data = snapshot.data!;
                final isLiked = data['isLiked'] as bool? ?? false;
                final likesCount = data['likes'] as int? ?? 0;

                return Column(
                  children: [
                    IconButton(
                      icon: FaIcon(
                        isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: isLiked ? Colors.red : Colors.white,
                      ),
                      onPressed: () => _toggleLike(
                          isLiked, isLiked ? likesCount + 1 : likesCount - 1),
                    ),
                    Text(
                      'Likes: $likesCount',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              }
              return const SizedBox(); // Fallback
            },
          ),

          // Share Button and Share Count
          ValueListenableBuilder<int>(
            valueListenable: _shareCountNotifier,
            builder: (context, value, child) {
              return Column(
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.share,
                        color: Colors.white),
                    onPressed: _shareVideo,
                  ),
                  Text(
                    'Shares: $value',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),

          // Comment Button
          IconButton(
            icon: const Icon(Icons.comment, color: Colors.white),
            onPressed: () {
              if (widget.username.isEmpty) {
                _showLoginPrompt();
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CommentPopup(
                      comments: widget.comments,
                      onCommentAdded: (String comment) {
                        print("New Comment: $comment");
                      },
                      videoID: widget.videoID.toString(),
                    );
                  },
                );
              }
            },
          ),

          // Mute/Unmute Button
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
          ),
        ],
      ),
    );
  }
}
