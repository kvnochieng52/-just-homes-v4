import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class LightboxPage extends StatefulWidget {
  final int initialIndex;
  final List<String> images;

  const LightboxPage({
    super.key,
    required this.initialIndex,
    required this.images,
  });

  @override
  _LightboxPageState createState() => _LightboxPageState();
}

class _LightboxPageState extends State<LightboxPage> {
  double _opacity = 1.0; // Controls the background opacity
  double _verticalDragDistance = 0.0; // Tracks the drag distance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(_opacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Update the drag distance and reduce opacity
          setState(() {
            _verticalDragDistance += details.delta.dy;
            _opacity = (1.0 - (_verticalDragDistance / 400).abs()).clamp(0.0, 1.0);
          });
        },
        onVerticalDragEnd: (details) {
          if (_opacity < 0.5) {
            // Close the lightbox if the opacity is below a threshold
            Navigator.of(context).pop();
          } else {
            // Reset the drag distance and opacity
            setState(() {
              _verticalDragDistance = 0.0;
              _opacity = 1.0;
            });
          }
        },
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 100),
          child: Transform.translate(
            offset: Offset(0, _verticalDragDistance),
            child: PhotoViewGallery.builder(
              itemCount: widget.images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.images[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              pageController: PageController(initialPage: widget.initialIndex),
            ),
          ),
        ),
      ),
    );
  }
}
