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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hargaBeli': hargaBeli,
    'hargaSales': hargaSales,
    'hargaBengkel': hargaBengkel,
    'hargaEcer': hargaEcer,
    'stock': stock,
    'code': code,
  };

  factory SparePart.fromJson(Map<String, dynamic> json) => SparePart(
    id: json['id'],
    name: json['name'],
    hargaBeli: (json['hargaBeli'] as num).toDouble(),
    hargaSales: (json['hargaSales'] as num).toDouble(),
    hargaBengkel: (json['hargaBengkel'] as num).toDouble(),
    hargaEcer: (json['hargaEcer'] as num).toDouble(),
    stock: json['stock'] as int,
    code: json['code'],
  );

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
