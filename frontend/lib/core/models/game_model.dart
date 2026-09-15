import 'product_model.dart';

class GameModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? bannerUrl;
  final String category;
  final String? publisher;
  final String inputLabel;
  final String inputPlaceholder;
  final String? inputLabel2;
  final String? inputPlaceholder2;
  final bool isActive;
  final int sortOrder;
  final List<ProductModel> products;

  GameModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.bannerUrl,
    this.category = 'game',
    this.publisher,
    this.inputLabel = 'User ID',
    this.inputPlaceholder = 'Masukkan User ID',
    this.inputLabel2,
    this.inputPlaceholder2,
    this.isActive = true,
    this.sortOrder = 0,
    this.products = const [],
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    var rawProducts = json['products'];
    List<ProductModel> productList = [];
    if (rawProducts != null && rawProducts is List) {
      productList = rawProducts.map((p) => ProductModel.fromJson(p)).toList();
    }

    return GameModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      bannerUrl: json['bannerUrl'],
      category: json['category'] ?? 'game',
      publisher: json['publisher'],
      inputLabel: json['inputLabel'] ?? 'User ID',
      inputPlaceholder: json['inputPlaceholder'] ?? 'Masukkan User ID',
      inputLabel2: json['inputLabel2'],
      inputPlaceholder2: json['inputPlaceholder2'],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      products: productList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'category': category,
      'publisher': publisher,
      'inputLabel': inputLabel,
      'inputPlaceholder': inputPlaceholder,
      'inputLabel2': inputLabel2,
      'inputPlaceholder2': inputPlaceholder2,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}
