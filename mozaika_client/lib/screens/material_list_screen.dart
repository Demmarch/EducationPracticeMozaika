import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../utils/styles.dart';
import 'login_screen.dart';

class MaterialListScreen extends StatelessWidget {
  const MaterialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем данные о пользователе
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список материалов'), // Заголовок по заданию [cite: 53]
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Выход из системы
              context.read<UserProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Добро пожаловать, ${user.name}!', style: AppTextStyles.label),
            Text('Ваша роль: ${user.role}'),
            const SizedBox(height: 20),
            const Text('Здесь будет список материалов...'),
          ],
        ),
      ),
    );
  }
}