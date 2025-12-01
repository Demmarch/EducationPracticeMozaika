import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/material_model.dart';
import '../models/material_type_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';
import 'suppliers_screen.dart';

class MaterialEditScreen extends StatefulWidget {
  final MaterialModel? material; // Если null, то это создание нового

  const MaterialEditScreen({super.key, this.material});

  @override
  State<MaterialEditScreen> createState() => _MaterialEditScreenState();
}

class _MaterialEditScreenState extends State<MaterialEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocketService _socketService = SocketService();

  // Контроллеры
  late TextEditingController _titleController;
  late TextEditingController _countController;
  late TextEditingController _unitController;
  late TextEditingController _packQtyController;
  late TextEditingController _minCountController;
  late TextEditingController _costController;
  late TextEditingController _descController;
  late TextEditingController _imageController;

  // Данные для выпадающего списка
  List<MaterialType> _types = [];
  int? _selectedTypeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadTypes();
  }

  void _initControllers() {
    final m = widget.material;
    _titleController = TextEditingController(text: m?.title ?? '');
    _countController = TextEditingController(text: m?.currentQuantity.toString() ?? '0');
    _unitController = TextEditingController(text: m?.unit ?? 'шт');
    _packQtyController = TextEditingController(text: m?.countInPack.toString() ?? '1');
    _minCountController = TextEditingController(text: m?.minCount.toString() ?? '0');
    _costController = TextEditingController(text: m?.cost.toStringAsFixed(2) ?? '0.00');
    _descController = TextEditingController(text: m?.description ?? '');
    _imageController = TextEditingController(text: m?.image ?? '');
  }

  Future<void> _pickImage() async {
    // Открываем диалог выбора файлов, фильтруем только изображения
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      // Получаем путь к выбранному файлу
      final String path = result.files.single.path!;
      
      setState(() {
        // Записываем путь в контроллер, чтобы он отобразился в поле
        _imageController.text = path;
      });
    }
  }

  Future<void> _loadTypes() async {
    try {
      final response = await _socketService.sendRequest('GET_MATERIAL_TYPES');
      if (response['status'] == 'success') {
        final List data = response['data'];
        setState(() {
          _types = data.map((e) => MaterialType.fromJson(e)).toList();
          
          // Если редактируем, пытаемся найти ID типа по названию (или сервер должен присылать ID)
          // Упрощение: сервер в Module 2 присылает type_name. 
          // Чтобы выставить dropdown корректно, нам нужен ID.
          // Если в MaterialModel нет typeId, то dropdown будет пустым при редактировании.
          // Для экзамена часто достаточно, чтобы пользователь выбрал тип заново или 
          // доработать сервер, чтобы он слал type_id в GET_MATERIALS.
          
          if (widget.material != null && _types.isNotEmpty) {
             // Пытаемся найти тип по названию
             final found = _types.where((t) => t.title == widget.material!.type);
             if (found.isNotEmpty) {
               _selectedTypeId = found.first.id;
             }
          } else if (_types.isNotEmpty) {
            _selectedTypeId = _types.first.id; // Выбор по умолчанию для нового
          }
        });
      }
    } catch (e) {
      _showError("Ошибка загрузки типов: $e");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      _showError("Выберите тип материала");
      return;
    }

    setState(() => _isLoading = true);

    String? base64Image;
    String imageName = _imageController.text;

    // Логика подготовки изображения
    if (imageName.isNotEmpty) {
      final file = File(imageName);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          base64Image = base64Encode(bytes);
          // Из пути 'C:\Folder\pic.jpg' берем только 'pic.jpg' для удобства имени
          imageName = imageName.split(Platform.pathSeparator).last;
        } catch (e) {
          _showError("Ошибка чтения файла изображения: $e");
          setState(() => _isLoading = false);
          return;
        }
      }
    }

    final data = {
      'material_name': _titleController.text,
      'material_type_id': _selectedTypeId,
      'current_quantity': int.parse(_countController.text),
      'unit': _unitController.text,
      'count_in_pack': int.parse(_packQtyController.text),
      'min_count': int.parse(_minCountController.text),
      'cost': double.parse(_costController.text.replaceAll(',', '.')), // Замена запятой на точку
      'description': _descController.text,
      'image': _imageController.text,
      'image_base64': base64Image,
    };

    String action = 'ADD_MATERIAL';
    if (widget.material != null) {
      action = 'UPDATE_MATERIAL';
      data['id'] = widget.material?.id;
    }

    final response = await _socketService.sendRequest(action, data);

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Успешно сохранено"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true); // Возвращаем true, чтобы обновить список
      }
    } else {
      _showError(response['message'] ?? "Ошибка сохранения");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // Вспомогательный метод для полей
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    bool allowDecimal = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [
                allowDecimal
                    ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    : FilteringTextInputFormatter.digitsOnly
              ]
            : [],
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) return 'Поле обязательно';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.material != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактирование материала' : 'Добавление материала'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Поле Наименования
                  _buildTextField(controller: _titleController, label: 'Наименование материала'),

                  // Выпадающий список Типов
                  DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Тип материала',
                      border: OutlineInputBorder(),
                    ),
                    items: _types.map((t) {
                      return DropdownMenuItem<int>(value: t.id, child: Text(t.title));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTypeId = val),
                    validator: (val) => val == null ? 'Выберите тип' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _countController, 
                          label: 'Кол-во на складе', 
                          isNumber: true
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _unitController, 
                          label: 'Ед. измерения'
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _minCountController, 
                          label: 'Мин. количество', 
                          isNumber: true,
                          // Задание: "Минимальное количество материала не может принимать отрицательные значения."
                          validator: (val) {
                             if (val == null || val.isEmpty) return 'Обязательно';
                             if (int.tryParse(val) == null) return 'Число';
                             if (int.parse(val) < 0) return 'Не может быть < 0';
                             return null;
                          }
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _packQtyController, 
                          label: 'В упаковке', 
                          isNumber: true
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(
                    controller: _costController, 
                    label: 'Цена за единицу', 
                    isNumber: true, 
                    allowDecimal: true,
                    // Задание: "Цена материала... не может быть отрицательной."
                    validator: (val) {
                       if (val == null || val.isEmpty) return 'Обязательно';
                       final v = double.tryParse(val.replaceAll(',', '.'));
                       if (v == null) return 'Неверный формат';
                       if (v < 0) return 'Цена не может быть < 0';
                       return null;
                    }
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageController,
                            decoration: const InputDecoration(
                              labelText: 'Изображение',
                              border: OutlineInputBorder(),
                              hintText: 'Выберите файл...',
                            ),
                            readOnly: true, // Запрещаем ручной ввод, чтобы не ошибиться в пути
                            validator: (v) => null, // Поле необязательное
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.folder_open),
                          label: const Text("Выбрать"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildTextField(
                    controller: _descController, 
                    label: 'Описание',
                    validator: (v) => null
                  ),
                  if (widget.material != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text("Список поставщиков"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Можно сделать отличающийся стиль
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => SupplierListScreen(
                              materialId: widget.material!.id,
                              materialTitle: widget.material!.title,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _save,
                    child: Text(isEdit ? 'СОХРАНИТЬ ИЗМЕНЕНИЯ' : 'ДОБАВИТЬ МАТЕРИАЛ'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}