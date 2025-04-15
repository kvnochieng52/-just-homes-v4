import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' show join;

class RecordVideoScreen extends StatefulWidget {
  const RecordVideoScreen({super.key});

  @override
  _RecordVideoScreenState createState() => _RecordVideoScreenState();
}

class _RecordVideoScreenState extends State<RecordVideoScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  late XFile _videoFile;
  List<CameraDescription> _cameras = [];
  late int _selectedCameraIndex;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _selectedCameraIndex = 0;

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _initializeControllerFuture;
      final directory = await getTemporaryDirectory();
      final videoPath = join(directory.path, '${DateTime.now()}.mp4');

      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });

      // Start a timer to display recording duration
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
        });
      });
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _videoFile = await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordTimer?.cancel();
        _recordDuration = Duration.zero;
      });
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _toggleCamera() {
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red,
            width: 5.0,
          ),
        ),
      ),
    );
  }

  Future<void> _uploadVideo(File videoFile) async {
    // Implement video upload logic here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.switch_camera,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleCamera,
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: MediaQuery.of(context).size.width / 2 - 40,
                  child: _buildRecordButton(),
                ),
                if (_isRecording)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Text(
                      '${_recordDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
