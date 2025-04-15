import 'package:flutter/material.dart';

class DropdownStyleHelper {
  static Widget dropdownBuilder(
    BuildContext context,
    Map<String, dynamic>? selectedItem,
    String? itemAsString,
    bool isDarkMode, // Added isDarkMode to handle themes
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedItem?["value"] ?? itemAsString ?? "County",
              style: TextStyle(
                color: selectedItem != null
                    ? isDarkMode
                        ? Colors.white
                        : Colors.grey.shade700
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget popupItemBuilder(
    BuildContext context,
    Map<String, dynamic> item,
    bool isSelected,
    bool isDarkMode, // Added isDarkMode to handle themes
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode
                ? Colors.grey.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Text(
          item["value"] ?? "",
          style: TextStyle(
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.grey.shade900)
                : (isDarkMode ? Colors.white70 : Colors.black),
          ),
        ),
      ),
    );
  }

  static InputDecoration dropdownSearchDecoration(bool isDarkMode) {
    return InputDecoration(
      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100.0),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
    );
  }

  static InputDecoration dropdownDecoration(bool isDarkMode) {
    return InputDecoration(
      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
          width: 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.white : Colors.grey.shade700,
          width: 0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
    );
  }
}
