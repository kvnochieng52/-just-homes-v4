import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final int selectionIndex = newValue.selection.end;
    int commasBeforeCursor = 0;

    // Count the number of commas before the cursor in the old value
    for (int i = 0; i < oldValue.selection.baseOffset; i++) {
      if (oldValue.text[i] == ',') {
        commasBeforeCursor++;
      }
    }

    // Remove any non-digit characters (commas) from the new value
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final newTextLength = newText.length;

    // Format the new value with commas and prepend "KSH"
    newText = "KSH ${NumberFormat('#,###').format(int.parse(newText))}";

    // Calculate the new cursor position
    int newCommasCount = 0;
    for (int i = 0; i < newText.length; i++) {
      if (newText[i] == ',') {
        newCommasCount++;
      }
    }

    final newSelectionIndex = selectionIndex +
        (newCommasCount - commasBeforeCursor) +
        4; // +4 for "KSH "

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
