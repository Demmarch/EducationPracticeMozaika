import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../models/product_model.dart';
import '../models/partner_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/styles.dart';

class RequestEditScreen extends StatefulWidget {
  final RequestModel? request;

  const RequestEditScreen({super.key, this.request});

  @override
  State<RequestEditScreen> createState() => _RequestEditScreenState();
}

class _RequestEditScreenState extends State<RequestEditScreen> {
  final SocketService _socketService = SocketService();
  bool _isLoading = false;

  List<RequestItemModel> _items = [];
  String _status = 'Новая';
  int? _selectedPartnerId;
  String? _selectedPartnerName;
  
  // Добавляем переменную для хранения скидки
  int _currentDiscount = 0; 

  List<PartnerModel> _partnersList = [];
  final List<String> _statuses = ['Новая', 'Ожидает оплаты', 'В производстве', 'Готова', 'Выполнена'];

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _status = widget.request!.status;
      _selectedPartnerId = widget.request!.partnerId;
      _selectedPartnerName = widget.request!.partnerName;
      _loadItems(widget.request!.id);
      
      // При редактировании существующего заказа неплохо бы подгрузить скидку партнера,
      // чтобы новые добавленные товары считались с ней.
      _loadPartnerDiscountInfo();
    } else {
      _initNewOrder();
    }
  }

  void _initNewOrder() {
    final user = context.read<UserProvider>();
    if (user.role == 'partner') {
      _selectedPartnerId = user.id;
      _selectedPartnerName = user.name;
      // Даже если это сам партнер, нам нужно загрузить его данные, чтобы узнать скидку (в UserProvider её нет)
      _loadPartnerDiscountInfo();
    } else {
      _loadPartners(); // Загрузка списка для менеджера
    }
  }

  // Метод для подгрузки скидки (используется и партнером, и при редактировании)
  Future<void> _loadPartnerDiscountInfo() async {
    if (_selectedPartnerId == null) return;
    
    // Используем общий метод получения партнеров, так как там рассчитывается скидка
    final response = await _socketService.sendRequest('GET_PARTNERS');
    if (response['status'] == 'success') {
      final List data = response['data'];
      final partners = data.map((e) => PartnerModel.fromJson(e)).toList();
      
      try {
        final currentPartner = partners.firstWhere((p) => p.id == _selectedPartnerId);
        setState(() {
          _currentDiscount = currentPartner.discount;
        });
      } catch (e) {
        // Партнер не найден
      }
    }
  }

  Future<void> _loadPartners() async {
    final response = await _socketService.sendRequest('GET_PARTNERS');
    if (response['status'] == 'success') {
      final List data = response['data'];
      setState(() {
        _partnersList = data.map((e) => PartnerModel.fromJson(e)).toList();
        
        // Выбор по умолчанию
        if (_partnersList.isNotEmpty && _selectedPartnerId == null) {
          _selectedPartnerId = _partnersList.first.id;
          _currentDiscount = _partnersList.first.discount; // Сразу ставим скидку первого
        }
      });
    }
  }

  Future<void> _loadItems(int requestId) async {
    setState(() => _isLoading = true);
    final response = await _socketService.sendRequest('GET_REQUEST_ITEMS', {'request_id': requestId});
    setState(() => _isLoading = false);
    
    if (response['status'] == 'success') {
      final List data = response['data'];
      setState(() {
        _items = data.map((e) => RequestItemModel.fromJson(e)).toList();
      });
    }
  }

  double get _totalCost {
    double sum = 0;
    for (var item in _items) {
      sum += item.actualPrice * item.quantity;
    }
    return sum;
  }

  // Диалог добавления товара
  void _showAddProductDialog() async {
    List<ProductModel> products = [];
    try {
      final response = await _socketService.sendRequest('GET_PRODUCTS');
      if (response['status'] == 'success') {
        products = (response['data'] as List).map((e) => ProductModel.fromJson(e)).toList();
      }
    } catch (e) {
      return;
    }

    if (!mounted) return;
    
    ProductModel? selectedProduct = products.isNotEmpty ? products.first : null;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    // Вспомогательная функция для пересчета цены с учетом скидки
    void updatePrice() {
      if (selectedProduct != null) {
        double basePrice = selectedProduct!.minCost;
        // --- ПРИМЕНЕНИЕ СКИДКИ ---
        double discounted = basePrice;
        if (_currentDiscount > 0) {
          discounted = basePrice * (1 - _currentDiscount / 100.0);
        }
        priceController.text = discounted.toStringAsFixed(2);
      }
    }

    // Инициализируем цену при открытии
    updatePrice();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Добавить товар"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Отображаем информацию о скидке
                    if (_currentDiscount > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.green.shade50,
                        child: Row(
                          children: [
                            const Icon(Icons.percent, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              "Применена скидка партнера: $_currentDiscount%",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                    DropdownButton<ProductModel>(
                      isExpanded: true,
                      value: selectedProduct,
                      items: products.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text("${p.article} | ${p.title}", overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedProduct = val;
                          updatePrice(); // Пересчитываем цену при смене товара
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(labelText: "Количество", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: "Цена за ед. (с учетом скидки)", 
                        border: OutlineInputBorder(),
                        helperText: "Можно изменить вручную"
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct == null) return;
                    final qty = int.tryParse(qtyController.text) ?? 1;
                    final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
                    
                    final newItem = RequestItemModel(
                      productId: selectedProduct!.id,
                      productName: selectedProduct!.title,
                      article: selectedProduct!.article,
                      productType: selectedProduct!.typeName,
                      quantity: qty,
                      actualPrice: price,
                    );
                    
                    setState(() => _items.add(newItem));
                    Navigator.pop(ctx);
                  },
                  child: const Text("Добавить"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Выберите партнера")));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Добавьте хотя бы один товар")));
      return;
    }

    setState(() => _isLoading = true);
    final user = context.read<UserProvider>();
    final reqData = {
      'partner_id': _selectedPartnerId,
      'manager_id': (user.role == 'manager') ? user.id : (widget.request?.managerId ?? 0),
      'status': _status,
      'items': _items.map((i) => i.toJson()).toList(),
    };

    String action = 'ADD_REQUEST';
    if (widget.request != null) {
      action = 'UPDATE_REQUEST';
      reqData['id'] = widget.request!.id;
    }

    final response = await _socketService.sendRequest(action, reqData);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Заказ сохранен"), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: ${response['message']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<UserProvider>().role;
    final isManager = userRole == 'manager';
    final isCreating = widget.request == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? 'Новый заказ' : 'Заказ №${widget.request!.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCreating && isManager)
                      DropdownButtonFormField<int>(
                        initialValue: _selectedPartnerId,
                        decoration: const InputDecoration(labelText: 'Партнер'),
                        items: _partnersList.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPartnerId = val;
                            // Находим скидку выбранного партнера
                            final p = _partnersList.firstWhere((element) => element.id == val);
                            _currentDiscount = p.discount;
                          });
                        },
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Партнер: $_selectedPartnerName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_currentDiscount > 0)
                             Text("Персональная скидка: $_currentDiscount%", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    
                    const SizedBox(height: 10),
                    if (isManager)
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Статус'),
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _status = val!),
                      )
                    else
                      Text("Статус: $_status", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 10),
                    Text("Итого: ${_totalCost.toStringAsFixed(2)} р", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _items.isEmpty 
                ? const Center(child: Text("Нет товаров."))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text("${item.quantity} шт x ${item.actualPrice} р"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                      );
                    },
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text("Добавить товар"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _showAddProductDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveOrder,
                      child: const Text("СОХРАНИТЬ"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}