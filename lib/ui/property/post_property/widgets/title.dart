import 'package:flutter/material.dart';

class TitleInput extends StatelessWidget {
  final TextEditingController titleController;
  final FormFieldValidator<String>? validator;

  const TitleInput({
    super.key,
    required this.titleController,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: TextFormField(
        controller: titleController,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: 'Title',
          hintText: 'Enter Property Title',
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70 // Label text color in dark mode
                : Colors.black54, // Label text color in light mode
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54 // Hint text color in dark mode
                : Colors.black38, // Hint text color in light mode
          ),
          filled: true, // Enable filling
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800] // Background color in dark mode
              : Colors.white, // Background color in light mode
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38 // Border color in dark mode
                  : Colors.black54, // Border color in light mode
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white // Focused border color in dark mode
                  : Colors.blue, // Focused border color in light mode
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
