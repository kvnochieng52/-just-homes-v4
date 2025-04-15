import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  _VideoPickerScreenState createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  final ImagePicker _picker = ImagePicker();

  // Function to open the bottom sheet
  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.fiber_manual_record, color: Colors.red),
                title: const Text('Live'),
                onTap: () {
                  Navigator.of(context).pop();
                  _recordVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Add Video'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickVideoFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to record a video
  Future<void> _recordVideo() async {
    final XFile? videoFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration:
          const Duration(minutes: 5), // Limit recording duration if needed
    );

    if (videoFile != null) {
      final file = File(videoFile.path);
      // Handle the recorded video file (e.g., save or upload)
      _saveVideo(file);
    }
  }

  // Function to pick a video from the gallery
  Future<void> _pickVideoFromGallery() async {
    final XFile? videoFile =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (videoFile != null) {
      final file = File(videoFile.path);
      // Handle the selected video file (e.g., save or upload)
      _saveVideo(file);
    }
  }

  // Function to save the video (example placeholder)
  void _saveVideo(File file) {
    // Implement your save functionality here
    print('Video saved at: ${file.path}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video saved at: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Picker')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showVideoOptions,
          child: const Text('Show Video Options'),
        ),
      ),
    );
  }
}
