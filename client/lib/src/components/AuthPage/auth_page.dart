import 'package:client/src/components/AuthPage/button_main.dart';
import 'package:client/src/components/AuthPage/input_textfield.dart';
import 'package:client/src/components/AuthPage/role_switcher.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isCandidate = true;

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
                color: Color.fromRGBO(255, 255, 255, 0.2),
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
                Text(
                  "Welcome to ExtremeHR",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
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
                        print(
                          "Login button pressed for ${isCandidate ? 'Candidate' : 'HR/Recruiter'}",
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
                            print("Sign up button pressed");
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
