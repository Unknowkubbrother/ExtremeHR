import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Summary")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    Icon(Icons.star, size: 48, color: AppColors.textPrimary),
                    Text(
                      "4.5",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSizes.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPositive(["Positive 1", "Positive 2", "Positive 3"]),
              const SizedBox(height: 16),
              _buildNegative(["Negative 1", "Negative 2", "Negative 3"]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositive(List<String> responsibilities) {
    return CardContent(
      header: Row(
        children: [
          Icon(
            Icons.check_circle_outline_outlined,
            color: AppColors.positiveColor,
          ),
          const SizedBox(width: 8),
          Text(
            "Positive",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: AppColors.positiveColor,
            ),
          ),
        ],
      ),
      child: Column(
        spacing: 8,
        children: [
          for (var responsibility in responsibilities)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_outlined,
                  color: AppColors.positiveColor,
                ),
                const SizedBox(width: 8),
                Text(
                  responsibility,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimaryTo,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNegative(List<String> responsibilities) {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.dangerousColor),
          const SizedBox(width: 8),
          Text(
            "Negative",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: AppColors.dangerousColor,
            ),
          ),
        ],
      ),
      child: Column(
        spacing: 8,
        children: [
          for (var responsibility in responsibilities)
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.dangerousColor),
                const SizedBox(width: 8),
                Text(
                  responsibility,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimaryTo,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
