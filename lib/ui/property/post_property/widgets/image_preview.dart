import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ImagePreview extends StatefulWidget {
  final List<File> images;
  final Function(int) onRemoveImage;
  final VoidCallback onAddImage;

  const ImagePreview({
    super.key,
    required this.images,
    required this.onRemoveImage,
    required this.onAddImage,
    required Future<void> Function(File image) onUploadImage,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool _isExpanded = false;
  List<String> uploadedImagePaths = [];

  @override
  void initState() {
    super.initState();
    _fetchWebUrl();
    _loadSavedImagePaths();
  }

  bool hasGotApiLink = false;

  var _webUrlFuture = '';

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      _webUrlFuture = apiLink['web'].toString();
      hasGotApiLink = true;
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  void _toggleExpandCollapse() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _loadSavedImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uploadedImagePaths = prefs.getStringList('uploaded_images') ?? [];
    });
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    uploadedImagePaths.add(path);
    await prefs.setStringList('uploaded_images', uploadedImagePaths);
  }

  Future<String> _uploadImage(File image) async {
    final link = hasGotApiLink ? _webUrlFuture : '';
    final url = Uri.parse('${link}api/property/upload-property-image');
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(responseData);
      String imagePath = data['image_path'];
      await _saveImagePath(imagePath);
      return imagePath;
    } else {
      throw Exception('Failed to upload image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int visibleImagesCount = _isExpanded
        ? widget.images.length
        : (widget.images.length > 6 ? 6 : widget.images.length);

    final List<Widget> items = [
      GestureDetector(
        onTap: widget.onAddImage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.purple),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 40, color: Colors.purple),
          ),
        ),
      ),
      if (widget.images.isNotEmpty)
        ...List.generate(visibleImagesCount, (index) {
          return Stack(
            children: [
              FutureBuilder<String>(
                future: _uploadImage(widget.images[index]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(
                        child: SizedBox(
                          height: 10,
                          width: 10,
                          child:
                              CircularProgressIndicator(color: Colors.purple),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      color: Colors.red.withOpacity(0.5),
                      child: const Center(
                        child: Text('Error',
                            style: TextStyle(color: Colors.white)),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: FileImage(widget.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => widget.onRemoveImage(index),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Please upload at least 1 photo. You can add up to 20 photos.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
        if (widget.images.length > 6)
          TextButton(
            onPressed: _toggleExpandCollapse,
            child: Text(_isExpanded
                ? "Show less"
                : "Show more (${widget.images.length - 6})"),
          ),
        const SizedBox(height: 8),
        const Text(
          "Supported formats are .jpg and .png. Pictures may not exceed 5MB.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
