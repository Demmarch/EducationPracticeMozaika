import 'package:flutter/material.dart';
import 'package:mozaika_client/models/staff_model.dart';
import 'package:mozaika_client/screens/staff_edit_screen.dart';
import 'package:mozaika_client/screens/staff_list_screen.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/material_list_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/partner_list_screen.dart';
import '../screens/partner_edit_screen.dart';
import '../models/partner_model.dart';
import '../services/socket_service.dart';
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
          
          // Мой профиль для сотрудника
          if (user.role == 'manager')
            ListTile(
              leading: const Icon(Icons.account_circle, color: AppColors.primary),
              title: const Text('Мой профиль'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final socket = SocketService();
                  final response = await socket.sendRequest('GET_EMPLOYEES');
                  if (response['status'] == 'success') {
                     final List data = response['data'];
                     // Ищем по ID
                     final myData = data.firstWhere((json) => json['id'] == user.id, orElse: () => null);

                     if (myData != null && context.mounted) {
                       final staffModel = StaffModel.fromJson(myData);
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => StaffEditScreen(staff: staffModel)),
                       );
                     }
                  }
                } catch (e) {
                  print(e);
                }
              },
            ),
          
          if (user.role == 'manager')
            _createDrawerItem(
              context: context,
              icon: Icons.badge,
              text: 'Сотрудники',
              targetScreen: const StaffListScreen(), // Не забудьте импорт
            ),

          
          if (user.role == 'partner')
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('Мой профиль'),
              onTap: () async {
                Navigator.pop(context); // Закрыть меню
                try {
                  final socket = SocketService();
                  // Запрашиваем всех партнеров (так как API отдает список)
                  final response = await socket.sendRequest('GET_PARTNERS');
        
                  if (response['status'] == 'success') {
                    final List data = response['data'];
                    // Ищем себя по ID
                    final myData = data.firstWhere(
                      (json) => json['id'] == user.id, 
                      orElse: () => null
                    );

                    if (myData != null && context.mounted) {
                      final partnerModel = PartnerModel.fromJson(myData);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartnerEditScreen(partner: partnerModel),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ошибка загрузки профиля")),
                      );
                  }
                }
              } catch (e) {
                print(e);
              }
            },
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
                _createDrawerItem(
                  context: context,
                  icon: Icons.people,
                  text: 'Партнеры',
                  targetScreen: PartnerListScreen()
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