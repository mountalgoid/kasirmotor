class SparePart {
  final String id;
  final String name;
  final double price;
  int stock;
  final String code;

  SparePart({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.code,
  });

  SparePart copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    String? code,
  }) {
    return SparePart(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      code: code ?? this.code,
    );
  }
}
