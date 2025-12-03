import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';
import '../widgets/app_drawer.dart';

class ProductionCalculatorScreen extends StatefulWidget {
  const ProductionCalculatorScreen({super.key});

  @override
  State<ProductionCalculatorScreen> createState() => _ProductionCalculatorScreenState();
}

class _ProductionCalculatorScreenState extends State<ProductionCalculatorScreen> {
  final SocketService _socketService = SocketService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Контроллеры
  final TextEditingController _prodTypeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _p1Controller = TextEditingController(); // Ширина/Длина
  final TextEditingController _p2Controller = TextEditingController(); // Высота/Толщина

  // Данные для выпадающего списка материалов
  List<Map<String, dynamic>> _materialTypes = [];
  int? _selectedMaterialTypeId;

  // Результат
  int? _calculationResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaterialTypes();
  }

  Future<void> _loadMaterialTypes() async {
    try {
      final response = await _socketService.sendRequest('GET_MATERIAL_TYPES');
      if (response['status'] == 'success') {
        setState(() {
          _materialTypes = List<Map<String, dynamic>>.from(response['data']);
          if (_materialTypes.isNotEmpty) {
            _selectedMaterialTypeId = _materialTypes.first['id'];
          }
        });
      }
    } catch (e) {
      // Тихая обработка ошибки загрузки списка, можно показать SnackBar
    }
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Сброс предыдущих результатов
    setState(() {
      _isLoading = true;
      _calculationResult = null;
      _errorMessage = null;
    });

    final data = {
      'prod_type': int.tryParse(_prodTypeController.text) ?? 0,
      'mat_type': _selectedMaterialTypeId,
      'mat_qty': int.tryParse(_qtyController.text) ?? 0,
      // Заменяем запятые на точки для корректного парсинга double
      'p1': double.tryParse(_p1Controller.text.replaceAll(',', '.')) ?? 0.0,
      'p2': double.tryParse(_p2Controller.text.replaceAll(',', '.')) ?? 0.0,
    };

    try {
      final response = await _socketService.sendRequest('CALCULATE_PRODUCTION', data);
      
      setState(() {
        _isLoading = false;
        if (response['status'] == 'success') {
          // Сервер возвращает поле "result" (int)
          _calculationResult = response['result'];
        } else {
          // Если сервер вернул -1 или другую ошибку
          _errorMessage = "Некорректные данные или ошибка расчёта.";
          if (response['result'] == -1) {
             _errorMessage = "Ошибка: Проверьте параметры (возможно, указаны отрицательные значения или несуществующие типы).";
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Ошибка соединения с сервером";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчёт выпуска продукции'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Блок 1: Исходное сырье ---
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text("Исходное сырье", style: AppTextStyles.header.copyWith(fontSize: 18)),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      DropdownButtonFormField<int>(
                        value: _selectedMaterialTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Тип материала',
                          border: OutlineInputBorder(),
                          helperText: "Выберите материал из справочника",
                        ),
                        items: _materialTypes.map((item) {
                          return DropdownMenuItem<int>(
                            value: item['id'],
                            child: Text(item['title'] ?? 'Материал #${item['id']}'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedMaterialTypeId = val),
                        validator: (val) => val == null ? "Выберите тип" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Количество материала',
                          suffixText: 'ед.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Введите количество";
                          if (int.tryParse(val) == null || int.parse(val) < 0) return "Число >= 0";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Блок 2: Параметры продукции ---
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard_customize_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text("Параметры продукции", style: AppTextStyles.header.copyWith(fontSize: 18)),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      TextFormField(
                        controller: _prodTypeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID Типа продукции',
                          border: OutlineInputBorder(),
                          helperText: "Код из спецификации (например, 1)",
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? "Обязательное поле" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _p1Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Параметр А',
                                hintText: 'Ширина/Вес',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? "Заполните" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _p2Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Параметр Б',
                                hintText: 'Длина/Высота',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? "Заполните" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "* Параметры используются для расчета расхода материала на 1 ед. продукции.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.calculate),
                label: const Text("РАССЧИТАТЬ ВЫПУСК", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),

              // --- Блок результата ---
              if (_calculationResult != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Возможный объем выпуска:", style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        "$_calculationResult шт.",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "(с учетом коэффициента продукции и % брака)",
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}