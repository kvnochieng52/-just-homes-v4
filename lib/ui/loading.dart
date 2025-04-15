import 'package:flutter/material.dart';

class Loading {
  loader(BuildContext context, String msg) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  msg.isEmpty ? "Processing...Please Wait" : msg,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
