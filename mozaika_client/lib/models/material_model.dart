class MaterialModel {
  final int id;
  final String title;
  final String type;
  final String image;
  final String imageBase64;
  final double cost;
  final int countInPack;
  final String unit;
  final int minCount;
  final int currentQuantity;
  final String description;  

  MaterialModel({
    required this.id,
    required this.title,
    required this.type,
    required this.image,
    this.imageBase64 = '',
    required this.cost,
    required this.countInPack,
    required this.unit,
    required this.minCount,
    required this.currentQuantity,
    required this.description,
  });

  // Фабрика для создания объекта из JSON
  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      title: json['material_name'] ?? 'Без названия',
      type: json['type_name'] ?? 'Тип не указан',
      image: json['image']?.toString() ?? '',
      imageBase64: json['image_base64']?.toString() ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      countInPack: json['count_in_pack'] ?? 1,
      unit: json['unit'] ?? 'шт',
      minCount: json['min_count'] ?? 0,
      currentQuantity: json['current_quantity'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}