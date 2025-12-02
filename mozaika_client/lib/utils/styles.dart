import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF546F94);
  static const Color accent = Color(0xFFABCFCE);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF333333);
  static const Color error = Color(0xFFE74C3C);
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );
}