class Customer {
  final String id;
  final String name;
  final String plateNumber;
  final String bikeType;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.bikeType,
    this.address = '',
  });
}
