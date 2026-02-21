import 'package:client/src/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CardContent extends StatefulWidget {
  final Widget header;
  final Widget child;

  const CardContent({super.key, required this.header, required this.child});

  @override
  State<CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<CardContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [widget.header, SizedBox(height: 16), widget.child],
      ),
    );
  }
}
