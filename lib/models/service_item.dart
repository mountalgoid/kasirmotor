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
}
