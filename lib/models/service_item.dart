class ServiceItem {
  final String id;
  final String name;
  final double price;
  final String category;

  ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.category = 'Umum',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
  };

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    category: json['category'],
  );
}
