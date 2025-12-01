import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';

class SupplierListScreen extends StatefulWidget {
  final int materialId;
  final String materialTitle; // Передаем название, чтобы показать в заголовке

  const SupplierListScreen({
    super.key,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final SocketService _socketService = SocketService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _suppliers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(widget.materialId);
    final response = await _socketService.sendRequest('GET_SUPPLIERS', {
      'material_id': widget.materialId,
    });

    if (!mounted) return;
    print(response);
    if (response['status'] == 'success') {
      setState(() {
        _suppliers = List<Map<String, dynamic>>.from(response['data']);
        print(response['data']);
        print(_suppliers);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'Не удалось загрузить поставщиков';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Отображаем название материала в заголовке для удобства
        title: Text(
          'Поставщики: ${widget.materialTitle}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadSuppliers,
              child: const Text('Повторить'),
            )
          ],
        ),
      );
    }

    if (_suppliers.isEmpty) {
      return const Center(
        child: Text(
          'Для этого материала нет поставщиков',
          style: AppTextStyles.label,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _suppliers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
        final name = supplier['name'] ?? 'Неизвестный поставщик';
        final type = supplier['type'] ?? '';
        final date = supplier['start_date'] ?? '-';

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка карточки: Имя и Тип
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "$type | $name",
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                
                // Дата начала работы
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "Дата начала работы: $date",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}