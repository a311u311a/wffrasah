import 'package:rbhan/constants.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.redAccent : Constants.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
