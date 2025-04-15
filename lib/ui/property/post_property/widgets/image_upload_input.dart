import 'package:flutter/material.dart';

class ImageUploadInput extends StatelessWidget {
  final VoidCallback pickAssets;

  const ImageUploadInput({
    super.key,
    required this.pickAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: ElevatedButton.icon(
            onPressed: () => pickAssets(),
            icon: Icon(
              Icons.camera_alt,
              color:
                  Colors.purple.shade300, // Camera icon with faded purple color
            ),
            label: Text(
              "Select Images",
              style: TextStyle(
                color: Colors.purple.shade300, // Faded purple text color
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // Button background color
              side: BorderSide(
                color: Colors.purple.shade300, // Purple border color
              ),
              minimumSize: const Size(
                  double.infinity, 50), // Full width and fixed height
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 5.0),
          child: Text(
            'Maximum of 40 photos',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
