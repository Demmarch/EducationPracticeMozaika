import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (product.imageBase64.isNotEmpty) {
      imageWidget = Image.memory(
        base64Decode(product.imageBase64),
        width: 80, height: 80, fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50),
      );
    } else {
      imageWidget = const Icon(Icons.shopping_bag, size: 50, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: imageWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.typeName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text("Артикул: ${product.article}"),
                  const SizedBox(height: 8),
                  Text(
                    "Мин. стоимость: ${product.minCost.toStringAsFixed(2)} р",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}