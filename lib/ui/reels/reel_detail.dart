import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_apartment_live/ui/reels/comment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class ReelDetailPage extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final String username;
  final int likes;
  final int shares;
  final int userID;
  final List comments;

  const ReelDetailPage({
    super.key,
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.userID,
    required this.username,
    required this.comments,
  });

  @override
  _ReelDetailPageState createState() => _ReelDetailPageState();
}

class _ReelDetailPageState extends State<ReelDetailPage> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  bool _isLiked = false;
  late int _likesCount;
  late int _shareCount;
  late String name;
  List comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.likes;
    _shareCount = widget.shares;
    comments = widget.comments;
    _loadVideo();
    _loadLikeStatus();
    setState(() {
      name = widget.username;
    });
  }

  Future<void> _loadVideo() async {
    _vlcPlayerController = VlcPlayerController.network(
      widget.videoUrl,
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
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesCount++ : _likesCount--;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLiked_${widget.videoID}', _isLiked);

    try {
      final url = Uri.parse(
          'https://justhomes.co.ke/api/reels/update-likes?likes=$_likesCount&videoId=${widget.videoID}&user_id=${widget.userID}');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        print('Likes updated successfully on server');
      } else {
        print('Failed to update likes on server: ${response.body}');
      }
    } catch (e) {
      print('Error updating likes on server: $e');
    }
  }

  Future<void> _postComment(
      String commentText, StateSetter setModalState) async {
    if (commentText.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse(
        'https://justhomes.co.ke/api/reels/post-comment?videoID=${widget.videoID}&userID=${widget.userID}&comment=$commentText');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      print("Comment posted successfully");

      final newComment = {
        'user': {'id': userId, 'name': widget.user},
        'comment': commentText,
        'created_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        comments.insert(0, newComment); // Add the new comment instantly
        _commentController.clear(); // Clear the comment input
      });
    } else {
      print("Failed to post comment: ${response.body}");
    }
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: CommentsWidget(
            username: name,
            videoID: widget.videoID,
            comments: comments,
          ),
        ),
      ),
    );
  }

  Future<void> _shareVideo() async {
    setState(() {
      _shareCount++;
    });
    Share.share(widget.videoUrl);
  }

  Future<void> _loadLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLiked = prefs.getBool('isLiked_${widget.videoID}') ?? false;
    setState(() {});
  }
//

// Inside your ReelDetailPage class
  @override
  void dispose() {
    // Prepare the updated data to pass back
    Map<String, dynamic> updatedData = {
      'likes': _likesCount,
      'comments': comments.length,
    };

    // Pass the updated data back to UserReels
    Navigator.pop(context, updatedData);

    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _vlcPlayerController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _vlcPlayerController.setVolume(_isMuted ? 0 : 100);
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _vlcPlayerController.pause();
      } else {
        _vlcPlayerController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.black,
                child: VlcPlayer(
                  controller: _vlcPlayerController,
                  aspectRatio: MediaQuery.of(context).size.aspectRatio,
                  placeholder: const Center(child: CircularProgressIndicator()),
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
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 55,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.user}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 150,
              right: 20,
              child: Column(
                children: [
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.solidHeart,
                      color: _isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    _likesCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //  SizedBox(height: 10),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.share,
                        color: Colors.white),
                    onPressed: _shareVideo,
                  ),
                  Text(
                    _shareCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  const SizedBox(height: 30),
                ],
              ),
            ),
            Positioned(
              bottom: 160,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.comment, color: Colors.white),
                onPressed: _showCommentsBottomSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
