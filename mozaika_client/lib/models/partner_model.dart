class PartnerModel {
  final int id;
  final String type;
  final String name;
  final String director;
  final String phone;
  final String email;
  final String address;
  final int rating;
  final int discount;

  PartnerModel({
    required this.id,
    required this.type,
    required this.name,
    required this.director,
    required this.phone,
    required this.email,
    required this.address,
    required this.rating,
    required this.discount,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] ?? 0,
      type: json['partner_type'] ?? '',
      name: json['partner_name'] ?? '',
      director: json['director_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['legal_address'],
      rating: json['rating'] ?? 0,
      discount: json['discount'] ?? 0,
    );
  }
}