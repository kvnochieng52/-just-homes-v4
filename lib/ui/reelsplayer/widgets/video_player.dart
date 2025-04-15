import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Videoplayer extends StatefulWidget {
  const Videoplayer({super.key, required this.url});

  final String url;

  @override
  _VideoplayerState createState() => _VideoplayerState();
}

class _VideoplayerState extends State<Videoplayer> {
  late VideoPlayerController controller;
  bool _isControllerInitialized = false;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await controller.initialize().then((_) {
      setState(() {
        _isControllerInitialized = true;
      });
      controller.addListener(() {
        if (controller.value.position == controller.value.duration &&
            controller.value.isCompleted) {
          controller.seekTo(Duration.zero);
          controller.play();
        }
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isControllerInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      setState(() {
        _showPlayPauseIcon = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _showPlayPauseIcon = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerAspectRatio = MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    double videoAspectRatio = controller.value.aspectRatio;

    // Log aspect ratios to check if they are correct
    print('⛔ Container aspect ratio: $containerAspectRatio');
    print('⛔ Video aspect ratio: $videoAspectRatio');

    // Set a threshold for when the video is considered stretched
    double threshold = 0.5;

    // Check if the video is stretched
    bool isVideoStretched = (containerAspectRatio - videoAspectRatio).abs() > threshold;

    // Adjust the height or width based on the video aspect ratio
    double videoHeight = MediaQuery.of(context).size.width / videoAspectRatio;

    if (isVideoStretched) {
      // If the video is stretched, ensure it doesn't exceed the container height
      videoHeight = 300;
    }else{
      videoHeight = MediaQuery.of(context).size.height;
    }

    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: (visibilityInfo) {
        var visibilityPercentage = visibilityInfo.visibleFraction * 100;
        if (visibilityPercentage > 50 && _isControllerInitialized) {
          controller.play();
        } else if (_isControllerInitialized) {
          controller.pause();
        }
      },
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _isControllerInitialized
                ? FittedBox(
              fit: BoxFit.cover, // Ensures the video fills the screen without stretching
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: videoHeight, // Adjusted height based on aspect ratio
                child: VideoPlayer(controller),
              ),
            )
                : const Center(child: CupertinoActivityIndicator()),
            if (_showPlayPauseIcon)
              Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 60,
              ),
          ],
        ),
      ),
    );
  }
}
