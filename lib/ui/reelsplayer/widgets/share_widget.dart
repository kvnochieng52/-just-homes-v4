import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';

final logger = Logger();

class ShareWidget extends StatefulWidget {
  final int videoId;
  final int userId;
  final int initialShares;
  final String filepath;

  const ShareWidget({
    Key? key,
    required this.videoId,
    required this.userId,
    required this.initialShares,
    required this.filepath,
  }) : super(key: key);

  @override
  _ShareWidgetState createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<ShareWidget> {
  bool isLiked = false; // Initial like state
  int likeCount = 0; // Current like count
  bool isLoading = false; // API call status

  @override
  void initState() {
    super.initState();
    likeCount = widget.initialShares;
  }

  Future<void> _toggleLike() async {
    if (isLoading) return; // Prevent multiple simultaneous API calls

    setState(() {
      isLoading = true; // Show loading indicator
    });

    final url =
        'https://justhomes.co.ke/api/reels/update-shares?shares=${likeCount + 1}&videoId=${widget.videoId}&user_id=${widget.userId}';

    logger.i("URL ---> $url");

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            likeCount = int.parse(data['shares']); // Update with server value
            isLiked = true;
          });

          if (await File(widget.filepath).exists()) {
            XFile videoFile = XFile(widget.filepath);
            await Share.shareXFiles(
              [videoFile],
              text: 'Check out this cool Just Homes video!',
            );
          } else {
            logger.e("File not found at: ${widget.filepath}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video file not found!')),
            );
          }
        } else {
          throw Exception('Server error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to update shares. HTTP Status: ${response.statusCode}');
      }
    } catch (error) {
      logger.e("Error occurred: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return iconDetail(CupertinoIcons.arrow_turn_up_right, likeCount.toString(),
        _toggleLike, isLoading, isLiked);
  }
}

Widget iconDetail(IconData icon, String number, VoidCallback onPressed,
    bool isLoading, bool isLiked) {
  return GestureDetector(
    onTap: onPressed, // Trigger onPressed callback when tapped
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 33,
              color:
                  isLoading ? Colors.grey : Colors.white, // Loading indicator
            ),
            if (isLoading) const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
        Text(
          number,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
