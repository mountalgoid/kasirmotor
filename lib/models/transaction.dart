import 'package:bengkel_pro/models/customer.dart';

enum PaymentMethod { cash, transfer }

class TransactionItem {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final int quantity;
  final bool isService;
  final String? priceType; // sales, bengkel, ecer, or purchase
  final String? itemCode;

  TransactionItem({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    this.quantity = 1,
    required this.isService,
    this.priceType,
    this.itemCode,
  });

  double get total => price * quantity;
  double get totalCost => costPrice * quantity;
  double get profit => total - totalCost;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'costPrice': costPrice,
    'quantity': quantity,
    'isService': isService,
    'priceType': priceType,
    'itemCode': itemCode,
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    costPrice: (json['costPrice'] as num).toDouble(),
    quantity: json['quantity'] as int,
    isService: json['isService'] as bool,
    priceType: json['priceType'],
    itemCode: json['itemCode'],
  );
}

class Transaction {
  final String id;
  final Customer? customer;
  final List<TransactionItem> items;
  final DateTime date;
  final double totalAmount;
  final double paidAmount;
  final PaymentMethod paymentMethod;

  Transaction({
    required this.id,
    this.customer,
    required this.items,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
  });

  double get change => paidAmount - totalAmount;
  double get totalProfit => items.fold(0, (sum, item) => sum + item.profit);

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer': customer?.toJson(),
    'items': items.map((i) => i.toJson()).toList(),
    'date': date.toIso8601String(),
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'paymentMethod': paymentMethod.index,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
    items: (json['items'] as List).map((i) => TransactionItem.fromJson(i)).toList(),
    date: DateTime.parse(json['date']),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num).toDouble(),
    paymentMethod: PaymentMethod.values[json['paymentMethod'] as int],
  );
}
