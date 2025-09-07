import 'package:flutter/material.dart';
import 'package:studhome/OnBoardPages/main_into_page.dart';
import 'dart:async';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<FirstPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    double getFontSize(double baseSize) {
      return baseSize * (screenWidth / 390);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/launcher_icon.png',
              width: screenWidth * 0.5,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              "Welcome to StudHome!",
              style: TextStyle(
                fontSize: getFontSize(28),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.02),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
