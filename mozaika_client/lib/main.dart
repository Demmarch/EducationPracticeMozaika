import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'utils/styles.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MozaikaApp(),
    ),
  );
}

class MozaikaApp extends StatelessWidget {
  const MozaikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mozaika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const LoginScreen(),
    );
  }
}