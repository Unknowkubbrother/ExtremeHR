import 'package:client/src/components/AuthPage/button_main.dart';
import 'package:client/src/components/AuthPage/input_textfield.dart';
import 'package:client/src/components/AuthPage/role_switcher.dart';
import 'package:client/src/components/HomePage/main_navigation_page.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Function() toggleLogin;
  const LoginPage({super.key, required this.toggleLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isCandidate = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleSwitcher(
          isCandidate: isCandidate,
          onRoleChanged: (value) {
            setState(() {
              isCandidate = value;
            });
          },
        ),
        const SizedBox(height: 32),
        Text(
          "EMAIL",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        inputTextField(hintText: "email@example.com"),
        SizedBox(height: 32),
        Text(
          "PASSWORD",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        inputTextField(hintText: "password", isPassword: true),
        SizedBox(height: 32),
        buttonMain(
          text: "LOGIN",
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigationPage(state: 0),
              ),
            );
          },
        ),

        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            Text(
              "Don't have an account?",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.small,
                fontWeight: FontWeight.normal,
              ),
            ),
            TextButton(
              onPressed: () {
                widget.toggleLogin();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                "SIGN UP",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
