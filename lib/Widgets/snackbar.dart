import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, String varient) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: varient == "error"
          ? Colors.red[400]
          : varient == "basic"
          ? Colors.black54
          : Colors.green[400],
      action: SnackBarAction(
        label: "Close",
        onPressed: () {},
        textColor: Colors.white,
      ),
    ),
  );
}
