import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/material_model.dart';
import '../utils/styles.dart';

class MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final VoidCallback onTap; // Для перехода к редактированию

  const MaterialCard({
    super.key,
    required this.material,
    required this.onTap,
  });

  // Логика расчета стоимости партии (Задание Модуль 2)
  String _calculateBatchCost() {
    // Если количество на складе меньше минимального
    if (material.currentQuantity < material.minCount) {
      // Получить разность
      int needed = material.minCount - material.currentQuantity;
      
      // Рассчитать объем закупки кратно упаковкам (округляем вверх)
      // (needed / pack) -> ceil -> * pack
      int packsNeeded = (needed / material.countInPack).ceil();
      int totalItemsToBuy = packsNeeded * material.countInPack;

      // Стоимость партии
      double batchCost = totalItemsToBuy * material.cost;

      // Два знака после запятой
      return "${batchCost.toStringAsFixed(2)} р";
    }
    
    // Если всего хватает
    return "0.00 р"; 
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (material.imageBase64.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(material.imageBase64),
          width: 80, height: 80, fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    } 
    else if (material.image.isNotEmpty) {
       imageWidget = const Icon(Icons.image, size: 50, color: Colors.grey);
    } else {
      imageWidget = const Icon(Icons.image, size: 50, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // По макету углы острые? (опционально)
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: imageWidget,
              ),
              const SizedBox(width: 16),

              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Тип | Наименование 
                    Text(
                      "${material.type} | ${material.title}",
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    
                    // Минимальное количество 
                    Text("Минимальное количество: ${material.minCount} ${material.unit}"),
                    
                    // Количество на складе 
                    Text("Количество на складе:      ${material.currentQuantity} ${material.unit}"),
                    
                    const SizedBox(height: 8),
                    // Цена 
                    Text("Цена: ${material.cost.toStringAsFixed(2)} р / Единица измерения: ${material.unit}"),
                  ],
                ),
              ),

              // Стоимость партии (справа) 
              Column(
                children: [
                   const Text("Стоимость партии:", style: TextStyle(fontSize: 12)),
                   Text(
                     _calculateBatchCost(),
                     style: const TextStyle(
                       fontSize: 16, 
                       fontWeight: FontWeight.bold,
                       // Обычно такие вещи выделяют цветом, если есть дефицит
                       color: AppColors.textMain 
                     ),
                   ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}