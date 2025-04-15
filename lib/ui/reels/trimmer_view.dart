import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/reelsplayer/reel_player.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:path/path.dart';
import 'package:flutter/rendering.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:audioplayers/audioplayers.dart'; // For audio playback

class TrimmerView extends StatefulWidget {
  bool? isLiveVideo;
  File file;

  TrimmerView(
    this.file, {
    super.key,
    this.isLiveVideo = false,
  });

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final _trimmer = Trimmer();
  final TextEditingController _descriptionController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool _hasLoggedIn = false;
  int? _userID = 0;
  double _speed = 1.0; // Default speed
  File? _selectedMusicFile;
  File? _voiceoverFile;
  String? _audioPath;

  bool _isMuted = false;
  String? _selectedSoundName;

  @override
  void initState() {
    super.initState();
    _loadVideo();
    _loadUser();
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
      });
    } else {
      setState(() {
        _hasLoggedIn = true;
      });
    }
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<File?> _captureScreenshot() async {
    final uint8List = await VideoThumbnail.thumbnailData(
      video: widget.file.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 1280,
      quality: 75,
    );

    if (uint8List != null) {
      final filePath = '${widget.file.path}_thumbnail.png';
      final file = File(filePath);
      await file.writeAsBytes(uint8List);
      return file;
    }
    return null;
  }

  void _showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  //-----------------------------SAVING & COMPRESS RECORDED VIDEO-----------------------------------------------
  Future<void> saveLiveVideo(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          final compressedPath = await _compressVideo(outputPath);

          if (compressedPath == null) {
            _showErrorDialog('Failed to compress video', context);
            return;
          }

          final screenshotFile = await _captureScreenshot();
          if (screenshotFile == null) {
            _showErrorDialog('Failed to capture screenshot', context);
            return;
          }

          await uploadVideoLive(
            url: 'https://justhomes.co.ke/api/reels/upload-video',
            userId: _userID ?? 0,
            description: _descriptionController.text,
            videoFile: File(compressedPath),
            screenshotFile: screenshotFile,
          );

          setState(() {
            _progressVisibility = false;
          });

          const snackBar =
              SnackBar(content: Text('Live video saved successfully.'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          setState(() {
            _progressVisibility = false;
          });
          _showErrorDialog('Failed to save video', context);
        }
      },
    );
  }

  Future<String?> _compressVideo(String filePath) async {
    try {
      final info = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (info != null && info.path != null) {
        logger.i('Video compression successful: ${info.path}');
        return info.path;
      } else {
        logger.e('Video compression failed');
        return null;
      }
    } catch (e) {
      logger.e('Error during video compression: $e');
      return null;
    }
  }

  Future<void> uploadVideoLive({
    required String url,
    required int userId,
    required String description,
    required File videoFile,
    required File screenshotFile,
  }) async {
    try {
      final uri = Uri.parse('$url?user_id=$userId&description=$description');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: 'video.mp4',
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshotFile.path,
          filename: 'screenshot.jpg',
        ),
      );

      logger.i('POST Request to: $uri');
      logger.i('Request fields: user_id=$userId, description=$description');
      logger.i('Video file: ${videoFile.path}');
      logger.i('Screenshot file: ${screenshotFile.path}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        logger.i('Upload successful: $responseData');
      } else {
        logger.e('Upload failed with status: ${response.statusCode}');
        logger.e('Response: $responseData');
      }
    } catch (e) {
      logger.e('Error during upload: $e');
    }
  }

  //-----------------------------NEW FEATURES-----------------------------------------------

  // Split Video
  Future<void> _splitVideo(String inputPath, List<double> splitPoints) async {
    final outputPaths = <String>[];
    for (var i = 0; i < splitPoints.length - 1; i++) {
      final start = splitPoints[i];
      final end = splitPoints[i + 1];
      final outputPath = '${inputPath}_part$i.mp4';

      final command =
          '-i "$inputPath" -ss $start -to $end -c copy "$outputPath"';
      await FFmpegKit.execute(command);

      outputPaths.add(outputPath);
    }

    logger.i('Split video into parts: $outputPaths');
  }

  // Change Video Speed
  Future<void> _changeVideoSpeed(String inputPath, double speed) async {
    final outputPath = '${inputPath}_speed_$speed.mp4';
    final command =
        '-i "$inputPath" -vf "setpts=${1 / speed}*PTS" -af "atempo=$speed" "$outputPath"';

    await FFmpegKit.execute(command);

    logger.i('Video speed changed: $outputPath');
  }

  // Add Music
  Future<void> _addMusic(String videoPath, String audioPath) async {
    final outputPath = '${videoPath}_with_music.mp4';
    final command =
        '-i "$videoPath" -i "$audioPath" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

    await FFmpegKit.execute(command);

    logger.i('Music added to video: $outputPath');
  }

  // Record Voiceover
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Define the path where the recording will be saved
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/recording.m4a';

        // Start recording with the required parameters
        await _audioRecorder.start(
          const RecordConfig(), // Use default configuration
          path: path, // Specify the save path
        );

        setState(() {
          _isRecording = true;
        });
      } else {
        print('Permission denied');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      print('Recording saved to: $path');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  // Add Voiceover
  Future<void> _addVoiceover(String videoPath, String audioPath) async {
    final outputPath = '${videoPath}_with_voiceover.mp4';
    final command =
        '-i "$videoPath" -i "$audioPath" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

    await FFmpegKit.execute(command);

    logger.i('Voiceover added to video: $outputPath');
  }

  Future<void> _saveVideo(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      // ffmpegCommand:
      //     '-vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0',
      // customVideoFormat: '.gif',
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          final directory = dirname(outputPath);
          const fileName = 'trimmed_video.mp4';
          final newFilePath = join(directory, fileName);

          final trimmedFile = File(newFilePath);
          await File(outputPath).copy(trimmedFile.path);
          await File(outputPath).delete();

          // Call upload video function
          await _uploadVideo(trimmedFile, _descriptionController.text, context);

          setState(() {
            _progressVisibility = false;
          });

          // Show success message (optional)
          final snackBar = SnackBar(
            //   content: Text('Video Saved successfully\n${trimmedFile.path}'),
            content: Text('Video uploaded successfully'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          setState(() {
            _progressVisibility = false;
          });

          // Show error message
          _showErrorDialog('Failed to save video', context);
        }
      },
    );
  }

  Future<void> _uploadVideo(
      File videoFile, String description, BuildContext context) async {
    const loadingDialog = AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Uploading video...'),
        ],
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => loadingDialog,
    );

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    // final uri = Uri.parse('${Configuration.API_URL}reels/upload-video');
    // logger.w('Uploading file: ${videoFile.path}');

    final links = await Configuration().getCountryApiLink();
    final uri = Uri.parse('${links['api']}reels/upload-video');
    logger.w('Uploading file: ${videoFile.path}');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = user['id'].toString()
      ..fields['description'] = description
      ..files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: basename(videoFile.path),
        ),
      );

    // Capture the screenshot
    final screenshotFile = await _captureScreenshot();
    if (screenshotFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshotFile.path,
          filename: basename(screenshotFile.path),
        ),
      );
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Redirect to ReelsPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                const Reels(), // Your ReelsPage widget
          ),
        );
      } else {
        _showErrorDialog('Failed to upload video: $responseData', context);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error uploading video: $e', context);
    }
  }

  // void _showErrorDialog(String message, BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Upload Error'),
  //         content: Text(message),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //-----------------------------UI FOR NEW FEATURES-----------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Upload Reel'),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                // Progress Indicator
                Visibility(
                  visible: _progressVisibility,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),

                // Video Viewer
                Expanded(child: VideoViewer(trimmer: _trimmer)),
                const SizedBox(height: 10),

                // Trim Viewer
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                      maxVideoLength: const Duration(seconds: 140),
                      editorProperties: TrimEditorProperties(
                        borderPaintColor: Colors.yellow,
                        borderWidth: 4,
                        borderRadius: 5,
                        circlePaintColor: Colors.yellow.shade800,
                      ),
                      areaProperties:
                          TrimAreaProperties.edgeBlur(thumbnailQuality: 10),
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) => setState(
                        () => _isPlaying = value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Play/Pause Button
                TextButton(
                  child: _isPlaying
                      ? const Icon(
                          Icons.pause,
                          size: 50.0,
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.play_arrow,
                          size: 50.0,
                          color: Colors.white,
                        ),
                  onPressed: () async {
                    final playbackState = await _trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() => _isPlaying = playbackState);
                  },
                ),
                const SizedBox(height: 10),

                // Description TextField and Send Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Add a description...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 20.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _progressVisibility
                              ? null
                              : () => widget.isLiveVideo!
                                  ? saveLiveVideo(context)
                                  : _saveVideo(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Selected Sound Placeholder
                if (_selectedSoundName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          _selectedSoundName!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedSoundName = null;
                              _selectedMusicFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                // Feature Buttons (Split, Speed, Music, Voiceover, Mute)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_off),
                      onPressed: () async {
                        await _removeBackgroundSound(widget.file.path, context);
                      },
                      tooltip: 'Remove Background Sound',
                    ),

                    // Add Selected Sound Button
                    // IconButton(
                    //   icon: const Icon(Icons.music_note),
                    //   onPressed: () async {
                    //     if (_selectedMusicFile != null) {
                    //       await _addSelectedSound(widget.file.path, _selectedMusicFile!.path, context);
                    //     } else {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(content: Text('Please select a sound first')),
                    //       );
                    //     }
                    //   },
                    //   tooltip: 'Add Selected Sound',
                    // ),

                    IconButton(
                      icon: const Icon(Icons.music_note),
                      onPressed: () async {
                        final selectedSound = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SoundSelectionPage(),
                          ),
                        );

                        if (selectedSound != null) {
                          setState(() {
                            _selectedSoundName = selectedSound['name'];
                          });

                          // Download the selected audio file
                          final downloadedFile = await _downloadAudioFile(
                              selectedSound['url'], context);
                          if (downloadedFile != null) {
                            setState(() {
                              _selectedMusicFile = downloadedFile;
                            });

                            // Add the selected sound to the video
                            await _addSelectedSound(
                                widget.file.path, downloadedFile.path, context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to download selected sound')),
                            );
                          }
                        }
                      },
                      tooltip: 'Add Music',
                    ), // Split Video Button
                    IconButton(
                      icon: const Icon(Icons.cut),
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Coming Soon: Split Video",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.black54,
                          textColor: Colors.white,
                        );
                      },
                      tooltip: 'Split Video',
                    ),

                    // Change Speed Button
                    IconButton(
                      icon: const Icon(Icons.speed),
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Coming Soon: Change Speed",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.black54,
                          textColor: Colors.white,
                        );
                      },
                      tooltip: 'Change Speed',
                    ),

                    // Record Voiceover Button
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () async {
                        await _startRecording();
                      },
                      tooltip: 'Record Voiceover',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeBackgroundSound(
      String inputPath, BuildContext context) async {
    try {
      final outputPath = '${inputPath}_no_audio.mp4';
      final command = '-i "$inputPath" -c:v copy -an "$outputPath"';

      print('Executing FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('Background sound removed successfully: $outputPath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Background sound removed')),
        );

        // Update the video file to the new file without audio
        setState(() {
          widget.file = File(outputPath);
        });

        // Reload the video
        _loadVideo();

        setState(() {});
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('FFmpeg command failed: $failStackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove background sound')),
        );
      }
    } catch (e) {
      print('Error removing background sound: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<File?> _downloadAudioFile(String url, BuildContext context) async {
    showProgressDialog(context, 'Downloading audio...');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/selected_music.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        Navigator.of(context).pop(); // Close the progress dialog
        return file;
      } else {
        Navigator.of(context).pop(); // Close the progress dialog
        print('Failed to download audio file: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the progress dialog
      print('Error downloading audio file: $e');
      return null;
    }
  }

  void showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSelectedSound(
      String videoPath, String audioPath, BuildContext context) async {
    showProgressDialog(context, 'Adding selected sound...');

    try {
      final outputPath = '${videoPath}_with_selected_sound.mp4';
      final command =
          '-i "$videoPath" -i "$audioPath" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

      print('Executing FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      Navigator.of(context).pop(); // Close the progress dialog

      if (ReturnCode.isSuccess(returnCode)) {
        print('Selected sound added successfully: $outputPath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected sound added to video')),
        );

        // Update the video file to the new file with selected sound
        setState(() {
          widget.file = File(outputPath);
        });

        // Reload the video
        _loadVideo();
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('FFmpeg command failed: $failStackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add selected sound')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the progress dialog
      print('Error adding selected sound: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class SoundSelectionPage extends StatefulWidget {
  @override
  _SoundSelectionPageState createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<SoundSelectionPage> {
  final String _apiKey = 'c79d92d2'; // Replace with your Jamendo API key
  final String _baseUrl = 'https://api.jamendo.com/v3.0/tracks';
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  // Fetch tracks from Jamendo API
  Future<void> _fetchTracks({String query = ''}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl?client_id=$_apiKey&format=json&limit=20&search=$query',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tracks = List<Map<String, dynamic>>.from(data['results']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tracks');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error fetching tracks: $e')),
      // );
    }
  }

  // Play or pause audio
  Future<void> _playOrPauseAudio(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      // Pause the currently playing audio
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Stop any currently playing audio
      if (_currentlyPlayingUrl != null) {
        await _audioPlayer.stop();
      }

      // Play the new audio
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingUrl = url;
        _isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Sound'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for music...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _fetchTracks(query: _searchQuery),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) => _searchQuery = value,
            ),
          ),
          // Loading Indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // Track List
          Expanded(
            child: ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final isCurrentlyPlaying =
                    _currentlyPlayingUrl == track['audio'];
                return ListTile(
                  leading: track['image'] != null
                      ? Image.network(track['image'],
                          width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title: Text(track['name']),
                  subtitle: Text(track['artist_name']),
                  trailing: IconButton(
                    icon: Icon(
                      isCurrentlyPlaying && _isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () => _playOrPauseAudio(track['audio']),
                  ),
                  onTap: () {
                    // Return the selected track to the previous screen
                    Navigator.pop(context, {
                      'name': track['name'],
                      'url': track['audio'], // URL of the audio file
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
