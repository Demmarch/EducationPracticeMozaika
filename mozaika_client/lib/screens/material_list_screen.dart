import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';
import '../widgets/material_card.dart';
import '../widgets/app_drawer.dart';
import 'material_edit_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final SocketService _socketService = SocketService();
  
  // Future для загрузки данных (используем FutureBuilder)
  late Future<List<MaterialModel>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    // Инициализируем загрузку
    setState(() {
      _materialsFuture = _fetchMaterials();
    });
  }

  Future<List<MaterialModel>> _fetchMaterials() async {
    // Отправляем команду GET_MATERIALS на сервер
    final response = await _socketService.sendRequest('GET_MATERIALS');
    
    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'];
      // Превращаем JSON массив в список объектов MaterialModel
      return data.map((json) => MaterialModel.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Ошибка загрузки');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список материалов'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Поле поиска можно добавить позже, если останется время
          
          Expanded(
            child: FutureBuilder<List<MaterialModel>>(
              future: _materialsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Материалы не найдены'));
                }

                final materials = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return MaterialCard(
                      material: material,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaterialEditScreen(material: material),
                          ),
                        );

                        // Если вернулось true, обновляем список
                        if (result == true) {
                          _loadMaterials();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Кнопка добавления нового материала (Модуль 3)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
              final result = await Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => MaterialEditScreen(material: null),
              ),
            );

          // Если вернулось true, обновляем список
          if (result == true) {
            _loadMaterials();
          }
        },
      ),
    );
  }
}