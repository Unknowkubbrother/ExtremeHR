import 'package:client/src/components/AuthPage/button_main.dart';
import 'package:client/src/components/AuthPage/input_textfield.dart';
import 'package:client/src/components/AuthPage/role_switcher.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/user_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/user_services.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.toggleLogin,
    required this.setToLogin,
  });

  final VoidCallback toggleLogin;
  final VoidCallback setToLogin;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isCandidate = true;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userServices = UserServices();
  final storage = AuthStorage();
  String error_msg = "";

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        error_msg = 'Passwords do not match';
      });
      return;
    }
    try {
      await userServices.register(
        UserRegister(
          username: usernameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        ),
      );

      if (!mounted) return;
      widget.setToLogin();
    } catch (e) {
      if (!mounted) return;

      debugPrint(e.toString());
      setState(() {
        error_msg = 'Register failed';
      });
    }
  }

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
          "USERNAME",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        inputTextField(hintText: "username", controller: usernameController),
        SizedBox(height: 32),
        Text(
          "EMAIL",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        inputTextField(
          hintText: "email@example.com",
          controller: emailController,
        ),
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
        inputTextField(
          hintText: "password",
          isPassword: true,
          controller: passwordController,
        ),
        SizedBox(height: 32),
        Text(
          "CONFIRM PASSWORD",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        inputTextField(
          hintText: "confirm password",
          isPassword: true,
          controller: confirmPasswordController,
        ),
        SizedBox(height: 32),
        buttonMain(text: "SIGN UP", onPressed: register),
        if (error_msg.isNotEmpty)
          Center(
            child: Column(
              children: [
                SizedBox(height: 8),
                Text(
                  error_msg,
                  style: TextStyle(
                    color: AppColors.dangerousColor,
                    fontSize: AppFontSizes.small,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            Text(
              "Already have an account?",
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
                "LOGIN",
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
