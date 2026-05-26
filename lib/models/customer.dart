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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plateNumber': plateNumber,
    'bikeType': bikeType,
    'address': address,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'],
    name: json['name'],
    plateNumber: json['plateNumber'],
    bikeType: json['bikeType'],
    address: json['address'] ?? '',
  );
}
