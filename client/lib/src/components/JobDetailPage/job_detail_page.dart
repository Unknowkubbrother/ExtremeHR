import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: Text(
          "Job Detail",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Job Title",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.title,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Company Name",
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    Text(
                      "Job Location",
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Text("hello"),
            ),
          ),
        ],
      ),
    );
  }
}
