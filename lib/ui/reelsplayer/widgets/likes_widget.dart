import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';


final logger = Logger();


class LikeWidget extends StatefulWidget {
  final int videoId;
  final int userId;
  final int initialLikes;

  const LikeWidget({
    Key? key,
    required this.videoId,
    required this.userId,
    required this.initialLikes,
  }) : super(key: key);

  @override
  _LikeWidgetState createState() => _LikeWidgetState();
}

class _LikeWidgetState extends State<LikeWidget> {
  bool isLiked = false; // Initial like state
  int likeCount = 0; // Current like count
  bool isLoading = false; // API call status

  @override
  void initState() {
    super.initState();
    likeCount = widget.initialLikes;
  }

  Future<void> _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      isLoading = true; // Show a loading spinner
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });


    final url =
        'https://justhomes.co.ke/api/reels/update-likes?likes=$likeCount&videoId=${widget.videoId}&user_id=${widget.userId}';

    logger.i("URL ---> $url");

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        logger.i("Resp ---> $data");

        if (data['success']) {
          setState(() {
            likeCount =
                int.parse(data['likes']); // Update count with API response
          });
        } else {
          logger.e("Error ---> $data");

          throw Exception('Failed to update likes');
        }
      } else {
        logger.e("Error ---> $response");

        throw Exception('Failed to reach API');
      }
    } catch (error) {
      setState(() {
        // Revert like state in case of error
        isLiked = !isLiked;
        likeCount = isLiked ? likeCount + 1 : likeCount - 1;
      });
      debugPrint('Error: $error');
    } finally {
      setState(() {
        isLoading = false; // Stop the loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return iconDetail(
        isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
        likeCount.toString(),
        _toggleLike,
        isLoading,
        isLiked);
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
              color: isLoading
                  ? Colors.grey
                  : isLiked
                      ? Colors.red
                      : Colors.white, // Loading indicator
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
