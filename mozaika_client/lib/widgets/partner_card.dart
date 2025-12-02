import 'package:flutter/material.dart';
import '../models/partner_model.dart';
import '../utils/styles.dart';

class PartnerCard extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback? onTap;

  const PartnerCard({super.key, required this.partner, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          "${partner.type} | ${partner.name}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text("Директор: ${partner.director}"),
            Text("Телефон: ${partner.phone}"),
            Text("Рейтинг: ${partner.rating}"),
          ],
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown, // Уменьшит контент, только если он не влезает
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Скидка", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                "${partner.discount}%",
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.primary
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}