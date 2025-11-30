import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';
// Импорт экрана, который мы создадим следующим (список материалов)
import 'material_list_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Контроллеры для полей ввода
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Состояние загрузки (крутилка)
  bool _isLoading = false;
  final SocketService _socketService = SocketService();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Метод входа
  Future<void> _login() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      _showError('Пожалуйста, заполните все поля');
      return;
    }

    setState(() => _isLoading = true);

    // 1. Отправляем запрос на сервер
    final response = await _socketService.sendRequest('LOGIN', {
      'login': login,
      'password': password,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    // 2. Проверяем ответ
    if (response['status'] == 'success') {
      // 3. Сохраняем данные пользователя в Provider
      final role = response['role']; // "manager" или "partner"
      final name = response['username'];
      final id = response['user_id'];
      
      context.read<UserProvider>().setUser(id, role, name);

      // 4. Навигация в зависимости от роли
      // Пока направим всех на список материалов, но логику можно разделить
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MaterialListScreen()),
      );
    } else {
      // Ошибка авторизации
      _showError(response['message'] ?? 'Ошибка авторизации');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Логотип (пока иконка, можно заменить на Image.asset) [cite: 72]
                const Icon(
                  Icons.grid_view_rounded, // Похоже на мозаику
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'МОЗАИКА',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.header,
                ),
                const SizedBox(height: 32),
                
                // Поле Логина
                TextField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Пароля
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Кнопка Входа
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ВОЙТИ', style: TextStyle(fontSize: 18)),
                  ),
                ),
                
                // Ссылка на регистрацию (для Партнеров)
                TextButton(
                  onPressed: () {
                    // TODO: Переход на экран регистрации
                    _showError("Функция регистрации в разработке");
                  },
                  child: const Text('Стать партнером'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}