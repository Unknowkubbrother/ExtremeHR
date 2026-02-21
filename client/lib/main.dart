import 'package:client/src/components/SplashPage/splash_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtremeHR',
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
