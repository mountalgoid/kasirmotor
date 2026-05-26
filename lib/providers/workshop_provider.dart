import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/sparepart.dart';
import '../models/service_item.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class WorkshopProvider with ChangeNotifier {
  final List<SparePart> _spareParts = [
    SparePart(
      id: '1',
      name: 'Oli MPX 2',
      purchasePrice: 45000,
      sellingPriceSales: 50000,
      sellingPriceWorkshop: 52000,
      sellingPriceRetail: 55000,
      stock: 20,
      code: 'OLI001',
    ),
    SparePart(
      id: '2',
      name: 'Kampas Rem Depan',
      purchasePrice: 25000,
      sellingPriceSales: 30000,
      sellingPriceWorkshop: 32000,
      sellingPriceRetail: 35000,
      stock: 15,
      code: 'BRK001',
    ),
    SparePart(
      id: '3',
      name: 'Ban Luar IRC 80/90-14',
      purchasePrice: 150000,
      sellingPriceSales: 170000,
      sellingPriceWorkshop: 175000,
      sellingPriceRetail: 185000,
      stock: 5,
      code: 'TYR001',
    ),
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

  void addToCart(dynamic item, {int quantity = 1, String? priceType, double? customPrice}) {
    if (item is SparePart) {
      final price = customPrice ?? item.sellingPriceRetail;
      _cartItems.add(TransactionItem(
        id: item.id,
        name: item.name,
        price: price,
        quantity: quantity,
        isService: false,
        priceType: priceType ?? 'Ecer',
        itemCode: item.code,
      ));
    } else if (item is ServiceItem) {
      _cartItems.add(TransactionItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: 1,
        isService: true,
        priceType: item.category,
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

  void updateSparePart(SparePart updatedPart) {
    final index = _spareParts.indexWhere((p) => p.id == updatedPart.id);
    if (index >= 0) {
      _spareParts[index] = updatedPart;
      notifyListeners();
    }
  }

  void deleteSparePart(String id) {
    _spareParts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index >= 0) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    if (_selectedCustomer?.id == id) {
      _selectedCustomer = null;
    }
    notifyListeners();
  }

  void addServiceItem(ServiceItem service) {
    _services.add(service);
    notifyListeners();
  }

  void updateServiceItem(ServiceItem updatedService) {
    final index = _services.indexWhere((s) => s.id == updatedService.id);
    if (index >= 0) {
      _services[index] = updatedService;
      notifyListeners();
    }
  }

  void deleteServiceItem(String id) {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
