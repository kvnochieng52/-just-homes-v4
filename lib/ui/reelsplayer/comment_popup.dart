// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:just_appartment_live/models/configuration.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// class CommentPopup extends StatefulWidget {
//   final List comments;
//   final Function(String) onCommentAdded;
//   final String videoID;
//
//   CommentPopup({
//     required this.comments,
//     required this.onCommentAdded,
//     required this.videoID,
//   });
//
//   @override
//   _CommentPopupState createState() => _CommentPopupState();
// }
//
// class _CommentPopupState extends State<CommentPopup> {
//   late TextEditingController _commentController;
//
//   @override
//   void initState() {
//     super.initState();
//     _commentController = TextEditingController();
//   }
//
//   @override
//   void dispose() {
//     _commentController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//
//     return Material(
//       type: MaterialType.transparency,
//       child: SizedBox(
//         width: mediaQuery.size.width * 0.50,
//         height: mediaQuery.size.height * 0.70, // Adjust height as needed
//         child: Container(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             top: 16,
//             bottom: mediaQuery.viewInsets.bottom + 16,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(
//               top: Radius.circular(15),
//             ),
//           ),
//           child: Column(
//             children: [
//               // Close button and comments list
//               Expanded(
//                 child: SingleChildScrollView(
//                   // Enable scrolling
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Close button
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Comments',
//                             style: TextStyle(
//                                 fontSize: 20, fontWeight: FontWeight.bold),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.close),
//                             onPressed: () {
//                               Navigator.pop(context); // Close the popup
//                             },
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//                       // Comments list
//                       ListView.builder(
//                         shrinkWrap: true, // Take up only required height
//                         physics:
//                             NeverScrollableScrollPhysics(), // Disable ListView scrolling
//                         itemCount: widget.comments.length,
//                         itemBuilder: (context, index) {
//                           return ListTile(
//                             leading:
//                                 _buildUserThumbnail(widget.comments[index]),
//                             title: Text(
//                               widget.comments[index]['user'] != null
//                                   ? widget.comments[index]['user']['name']
//                                       .toString()
//                                   : 'Anonymous',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(widget.comments[index]['comment']),
//                                 SizedBox(height: 4.0),
//                                 Text(
//                                   _formatDateTime(
//                                       widget.comments[index]['created_at']),
//                                   style: TextStyle(
//                                       color: Colors.grey[600], fontSize: 12),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Input field at the bottom
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _commentController,
//                       maxLines: 1, // Set to 1 line
//                       decoration: InputDecoration(
//                         hintText: 'Add a comment...',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.send),
//                     onPressed: _addComment,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUserThumbnail(comment) {
//     return CircleAvatar(
//       backgroundColor: _randomColor(),
//       child: Text(
//         comment['user'] != null && comment['user']['name'].isNotEmpty
//             ? comment['user']['name'][0].toUpperCase()
//             : '?',
//         style: TextStyle(color: Colors.white),
//       ),
//     );
//   }
//
//   Color _randomColor() {
//     Random random = Random();
//     return Color.fromARGB(
//       255,
//       random.nextInt(256),
//       random.nextInt(256),
//       random.nextInt(256),
//     );
//   }
//
//   String _formatDateTime(String dateTime) {
//     DateTime createdAt = DateTime.parse(dateTime);
//     return "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.day}/${createdAt.month}/${createdAt.year}";
//   }
//
//   Future<void> _addComment() async {
//     final newCommentText = _commentController.text;
//     if (newCommentText.isEmpty) return;
//
//     // Retrieve user info from shared preferences
//     SharedPreferences localStorage = await SharedPreferences.getInstance();
//     var user = json.decode(localStorage.getString('user') ?? '{}');
//
//     if (user == null || user.isEmpty) {
//       // Handle the case where user is not logged in or user data is unavailable
//       return;
//     }
//
//     // Create new comment object
//     final newComment = {
//       'user': {
//         'id': user['id'],
//         'name': user['name'],
//       },
//       'comment': newCommentText,
//       'created_at': DateTime.now().toIso8601String(),
//     };
//
//     // Add the new comment to the top of the list
//     setState(() {
//       widget.comments.insert(0, newComment);
//     });
//
//     // Clear the input field
//     _commentController.clear();
//
//     // Close the popup
//     //Navigator.pop(context);
//
//     // Send the comment to the server
//     await _postCommentToServer(newComment, widget.videoID);
//   }
//
//   Future<void> _postCommentToServer(
//       Map<String, dynamic> comment, String videoID) async {
//     final uri = Configuration.API_URL + 'reels/post-comment';
//
//     final response = await http.post(
//       Uri.parse(uri),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({
//         'videoID': videoID,
//         'userID': comment['user']['id'],
//         'comment': comment['comment'],
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       // Handle successful response
//       print('Comment posted successfully');
//     } else {
//       // Handle error response
//       print('Failed to post comment');
//     }
//   }
// }
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CommentPopup extends StatefulWidget {
  final List comments;
  final Function(String) onCommentAdded;
  final String videoID;

  const CommentPopup({
    super.key,
    required this.comments,
    required this.onCommentAdded,
    required this.videoID,
  });

  @override
  _CommentPopupState createState() => _CommentPopupState();
}

