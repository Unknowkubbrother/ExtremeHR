import 'package:client/src/components/AuthPage/auth_page.dart';
import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/user_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/user_services.dart';
import 'package:client/src/components/ProfilePage/company_edit_page.dart';
import 'package:client/src/components/ProfilePage/profile_edit_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthStorage _authStorage = AuthStorage();
  final UserServices _userService = UserServices();

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = await _authStorage.getToken();
    if (token != null) {
      final data = await _userService.me(token);
      if (!mounted) return;
      setState(() {
        _user = data;
      });
    }
  }

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
                      _user?.username ?? "",
                      style: TextStyle(
                        fontSize: AppFontSizes.title,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryTo,
                      ),
                    ),
                    Text(
                      _user?.email ?? "",
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
              action: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditPage(),
                  ),
                );
                if (result == true) {
                  _loadProfile();
                }
              },
            ),
            if (_user?.role == 'hr')
              CardList(
                icon: Icons.business,
                child: Text(
                  "Edit Company",
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryTo,
                  ),
                ),
                action: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyEditPage(),
                    ),
                  );
                },
              ),
            ElevatedButton(
              onPressed: () async {
                await AuthStorage().clear();
                debugPrint("Logout");
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
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
          ],
        ),
      ),
    );
  }
}
