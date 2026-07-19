class ProductModel {
  final int? id;
  final String name;
  final double price;
  final double modal;
  final String category;
  final String? barcode;

  ProductModel({
    this.id,
    required this.name,
    required this.price,
    this.modal = 0.0,
    this.category = 'Lainnya',
    this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'modal': modal,
      'category': category,
      'barcode': barcode,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      modal: (map['modal'] as num).toDouble(),
      category: map['category'] ?? 'Lainnya',
      barcode: map['barcode'],
    );
  }
}
