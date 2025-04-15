import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentsWidget extends StatefulWidget {
  final int videoID;
  final String username;
  List comments = [];

  CommentsWidget({
    super.key,
    required this.videoID,
    required this.username,
    required this.comments,
  });

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  late List comments;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      comments = widget.comments;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment(String commentText) async {
    if (commentText.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse(
        'https://justhomes.co.ke/api/reels/post-comment?videoID=${widget.videoID}&userID=$userId&comment=$commentText');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final newComment = {
        'user': {
          'id': userId,
          'name': widget.username
        }, // Replace with actual user data
        'comment': commentText,
        'created_at': DateTime.now().toString(),
      };

      setState(() {
        comments.insert(0, newComment);
      });

      _commentController.clear();
    } else {
      // Handle error or show an error message
      print("Failed to post comment: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // CLOSE
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
              child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              String userName = 'U';
              if (comment['user'] != null && comment['user']['name'] != null) {
                userName = comment['user']['name'];
              }

              return ListTile(
                title: Text(userName),
                subtitle: Text(comment['comment']),
              );
            },
          )),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _postComment(_commentController.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
