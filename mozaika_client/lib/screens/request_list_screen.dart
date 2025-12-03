import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/styles.dart';
import 'request_edit_screen.dart'; // Создадим следующим шагом

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final SocketService _socketService = SocketService();
  late Future<List<RequestModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  Future<List<RequestModel>> _fetchRequests() async {
    final response = await _socketService.sendRequest('GET_REQUESTS');
    if (response['status'] == 'success') {
      final List data = response['data'];
      return data.map((json) => RequestModel.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Ошибка загрузки');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final isPartner = user.role == 'partner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<RequestModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Заказов нет'));
          }

          // Фильтрация: Партнер видит только свои заказы
          final allRequests = snapshot.data!;
          final requests = isPartner
              ? allRequests.where((r) => r.partnerId == user.id).toList()
              : allRequests;

          if (requests.isEmpty) {
            return const Center(child: Text('У вас пока нет заказов'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              Color statusColor = Colors.grey;
              if (req.status == 'Новая') statusColor = Colors.blue;
              if (req.status == 'Выполнена') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Заказ №${req.id} от ${req.dateCreated.toString().substring(0, 16)}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Партнер: ${req.partnerName}"),
                      Text("Статус: ${req.status}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      if (req.managerName != 'Не назначен')
                         Text("Менеджер: ${req.managerName}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    // Переход к редактированию/просмотру
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestEditScreen(request: req),
                      ),
                    );
                    _loadRequests();
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
          // Создание нового заказа
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RequestEditScreen(request: null),
            ),
          );
          _loadRequests();
        },
      ),
    );
  }
}