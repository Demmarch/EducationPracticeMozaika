import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partner_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';

class PartnerEditScreen extends StatefulWidget {
  final PartnerModel? partner;

  const PartnerEditScreen({super.key, required this.partner});

  @override
  State<PartnerEditScreen> createState() => _PartnerEditScreenState();
}

class _PartnerEditScreenState extends State<PartnerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;

  int _selectedTypeId = 1;
  final Map<int, String> _partnerTypes = {
    1: 'ООО',
    2: 'ЗАО',
    3: 'ПАО',
    4: 'ИП'
  };

  // Контроллеры общих данных
  late TextEditingController _nameController;
  late TextEditingController _directorController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _ratingController;

  // Контроллеры безопасности (только для Партнера)
  late TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TextEditingController _innController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.partner;
    _nameController = TextEditingController(text: p?.name);
    _directorController = TextEditingController(text: p?.director);
    _phoneController = TextEditingController(text: p?.phone);
    _emailController = TextEditingController(text: p?.email);
    _addressController = TextEditingController(text: p?.address); 
    _ratingController = TextEditingController(text: p?.rating.toString());
    _innController = TextEditingController(text: p?.inn);
    _loginController = TextEditingController(text: p?.login);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _directorController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _ratingController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _innController.dispose();
    super.dispose();
  }

  Future<void> _createPartner() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Собираем JSON для struct Partner::fromJson на сервере
    final data = {
      'partner_name': _nameController.text,
      'director_name': _directorController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'legal_address': _addressController.text,
      'inn': _innController.text, // Обязательно при регистрации
      'partner_type_id': _selectedTypeId, // ID типа
      'login': _loginController.text,
      'password': _passwordController.text,
      'rating': int.tryParse(_ratingController.text) ?? 0,
      'logo': '',
      'sales_locations': ''
    };

    // Отправляем команду REGISTER_PARTNER
    final response = await _socketService.sendRequest('REGISTER_PARTNER', data);
    
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Партнер успешно зарегистрирован"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Возвращаемся и обновляем список
      }
    } else {
      if (mounted) _showMessage(response['message'] ?? "Ошибка регистрации", AppColors.error);
    }
  }

  // Сохранение общих данных
  Future<void> _saveGeneralData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'id': widget.partner?.id,
      'partner_name': _nameController.text,
      'director_name': _directorController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'legal_address': _addressController.text,
      'rating': int.tryParse(_ratingController.text) ?? 0,
    };

    final response = await _socketService.sendRequest('UPDATE_PARTNER_DATA', data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) _showMessage("Данные обновлены", Colors.green);
    } else {
      if (mounted) _showMessage(response['message'] ?? "Ошибка обновления", AppColors.error);
    }
  }

  // Сохранение чувствительной инф-ции (Только Партнер)
  Future<void> _saveSecurityData() async {
    setState(() => _isLoading = true);

    final data = {
      'id': widget.partner?.id,
      'login': _loginController.text.trim(),
      'password': _passwordController.text.trim(),
      'inn': _innController.text.trim(),
    };

    final response = await _socketService.sendRequest('UPDATE_PARTNER_SECURITY', data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      // Очищаем поля безопасности после успешной смены
      _loginController.clear();
      _passwordController.clear();
      _innController.clear();
      if (mounted) _showMessage("Данные безопасности обновлены", Colors.green);
    } else {
      if (mounted) _showMessage(response['message'] ?? "Ошибка обновления безопасности", AppColors.error);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.partner == null;
    final userRole = context.read<UserProvider>().role;
    // Определяем права:
    // Менеджер может всё в общем блоке.
    // Партнер может всё в общем блоке, кроме Рейтинга (обычно рейтинг ставит менеджер).
    final isManager = userRole == 'manager';
    final isPartner = userRole == 'partner';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? 'Новый партнер' :'Редактирование: ${widget.partner?.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Общие данные
                  Text(
                    isCreating ? "Регистрация партнера" : "Основная информация",
                    style: AppTextStyles.header.copyWith(fontSize: 20)
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (isCreating) 
                          DropdownButtonFormField<int>(
                          initialValue: _selectedTypeId,
                          decoration: const InputDecoration(labelText: 'Тип партнера', border: OutlineInputBorder()),
                          items: _partnerTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                          onChanged: (val) => setState(() => _selectedTypeId = val!),
                        ),
                        if (isCreating) const SizedBox(height: 12),
                        _buildTextField(_nameController, "Название партнера"),
                        _buildTextField(_directorController, "ФИО Директора"),
                        _buildTextField(_phoneController, "Телефон", isPhone: true),
                        _buildTextField(_emailController, "Email"),
                        _buildTextField(_addressController, "Юридический адрес"),
                        if (!isCreating)
                         _buildTextField(_ratingController, "Рейтинг", isNumber: true, readOnly: !isManager),

                        // --- ПОЛЯ БЕЗОПАСНОСТИ ПРИ СОЗДАНИИ ---
                        // При регистрации они обязательны и находятся в той же форме
                        if (isCreating) ...[
                          const SizedBox(height: 10),
                          const Text("Данные для входа и реквизиты", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _buildTextField(_innController, "ИНН", isNumber: true),
                          _buildTextField(_loginController, "Логин"),
                          _buildTextField(_passwordController, "Пароль"),
                        ],
                        const SizedBox(height: 10),
                        if (isCreating)
                          ElevatedButton(
                            onPressed: _createPartner,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text("ЗАРЕГИСТРИРОВАТЬ ПАРТНЕРА"),
                          )
                        else 
                          ElevatedButton(
                            onPressed: _saveGeneralData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          child: const Text("СОХРАНИТЬ ОБЩИЕ ДАННЫЕ"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Важные данные (Только для Партнера)
                  if (!isCreating && isPartner) ...[
                    const Divider(thickness: 2),
                    const SizedBox(height: 10),
                    Text(
                      "Безопасность и доступ", 
                      style: AppTextStyles.header.copyWith(fontSize: 20, color: Colors.red[700])
                    ),
                    const Text(
                      "Заполните только те поля, которые хотите изменить. Оставьте пустыми, чтобы сохранить текущие значения.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_loginController, "Новый логин"),
                    _buildTextField(_passwordController, "Новый пароль"),
                    _buildTextField(_innController, "Новый ИНН"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _saveSecurityData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("ОБНОВИТЬ ДАННЫЕ ДОСТУПА"),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    {bool isNumber = false, bool isPhone = false, bool readOnly = false}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : (isPhone ? TextInputType.phone : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
        ),
        validator: (val) {
          if (widget.partner == null && (val == null || val.isEmpty)) return 'Поле обязательно';
          if (widget.partner != null && !readOnly && (val == null || val.isEmpty) && 
              label != "Новый логин" && label != "Новый пароль" && label != "Новый ИНН") {
            return 'Поле обязательно';
          }
          return null;
        },
      ),
    );
  }
}