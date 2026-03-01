import 'package:client/src/components/AuthPage/auth_page.dart';
import 'package:client/src/components/HomePage/main_navigation_page.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/user_services.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  AuthStorage authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await authStorage.getToken();

    if (token == null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
    }
    try {
      await UserServices().me(token!);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage(state: 0)),
      );
    } catch (e) {
      debugPrint(e.toString());
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Icon(Icons.person_pin, size: 100, color: AppColors.primary),
      ),
    );
  }
}
