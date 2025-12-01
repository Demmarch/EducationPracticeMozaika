import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/material_list_screen.dart';
import '../screens/product_list_screen.dart';
import '../utils/styles.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Drawer(
      child: Column(
        children: [
          // Шапка с информацией о пользователе
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              user.name ?? "Гость",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              user.role == 'manager' ? "Менеджер / Сотрудник" : "Партнер",
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name != null && user.name!.isNotEmpty ? user.name![0] : "A",
                style: const TextStyle(fontSize: 24, color: AppColors.primary),
              ),
            ),
          ),
          
          // Пункты меню
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _createDrawerItem(
                  context: context,
                  icon: Icons.inventory_2,
                  text: 'Материалы',
                  targetScreen: const MaterialListScreen(),
                ),
                _createDrawerItem(
                  context: context,
                  icon: Icons.shopping_bag,
                  text: 'Продукция',
                  targetScreen: const ProductListScreen(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Выйти", style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<UserProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Widget targetScreen,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(text),
      onTap: () {
        // Закрываем меню
        Navigator.pop(context);
        
        // Переходим на новый экран с заменой текущего (чтобы не растить стек)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
    );
  }
}