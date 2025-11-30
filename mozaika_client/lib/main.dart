import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'utils/styles.dart';
// Импортируй будущий экран логина (пока закомментируй или создай заглушку)
// import 'screens/login_screen.dart'; 

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
      title: 'Mozaika ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      // Пока поставим заглушку, на следующем шаге заменим на LoginScreen
      home: const Scaffold(
        body: Center(child: Text("Загрузка...")),
      ),
    );
  }
}