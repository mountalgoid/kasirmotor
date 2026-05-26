class SparePart {
  final String id;
  final String name;
  final double hargaBeli;
  final double hargaSales;
  final double hargaBengkel;
  final double hargaEcer;
  int stock;
  final String code;

  SparePart({
    required this.id,
    required this.name,
    required this.hargaBeli,
    required this.hargaSales,
    required this.hargaBengkel,
    required this.hargaEcer,
    required this.stock,
    required this.code,
  });

  SparePart copyWith({
    String? id,
    String? name,
    double? hargaBeli,
    double? hargaSales,
    double? hargaBengkel,
    double? hargaEcer,
    int? stock,
    String? code,
  }) {
    return SparePart(
      id: id ?? this.id,
      name: name ?? this.name,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaSales: hargaSales ?? this.hargaSales,
      hargaBengkel: hargaBengkel ?? this.hargaBengkel,
      hargaEcer: hargaEcer ?? this.hargaEcer,
      stock: stock ?? this.stock,
      code: code ?? this.code,
    );
  }
}
