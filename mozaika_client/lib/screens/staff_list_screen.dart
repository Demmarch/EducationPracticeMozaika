import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/styles.dart';
import 'staff_edit_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final SocketService _socketService = SocketService();
  late Future<List<StaffModel>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    setState(() {
      _staffFuture = _fetchStaff();
    });
  }

  Future<List<StaffModel>> _fetchStaff() async {
    final response = await _socketService.sendRequest('GET_EMPLOYEES');
    if (response['status'] == 'success') {
      final List data = response['data'];
      return data.map((json) => StaffModel.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Ошибка');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Проверка доступа: Партнеры не должны видеть этот экран
    final userRole = context.watch<UserProvider>().role;
    if (userRole == 'partner') {
      return const Scaffold(
        body: Center(child: Text("Доступ запрещен")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<StaffModel>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Нет сотрудников'));

          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final staff = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Text(staff.surname.isNotEmpty ? staff.surname[0] : "?", style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${staff.positionName} | ${staff.phone}"),
                  onTap: () async {
                    // Переход к редактированию (доступно всем сотрудникам)
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StaffEditScreen(staff: staff)),
                    );
                    _loadStaff();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffEditScreen(staff: null)),
          );
          if (result == true) _loadStaff();
        },
      ),
    );
  }
}