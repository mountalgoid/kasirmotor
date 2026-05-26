import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/sparepart.dart';
import '../models/service_item.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class WorkshopProvider with ChangeNotifier {
  WorkshopProvider() {
    loadData();
  }
  final List<SparePart> _spareParts = [
    SparePart(
      id: '1',
      name: 'Oli MPX 2',
      hargaBeli: 45000,
      hargaSales: 50000,
      hargaBengkel: 52000,
      hargaEcer: 55000,
      stock: 20,
      code: 'OLI001',
    ),
    SparePart(
      id: '2',
      name: 'Kampas Rem Depan',
      hargaBeli: 25000,
      hargaSales: 30000,
      hargaBengkel: 32000,
      hargaEcer: 35000,
      stock: 15,
      code: 'BRK001',
    ),
    SparePart(
      id: '3',
      name: 'Ban Luar IRC 80/90-14',
      hargaBeli: 150000,
      hargaSales: 170000,
      hargaBengkel: 175000,
      hargaEcer: 185000,
      stock: 5,
      code: 'TYR001',
    ),
  ];

  final List<ServiceItem> _services = [
    ServiceItem(id: '1', name: 'Servis Ringan', price: 45000, category: 'Servis'),
    ServiceItem(id: '2', name: 'Tune Up', price: 75000, category: 'Servis'),
    ServiceItem(id: '3', name: 'Ganti Oli', price: 10000, category: 'Jasa'),
    ServiceItem(id: '4', name: 'Bongkar Mesin', price: 350000, category: 'Servis Berat'),
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

  List<TransactionItem> get cartItems => List.unmodifiable(_cartItems);
  Customer? get selectedCustomer => _selectedCustomer;

  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spareParts', jsonEncode(_spareParts.map((p) => p.toJson()).toList()));
    await prefs.setString('services', jsonEncode(_services.map((s) => s.toJson()).toList()));
    await prefs.setString('customers', jsonEncode(_customers.map((c) => c.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final partsStr = prefs.getString('spareParts');
      if (partsStr != null) {
        _spareParts.clear();
        _spareParts.addAll((jsonDecode(partsStr) as List).map((p) => SparePart.fromJson(p)).toList());
      }

      final servicesStr = prefs.getString('services');
      if (servicesStr != null) {
        _services.clear();
        _services.addAll((jsonDecode(servicesStr) as List).map((s) => ServiceItem.fromJson(s)).toList());
      }

      final customersStr = prefs.getString('customers');
      if (customersStr != null) {
        _customers.clear();
        _customers.addAll((jsonDecode(customersStr) as List).map((c) => Customer.fromJson(c)).toList());
      }

      final transactionsStr = prefs.getString('transactions');
      if (transactionsStr != null) {
        _transactions.clear();
        _transactions.addAll((jsonDecode(transactionsStr) as List).map((t) => Transaction.fromJson(t)).toList());
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading data: $e');
    }
  }

  void addToCart(dynamic item, {int quantity = 1, String? priceType, double? customPrice}) {
    if (item is SparePart) {
      final price = customPrice ?? item.hargaEcer;
      final type = priceType ?? 'Ecer';

      final index = _cartItems.indexWhere((i) => i.id == item.id && i.priceType == type && !i.isService);

      if (index >= 0) {
        final existingItem = _cartItems[index];
        _cartItems[index] = TransactionItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          costPrice: item.hargaBeli,
          quantity: existingItem.quantity + quantity,
          isService: false,
          priceType: existingItem.priceType,
          itemCode: existingItem.itemCode,
        );
      } else {
        _cartItems.add(TransactionItem(
          id: item.id,
          name: item.name,
          price: price,
          costPrice: item.hargaBeli,
          quantity: quantity,
          isService: false,
          priceType: type,
          itemCode: item.code,
        ));
      }
    } else if (item is ServiceItem) {
      final index = _cartItems.indexWhere((i) => i.id == item.id && i.isService);

      if (index >= 0) {
        final existingItem = _cartItems[index];
        _cartItems[index] = TransactionItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + quantity,
          isService: true,
          priceType: existingItem.priceType,
        );
      } else {
        _cartItems.add(TransactionItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: quantity,
          isService: true,
          priceType: item.category,
        ));
      }
    }
    notifyListeners();
  }

  void incrementCartItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final item = _cartItems[index];
      _cartItems[index] = TransactionItem(
        id: item.id,
        name: item.name,
        price: item.price,
        costPrice: item.costPrice,
        quantity: item.quantity + 1,
        isService: item.isService,
        priceType: item.priceType,
        itemCode: item.itemCode,
      );
      notifyListeners();
    }
  }

  void decreaseCartItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      if (_cartItems[index].quantity > 1) {
        final item = _cartItems[index];
        _cartItems[index] = TransactionItem(
          id: item.id,
          name: item.name,
          price: item.price,
          costPrice: item.costPrice,
          quantity: item.quantity - 1,
          isService: item.isService,
          priceType: item.priceType,
          itemCode: item.itemCode,
        );
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
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
    saveData();
    notifyListeners();
  }

  void addSparePart(SparePart part) {
    _spareParts.add(part);
    saveData();
    notifyListeners();
  }

  void updateSparePart(SparePart updatedPart) {
    final index = _spareParts.indexWhere((p) => p.id == updatedPart.id);
    if (index >= 0) {
      _spareParts[index] = updatedPart;
      saveData();
      notifyListeners();
    }
  }

  void deleteSparePart(String id) {
    _spareParts.removeWhere((p) => p.id == id);
    saveData();
    notifyListeners();
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
    saveData();
    notifyListeners();
  }

  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index >= 0) {
      _customers[index] = updatedCustomer;
      saveData();
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    if (_selectedCustomer?.id == id) {
      _selectedCustomer = null;
    }
    saveData();
    notifyListeners();
  }

  void addServiceItem(ServiceItem service) {
    _services.add(service);
    saveData();
    notifyListeners();
  }

  void updateServiceItem(ServiceItem updatedService) {
    final index = _services.indexWhere((s) => s.id == updatedService.id);
    if (index >= 0) {
      _services[index] = updatedService;
      saveData();
      notifyListeners();
    }
  }

  void deleteServiceItem(String id) {
    _services.removeWhere((s) => s.id == id);
    saveData();
    notifyListeners();
  }
}
