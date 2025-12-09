import 'package:flutter/material.dart';
import 'package:myapp/app_colors.dart';
import 'package:myapp/database.dart';
import 'package:myapp/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AppDatabase>(
      create: (context) => AppDatabase(),
      dispose: (context, db) => db.close(),
      child: MaterialApp(
        title: 'Finance App',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            surface: AppColors.background,
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.text),
            bodyMedium: TextStyle(color: AppColors.text),
            titleLarge: TextStyle(color: AppColors.text),
            headlineSmall: TextStyle(color: AppColors.text),
            headlineMedium: TextStyle(color: AppColors.text),
            headlineLarge: TextStyle(color: AppColors.text),
            displaySmall: TextStyle(color: AppColors.text),
            displayMedium: TextStyle(color: AppColors.text),
            displayLarge: TextStyle(color: AppColors.text),
          ),
          cardTheme: const CardThemeData(
            color: AppColors.card,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: AppColors.primary,
            selectedItemColor: AppColors.textOnPrimary,
            unselectedItemColor: AppColors.textOnPrimary.withAlpha(153),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
