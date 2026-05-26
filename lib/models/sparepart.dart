class SparePart {
  final String id;
  final String name;
  final double purchasePrice;
  final double sellingPriceSales;
  final double sellingPriceWorkshop;
  final double sellingPriceRetail;
  int stock;
  final String code;

  SparePart({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellingPriceSales,
    required this.sellingPriceWorkshop,
    required this.sellingPriceRetail,
    required this.stock,
    required this.code,
  });

  double get price => sellingPriceRetail; // Default price

  SparePart copyWith({
    String? id,
    String? name,
    double? purchasePrice,
    double? sellingPriceSales,
    double? sellingPriceWorkshop,
    double? sellingPriceRetail,
    int? stock,
    String? code,
  }) {
    return SparePart(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPriceSales: sellingPriceSales ?? this.sellingPriceSales,
      sellingPriceWorkshop: sellingPriceWorkshop ?? this.sellingPriceWorkshop,
      sellingPriceRetail: sellingPriceRetail ?? this.sellingPriceRetail,
      stock: stock ?? this.stock,
      code: code ?? this.code,
    );
  }
}
