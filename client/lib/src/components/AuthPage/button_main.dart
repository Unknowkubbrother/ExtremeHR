import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

Widget buttonMain({String text = "", VoidCallback? onPressed}) {
  return Material(
    color: AppColors.primary,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      splashColor: AppColors.secondary,
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
