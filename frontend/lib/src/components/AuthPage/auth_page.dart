import 'package:client/src/components/AuthPage/signup_page.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  void toggleLogin() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void setToLogin() {
    setState(() {
      isLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blur,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.computer, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 15),
            const Text(
              "ExtremeHR",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSizes.subtitle,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                isLogin
                    ? Text(
                        "Welcome to ExtremeHR",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppFontSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        "Join ExtremeHR",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppFontSizes.title,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                if (isLogin)
                  Text(
                    "Smart Recruitment,\nPowered by AI",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.bold,
                    ),
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
              child: SingleChildScrollView(
                child: isLogin
                    ? LoginPage(toggleLogin: toggleLogin)
                    : SignUpPage(
                        toggleLogin: toggleLogin,
                        setToLogin: setToLogin,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
