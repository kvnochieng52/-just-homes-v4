import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final bool autoFocus;
  final Function(String)? onChanged;

  const CodeInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.autoFocus = false,
    this.onChanged,
  });

  @override
  _CodeInputFieldState createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: widget.focusNode,
      onKey: (event) {
        if (event.runtimeType.toString() == 'RawKeyDownEvent') {
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            if (widget.focusNode.hasFocus) {
              FocusScope.of(context).previousFocus();
            }
          }
        }
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autoFocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Make text bold
            fontSize: 18, // Adjust size if needed
          ),
          onChanged: (value) {
            if (value.length == 1 && widget.nextFocusNode != null) {
              FocusScope.of(context).requestFocus(widget.nextFocusNode);
            } else if (value.isEmpty && widget.focusNode.hasFocus) {
              FocusScope.of(context).previousFocus();
            }
            widget.onChanged?.call(value);
          },
        ),
      ),
    );
  }
}
