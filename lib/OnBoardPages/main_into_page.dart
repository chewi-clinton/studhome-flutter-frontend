import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:studhome/OnBoardPages/onboard_page1.dart';
import 'package:studhome/OnBoardPages/onboard_page2.dart';
import 'package:studhome/OnBoardPages/onboard_page3.dart';
import 'package:studhome/OnBoardPages/onboard_page4.dart';
import 'package:studhome/constants/app_colors.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            children: [
              OnboardingPage1(),
              OnboardingPage2(),
              OnboardingPage3(),
              OnboardingPage4(),
            ],
          ),
          Container(
            alignment: Alignment(0, 0.81),
            child: SmoothPageIndicator(
              controller: _controller,
              count: 4,
              effect: ScrollingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.lightBackground
                    : AppColors.darkSurface,
                dotHeight: screenWidth * 0.02,
                dotWidth: screenWidth * 0.02,
                spacing: screenWidth * 0.02,
                activeDotScale: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
