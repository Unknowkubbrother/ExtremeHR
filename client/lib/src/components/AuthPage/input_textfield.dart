import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

Widget inputTextField({String hintText = "", bool isPassword = false}) {
  return TextField(
    obscureText: isPassword,
    decoration: InputDecoration(
      fillColor: Colors.grey.shade200,
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.inputTextColor,
        fontSize: AppFontSizes.body,
      ),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
