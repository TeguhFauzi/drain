class ProductModel {
  final String id;
  final String? gameId;
  final String name;
  final String? description;
  final double price;
  final double sellPrice;
  final String? providerCode;
  final String category;
  final bool isActive;
  final int sortOrder;

  ProductModel({
    required this.id,
    this.gameId,
    required this.name,
    this.description,
    required this.price,
    required this.sellPrice,
    this.providerCode,
    this.category = 'topup',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      gameId: json['gameId'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      sellPrice: (json['sellPrice'] is num) ? (json['sellPrice'] as num).toDouble() : double.tryParse(json['sellPrice']?.toString() ?? '0') ?? 0.0,
      providerCode: json['providerCode'],
      category: json['category'] ?? 'topup',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'name': name,
      'description': description,
      'price': price,
      'sellPrice': sellPrice,
      'providerCode': providerCode,
      'category': category,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
