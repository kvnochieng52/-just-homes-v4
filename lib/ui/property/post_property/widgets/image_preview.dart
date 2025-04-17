import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ImagePreview extends StatefulWidget {
  final List<File> images;
  final List<String> uploadedImageUrls;
  final bool isUploading;
  final Function(List<File>) onImagesChanged;
  final Function(int) onRemoveImage;

  const ImagePreview({
    super.key,
    required this.images,
    required this.uploadedImageUrls,
    required this.isUploading,
    required this.onImagesChanged,
    required this.onRemoveImage,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool _isExpanded = false;

  Future<void> _pickAssets() async {
    try {
      final permissionStatus = await PhotoManager
          .requestPermissionExtend(); // Renamed to permissionStatus
      if (!permissionStatus.isAuth) {
        // Changed result to permissionStatus
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required to pick images.'),
          ),
        );
        return;
      }
      final selectedAssets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 20 - widget.images.length,
          requestType: RequestType.image,
          // Remove selectedAssets parameter unless specifically needed
        ),
      );

      if (selectedAssets != null) {
        // Changed result to selectedAssets
        final List<File> newImages = [];
        for (final asset in selectedAssets) {
          // Changed result to selectedAssets
          final File? file = await asset.file;
          if (file != null) {
            newImages.add(file);
          }
        }

        if (newImages.isNotEmpty) {
          widget.onImagesChanged([...widget.images, ...newImages]);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _toggleExpandCollapse() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildImageItem(int index) {
    final isUploaded = index < widget.uploadedImageUrls.length;
    final isUploading = widget.isUploading && !isUploaded;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: FileImage(widget.images[index]),
              fit: BoxFit.cover,
            ),
          ),
          child: isUploading
              ? Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : null,
        ),
        if (isUploaded)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
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
                color: Colors.red,
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
  }

  @override
  Widget build(BuildContext context) {
    final visibleImagesCount = _isExpanded
        ? widget.images.length
        : (widget.images.length > 6 ? 6 : widget.images.length);

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
          itemCount: visibleImagesCount + 1, // +1 for the add button
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: widget.images.length >= 20 ? null : _pickAssets,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.images.length >= 20
                        ? Colors.grey.shade300
                        : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: widget.images.length >= 20
                          ? Colors.grey
                          : Colors.purple,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 40,
                      color: widget.images.length >= 20
                          ? Colors.grey
                          : Colors.purple,
                    ),
                  ),
                ),
              );
            }
            return _buildImageItem(index - 1);
          },
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
