import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/sparepart.dart';
import '../models/service_item.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class WorkshopProvider with ChangeNotifier {
  final List<SparePart> _spareParts = [
    SparePart(id: '1', name: 'Oli MPX 2', price: 55000, stock: 20, code: 'OLI001'),
    SparePart(id: '2', name: 'Kampas Rem Depan', price: 35000, stock: 15, code: 'BRK001'),
    SparePart(id: '3', name: 'Ban Luar IRC 80/90-14', price: 185000, stock: 5, code: 'TYR001'),
  ];

  final List<ServiceItem> _services = [
    ServiceItem(id: '1', name: 'Servis Ringan', price: 45000),
    ServiceItem(id: '2', name: 'Tune Up', price: 75000),
    ServiceItem(id: '3', name: 'Ganti Oli', price: 10000),
    ServiceItem(id: '4', name: 'Bongkar Mesin', price: 350000),
  ];

  final List<Customer> _customers = [];
  final List<Transaction> _transactions = [];

  List<SparePart> get spareParts => [..._spareParts];
  List<ServiceItem> get services => [..._services];
  List<Customer> get customers => [..._customers];
  List<Transaction> get transactions => [..._transactions];

  // Cart state for current transaction
  final List<TransactionItem> _cartItems = [];
  Customer? _selectedCustomer;

  List<TransactionItem> get cartItems => [..._cartItems];
  Customer? get selectedCustomer => _selectedCustomer;

  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addToCart(dynamic item, {int quantity = 1}) {
    if (item is SparePart) {
      final existingIndex = _cartItems.indexWhere((element) => element.id == item.id && !element.isService);
      if (existingIndex >= 0) {
        _cartItems[existingIndex] = TransactionItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: _cartItems[existingIndex].quantity + quantity,
          isService: false,
        );
      } else {
        _cartItems.add(TransactionItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: quantity,
          isService: false,
        ));
      }
    } else if (item is ServiceItem) {
      _cartItems.add(TransactionItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: 1,
        isService: true,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    notifyListeners();
  }

  void completeTransaction(double paidAmount, PaymentMethod method) {
    final transaction = Transaction(
      id: const Uuid().v4(),
      customer: _selectedCustomer,
      items: [..._cartItems],
      date: DateTime.now(),
      totalAmount: cartTotal,
      paidAmount: paidAmount,
      paymentMethod: method,
    );

    // Update stocks
    for (var item in _cartItems) {
      if (!item.isService) {
        final partIndex = _spareParts.indexWhere((p) => p.id == item.id);
        if (partIndex >= 0) {
          _spareParts[partIndex].stock -= item.quantity;
        }
      }
    }

    _transactions.insert(0, transaction);
    clearCart();
    notifyListeners();
  }

  void addSparePart(SparePart part) {
    _spareParts.add(part);
    notifyListeners();
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }
}
