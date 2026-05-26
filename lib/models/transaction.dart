import 'package:bengkel_pro/models/customer.dart';

enum PaymentMethod { cash, transfer }

class TransactionItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final bool isService;
  final String? priceType; // sales, bengkel, ecer, or purchase
  final String? itemCode;

  TransactionItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.isService,
    this.priceType,
    this.itemCode,
  });

  double get total => price * quantity;
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
}
