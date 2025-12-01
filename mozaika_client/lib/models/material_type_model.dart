class MaterialType {
  final int id;
  final String title;

  MaterialType({required this.id, required this.title});

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      id: json['id'],
      title: json['title'],
    );
  }
}