class _CommentPopupState extends State<CommentPopup> {
  late TextEditingController _commentController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String? _errorMessage; // For displaying error messages

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: mediaQuery.size.width * 0.90,
        height: mediaQuery.size.height * 0.70,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildCommentList(),
              ),
              if (_errorMessage != null) _buildErrorMessage(),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _buildCommentList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: widget.comments.length,
      itemBuilder: (context, index, animation) {
        return _buildCommentTile(widget.comments[index], animation);
      },
    );
  }

  Widget _buildCommentTile(comment, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        leading: _buildUserThumbnail(comment),
        title: Text(
          comment['user']?['name'] ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment['comment']),
            const SizedBox(height: 4.0),
            Text(
              _formatDateTime(comment['created_at']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserThumbnail(comment) {
    return CircleAvatar(
      backgroundColor: _randomColor(),
      child: Text(
        (comment['user']?['name']?.isNotEmpty ?? false)
            ? comment['user']['name'][0].toUpperCase()
            : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildInputField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _addComment,
          color: Colors.blue,
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    DateTime createdAt = DateTime.parse(dateTime);
    return "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.day}/${createdAt.month}/${createdAt.year}";
  }

  Color _randomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Future<void> _addComment() async {
    final newCommentText = _commentController.text.trim();
    if (newCommentText.isEmpty) return;

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user.isEmpty) {
      // Handle the case where user is not logged in or user data is unavailable
      return;
    }

    final newComment = {
      'user': {
        'id': user['id'],
        'name': user['name'],
      },
      'comment': newCommentText,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      widget.comments.insert(0, newComment);
      widget.onCommentAdded(newCommentText);
      _errorMessage = null; // Reset error message on new comment
    });

    // Animate the addition of the new comment
    _listKey.currentState?.insertItem(0);

    _commentController.clear();
    await _postCommentToServer(newComment, widget.videoID);
  }

  Future<void> _postCommentToServer(
      Map<String, dynamic> comment, String videoID) async {
    // const uri = '${Configuration.API_URL}reels/post-comment';

    final links = await Configuration().getCountryApiLink();
    final uri = '${links['api']}reels/post-comment';

    final response = await http.post(
      Uri.parse(uri),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'videoID': videoID,
        'userID': comment['user']['id'],
        'comment': comment['comment'],
      }),
    );

    if (response.statusCode != 200) {
      // Handle error response
      setState(() {
        _errorMessage = 'Failed to post comment. Please try again.';
      });
      // Optionally remove the comment if the post failed
      widget.comments.removeAt(0); // Remove the comment that failed to post
      _listKey.currentState?.removeItem(
          0, (context, animation) => _buildCommentTile(comment, animation));
    }
  }
}
