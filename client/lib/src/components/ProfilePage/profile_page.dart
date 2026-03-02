import 'package:client/src/components/AuthPage/auth_page.dart';
import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            CardContent(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person, size: 100, color: AppColors.primary),
                    Text(
                      "Alex Johnson",
                      style: TextStyle(
                        fontSize: AppFontSizes.title,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryTo,
                      ),
                    ),
                    Text(
                      "alex@example.com",
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inputTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CardList(
              icon: Icons.settings,
              child: Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryTo,
                ),
              ),
              action: () {
                debugPrint("Edit Profile");
              },
            ),
            Material(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                splashColor: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await AuthStorage().clear();
                  debugPrint("Logout");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.textPrimary),
                      const SizedBox(width: 16),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
