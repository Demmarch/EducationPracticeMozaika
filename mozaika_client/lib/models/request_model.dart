class RequestItemModel {
  final int id;
  final int productId;
  final String productName;
  final String article;
  final String productType;
  int quantity;
  double actualPrice;
  DateTime? plannedDate;

  RequestItemModel({
    this.id = 0,
    required this.productId,
    required this.productName,
    this.article = '',
    this.productType = '',
    required this.quantity,
    required this.actualPrice,
    this.plannedDate,
  });

  factory RequestItemModel.fromJson(Map<String, dynamic> json) {
    return RequestItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Неизвестный товар',
      article: json['article'] ?? '',
      productType: json['type'] ?? '',
      quantity: json['quantity'] ?? 1,
      actualPrice: (json['actual_price'] ?? 0).toDouble(),
      plannedDate: json['planned_date'] != null && json['planned_date'].toString().isNotEmpty
          ? DateTime.tryParse(json['planned_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'actual_price': actualPrice,
      'planned_date': plannedDate?.toIso8601String().split('T').first, // YYYY-MM-DD
    };
  }
}

class RequestModel {
  final int id;
  final int partnerId;
  final String partnerName;
  final int managerId;
  final String managerName;
  final DateTime dateCreated;
  final String status;
  final DateTime? paymentDate;
  // Список товаров (может быть пустым в общем списке заказов)
  List<RequestItemModel> items;

  RequestModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.managerId,
    required this.managerName,
    required this.dateCreated,
    required this.status,
    this.paymentDate,
    this.items = const [],
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <RequestItemModel>[];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((i) => RequestItemModel.fromJson(i))
          .toList();
    }

    return RequestModel(
      id: json['id'] ?? 0,
      partnerId: json['partner_id'] ?? 0,
      partnerName: json['partner_name'] ?? 'Неизвестный партнер',
      managerId: json['manager_id'] ?? 0,
      managerName: json['manager_name'] ?? 'Не назначен',
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'Новая',
      paymentDate: json['payment_date'] != null 
          ? DateTime.tryParse(json['payment_date']) 
          : null,
      items: itemsList,
    );
  }
}