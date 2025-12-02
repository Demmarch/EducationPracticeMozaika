import 'package:flutter/material.dart';
import '../models/partner_model.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../widgets/partner_card.dart';
import '../widgets/app_drawer.dart';
import '../utils/styles.dart';
import 'partner_edit_screen.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  final SocketService _socketService = SocketService();
  late Future<List<PartnerModel>> _partnersFuture;
  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  void _loadPartners() {
    setState(() {
      _partnersFuture = _fetchPartners();
    });
  }

  Future<List<PartnerModel>> _fetchPartners() async {
    final response = await _socketService.sendRequest('GET_PARTNERS');
    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'];
      return data.map((json) => PartnerModel.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Ошибка загрузки');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserProvider>().role;
    final isManager = userRole == 'manager';
    final userId = context.watch<UserProvider>().id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Партнеры'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<PartnerModel>>(
        future: _partnersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Список партнеров пуст'));
          }

          final partners = snapshot.data!;
          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              return PartnerCard(
                partner: partner,
                onTap: () async {
                  if (isManager || (userId == partner.id)) {
                    await Navigator.push(
                      context, MaterialPageRoute(builder: (context) => PartnerEditScreen(partner: partner))
                    ).then((_) => _loadPartners());
                  }                  
                },
              );
            },
          );
        },
      ),
      floatingActionButton: isManager ?
      FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () async {
          // Переходим на экран редактирования, но без партнера (создание)
          final result = await Navigator.push(
             context,
             MaterialPageRoute(
                builder: (context) => const PartnerEditScreen(partner: null),
              ),
            );

            // Если вернулось true (успешное создание), обновляем список
            if (result == true) {
             _loadPartners();
            }
        },
      ) : null, 
    );
  }
}