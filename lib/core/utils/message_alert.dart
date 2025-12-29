import 'package:flutter/material.dart';

void showMessage(
  BuildContext context,
  String message, {
  Color bgColor = Colors.grey,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
