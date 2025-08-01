import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/home_screen.dart';
import 'shared/themes/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AutoBodyRepairApp(),
    ),
  );
}

class AutoBodyRepairApp extends StatelessWidget {
  const AutoBodyRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Body Repair Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}