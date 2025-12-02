import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';

class StaffEditScreen extends StatefulWidget {
  final StaffModel? staff; // Если null -> создание нового

  const StaffEditScreen({super.key, this.staff});

  @override
  State<StaffEditScreen> createState() => _StaffEditScreenState();
}

class _StaffEditScreenState extends State<StaffEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;

  // Общие данные
  late TextEditingController _surnameController;
  late TextEditingController _nameController;
  late TextEditingController _patronymicController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _bankController;
  late TextEditingController _familyController;
  late TextEditingController _healthController;

  // Безопасность
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Должности (упрощено: хардкод, в идеале - запрос GET_POSITIONS)
  int _selectedPositionId = 1;
  final Map<int, String> _positions = {
    1: 'Директор',
    2: 'Менеджер',
    3: 'Мастер',
    4: 'Кладовщик'
  };

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _surnameController = TextEditingController(text: s?.surname ?? '');
    _nameController = TextEditingController(text: s?.name ?? '');
    _patronymicController = TextEditingController(text: s?.patronymic ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _birthDateController = TextEditingController(text: s?.birthDate ?? '2000-01-01');
    _bankController = TextEditingController(text: s?.bankAccount ?? '');
    _familyController = TextEditingController(text: s?.familyStatus ?? '');
    _healthController = TextEditingController(text: s?.healthInfo ?? '');
    
    // Если редактируем, пытаемся установить текущую должность
    if (s != null) _selectedPositionId = s.positionId;
    
    // Если редактируем себя, можно подставить логин/паспорт (если сервер их прислал)
    if (s != null) {
      _loginController.text = s.login;
      _passportController.text = s.passportDetails;
    }
  }

  // --- 1. РЕГИСТРАЦИЯ (Все поля сразу) ---
  Future<void> _registerEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'surname': _surnameController.text,
      'name': _nameController.text,
      'patronymic': _patronymicController.text,
      'position_id': _selectedPositionId,
      'birth_date': _birthDateController.text,
      'phone': _phoneController.text,
      'bank_account': _bankController.text,
      'family_status': _familyController.text,
      'health_info': _healthController.text,
      // Чувствительные данные обязательны при создании
      'passport_details': _passportController.text,
      'login': _loginController.text,
      'password': _passwordController.text,
    };

    final response = await _socketService.sendRequest('REGISTER_EMPLOYEE', data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Сотрудник создан"), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) _showError(response['message'] ?? "Ошибка регистрации");
    }
  }

  // --- 2. ОБНОВЛЕНИЕ ОБЩИХ ДАННЫХ ---
  Future<void> _updateGeneral() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'id': widget.staff!.id,
      'surname': _surnameController.text,
      'name': _nameController.text,
      'patronymic': _patronymicController.text,
      'position_id': _selectedPositionId,
      'birth_date': _birthDateController.text,
      'phone': _phoneController.text,
      'bank_account': _bankController.text,
      'family_status': _familyController.text,
      'health_info': _healthController.text,
    };

    final response = await _socketService.sendRequest('UPDATE_EMPLOYEE_DATA', data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Общие данные обновлены"), backgroundColor: Colors.green));
    } else {
      if (mounted) _showError("Ошибка обновления");
    }
  }

  // --- 3. ОБНОВЛЕНИЕ БЕЗОПАСНОСТИ (Только свои) ---
  Future<void> _updateSecurity() async {
    setState(() => _isLoading = true);
    final data = {
      'id': widget.staff!.id,
      'login': _loginController.text.trim(),
      'password': _passwordController.text.trim(),
      'passport_details': _passportController.text.trim(),
    };
    final response = await _socketService.sendRequest('UPDATE_STAFF_SECURITY', data);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Данные безопасности обновлены"), backgroundColor: Colors.green));
        _passwordController.clear(); // Очистить пароль после сохранения
      }
    } else {
      if (mounted) _showError("Ошибка обновления безопасности");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.staff == null;
    final currentUser = context.read<UserProvider>();
    // Проверка: это я сам?
    final isSelf = !isCreating && (currentUser.id == widget.staff!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? 'Новый сотрудник' : 'Карточка сотрудника'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Личные данные", style: AppTextStyles.header.copyWith(fontSize: 18)),
                    const SizedBox(height: 10),
                    
                    _buildTextField(_surnameController, "Фамилия"),
                    _buildTextField(_nameController, "Имя"),
                    _buildTextField(_patronymicController, "Отчество"),
                    
                    DropdownButtonFormField<int>(
                      initialValue: _selectedPositionId,
                      decoration: const InputDecoration(labelText: 'Должность', border: OutlineInputBorder()),
                      items: _positions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (val) => setState(() => _selectedPositionId = val!),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(_birthDateController, "Дата рождения (YYYY-MM-DD)"),
                    _buildTextField(_phoneController, "Телефон", isPhone: true),
                    _buildTextField(_bankController, "Номер счета"),
                    _buildTextField(_familyController, "Семейное положение"),
                    _buildTextField(_healthController, "Сведения о здоровье"),

                    // Если создаем - кнопка создания (со всеми полями ниже)
                    // Если редактируем - кнопка "Сохранить общие"
                    if (!isCreating) ...[
                       const SizedBox(height: 10),
                       ElevatedButton(
                         onPressed: _updateGeneral,
                         style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                         child: const Text("СОХРАНИТЬ ОБЩИЕ ДАННЫЕ"),
                       ),
                    ],

                    const SizedBox(height: 30),

                    // --- БЛОК БЕЗОПАСНОСТИ ---
                    // Виден, если СОЗДАЕМ или ЕСЛИ РЕДАКТИРУЕМ СЕБЯ
                    if (isCreating || isSelf) ...[
                       const Divider(thickness: 2),
                       Text(
                         isCreating ? "Безопасность и Документы" : "Мои данные безопасности", 
                         style: AppTextStyles.header.copyWith(fontSize: 18, color: Colors.red[700])
                       ),
                       if (isSelf) const Text("Эти данные видите и можете менять только вы.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                       const SizedBox(height: 10),

                       _buildTextField(_passportController, "Паспортные данные"),
                       _buildTextField(_loginController, isCreating ? "Логин" : "Новый логин"),
                       _buildTextField(_passwordController, isCreating ? "Пароль" : "Новый пароль"),

                       const SizedBox(height: 10),
                       
                       if (isCreating)
                          ElevatedButton(
                            onPressed: _registerEmployee,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                            child: const Text("ЗАРЕГИСТРИРОВАТЬ СОТРУДНИКА"),
                          )
                       else
                          ElevatedButton(
                            onPressed: _updateSecurity,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                            child: const Text("ОБНОВИТЬ БЕЗОПАСНОСТЬ"),
                          ),
                    ] else ...[
                       // Если редактируем чужого
                       const Divider(),
                       const Center(child: Text("Данные безопасности (паспорт, вход) доступны только самому сотруднику.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                    ]
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) {
           // При создании проверяем всё, при редактировании безопасности можно пропускать пустые пароли
           if (widget.staff == null && (val == null || val.isEmpty)) return "Обязательно";
           // При редактировании общих данных:
           if (widget.staff != null && (val == null || val.isEmpty)) {
              // Если это поля безопасности и мы редактируем - они могут быть пустыми (не менять)
              if (label.contains("Новый") || label.contains("Паспорт")) return null;
              return "Обязательно";
           }
           return null;
        },
      ),
    );
  }
}