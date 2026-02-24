import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class Filter extends StatefulWidget {
  const Filter({super.key});

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final List<String> _filters = [
    "All",
    "Technology",
    "Business",
    "Marketing",
    "Sales",
    "Finance",
    "Human Resources",
    "Education",
    "Healthcare",
    "Customer Service",
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(width: 2, color: AppColors.primary),
                  color: _selectedIndex == index
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: AppFontSizes.small,
                    color: _selectedIndex == index
                        ? Colors.white
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
