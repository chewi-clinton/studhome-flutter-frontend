import 'package:flutter/material.dart';

import 'package:studhome/constants/app_colors.dart';
import 'package:studhome/first_page.dart';

ValueNotifier<bool> isDarkMode = ValueNotifier(false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  isDarkMode.value = (brightness == Brightness.dark);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudHome',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            dividerColor: Colors.grey,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.black,
            cardColor: Colors.grey[900],
            dividerColor: Colors.grey[700],
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const FirstPage(),
        );
      },
    );
  }
}
