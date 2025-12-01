class ProductModel {
  final int id;
  final String article;
  final String title;
  final int typeId; // New
  final String typeName;
  final double minCost;
  final String description;
  final String image;
  final String imageBase64;

  ProductModel({
    required this.id,
    required this.article,
    required this.title,
    required this.typeId,
    required this.typeName,
    required this.minCost,
    required this.description,
    required this.image,
    required this.imageBase64
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      article: json['article'] ?? '',
      title: json['product_name'] ?? '',
      typeId: json['product_type_id'] ?? 0,
      typeName: json['type_name'] ?? '',
      minCost: (json['min_cost_for_partner'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      imageBase64: json['image_base64']?.toString() ?? '',
    );
  }
}