import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/product_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';

// Простая моделька для Dropdown
class ProductType {
  final int id;
  final String title;
  ProductType({required this.id, required this.title});
  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(id: json['id'], title: json['title']);
  }
}

class ProductEditScreen extends StatefulWidget {
  final ProductModel? product; // null = создание

  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocketService _socketService = SocketService();

  late TextEditingController _articleController;
  late TextEditingController _titleController;
  late TextEditingController _costController;
  late TextEditingController _descController;
  late TextEditingController _imageController;

  List<ProductType> _types = [];
  int? _selectedTypeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadTypes();
  }

  void _initControllers() {
    final p = widget.product;
    _articleController = TextEditingController(text: p?.article ?? '');
    _titleController = TextEditingController(text: p?.title ?? '');
    _costController = TextEditingController(text: p?.minCost.toStringAsFixed(2) ?? '0.00');
    _descController = TextEditingController(text: p?.description ?? '');
    _imageController = TextEditingController(text: p?.image ?? '');
    
    if (p != null) {
      _selectedTypeId = p.typeId;
    }
  }

  Future<void> _loadTypes() async {
    try {
      final response = await _socketService.sendRequest('GET_PRODUCT_TYPES');
      if (response['status'] == 'success') {
        final List data = response['data'];
        setState(() {
          _types = data.map((e) => ProductType.fromJson(e)).toList();
          // Если это создание, выбираем первый тип по умолчанию
          if (widget.product == null && _types.isNotEmpty) {
            _selectedTypeId = _types.first.id;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка типов: $e")));
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageController.text = result.files.single.path!;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) return;

    setState(() => _isLoading = true);

    String? base64Image;
    String imageName = _imageController.text;

    // Чтение картинки в base64
    if (imageName.isNotEmpty && !imageName.contains('/') && !imageName.contains('\\')) {
      // Это значит картинка уже с сервера (просто имя файла), не трогаем
    } else if (imageName.isNotEmpty) {
      final file = File(imageName);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
        imageName = imageName.split(Platform.pathSeparator).last;
      }
    }

    final data = {
      'article': _articleController.text,
      'product_name': _titleController.text,
      'product_type_id': _selectedTypeId,
      'min_cost_for_partner': double.parse(_costController.text.replaceAll(',', '.')),
      'description': _descController.text,
      'image': imageName,
      'image_base64': base64Image,
    };

    String action = 'ADD_PRODUCT';
    if (widget.product != null) {
      action = 'UPDATE_PRODUCT';
      data['id'] = widget.product!.id;
    }

    final response = await _socketService.sendRequest(action, data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Ошибка"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.product == null) return;
    
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Удаление"),
        content: const Text("Вы уверены?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Нет")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Да")),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final response = await _socketService.sendRequest('DELETE_PRODUCT', {'id': widget.product!.id});
      setState(() => _isLoading = false);
      
      if (response['status'] == 'success') {
        if (mounted) Navigator.pop(context, true);
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Ошибка удаления"), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Создание продукта' : 'Редактирование'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.product != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   TextFormField(
                    controller: _articleController,
                    decoration: const InputDecoration(labelText: 'Артикул', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Заполните артикул' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Наименование', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Заполните название' : null,
                  ),
                  const SizedBox(height: 16),
                   DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Тип продукции', border: OutlineInputBorder()),
                    items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))).toList(),
                    onChanged: (val) => setState(() => _selectedTypeId = val),
                    validator: (val) => val == null ? 'Выберите тип' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Мин. цена для партнера', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                       if (v!.isEmpty) return 'Обязательно';
                       if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Число';
                       if (double.parse(v.replaceAll(',', '.')) < 0) return 'Не < 0';
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                       Expanded(
                         child: TextFormField(
                           controller: _imageController,
                           decoration: const InputDecoration(labelText: 'Картинка', border: OutlineInputBorder()),
                           readOnly: true,
                         ),
                       ),
                       IconButton(onPressed: _pickImage, icon: const Icon(Icons.folder))
                    ],
                  ),
                  const SizedBox(height: 16),
                   TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      onPressed: _save, 
                      child: Text(widget.product == null ? "СОЗДАТЬ" : "СОХРАНИТЬ")
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}