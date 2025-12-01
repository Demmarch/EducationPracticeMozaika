import 'package:flutter/material.dart';
import 'package:mozaika_client/screens/product_edit_screen.dart';
import '../models/product_model.dart';
import '../services/socket_service.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../utils/styles.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final SocketService _socketService = SocketService();
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  Future<List<ProductModel>> _fetchProducts() async {
    final response = await _socketService.sendRequest('GET_PRODUCTS');
    
    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Ошибка загрузки продукции');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список продукции'),
        backgroundColor: AppColors.primary, // Убедитесь, что AppColors импортирован или замените цвет
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductEditScreen()),
        );
        if (result == true) _loadProducts();
      },
    ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Продукция не найдена'));
          }
          final products = snapshot.data!;
          return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductEditScreen(product: product),
                  ),
                );
                if (result == true) _loadProducts();
              },
              child: ProductCard(product: product),
            );
          },
          );
        },
      ),
    );
  }
}