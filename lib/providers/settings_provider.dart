import 'package:flutter/foundation.dart';

class SettingsProvider with ChangeNotifier {
  String _workshopName = 'Ibrahim Part';
  String _workshopAddress = 'Jl. Raya Motor No. 123';
  String _workshopPhone = '0812-3456-7890';
  String _qrisImageUrl = '';
  String? _qrisLocalPath;
  String _bankName = 'BCA';
  String _bankAccountNumber = '1234567890';
  String _bankAccountName = 'Ibrahim Part';

  String get workshopName => _workshopName;
  String get workshopAddress => _workshopAddress;
  String get workshopPhone => _workshopPhone;
  String get qrisImageUrl => _qrisImageUrl;
  String? get qrisLocalPath => _qrisLocalPath;
  String get bankName => _bankName;
  String get bankAccountNumber => _bankAccountNumber;
  String get bankAccountName => _bankAccountName;

  void updateSettings({
    String? name,
    String? address,
    String? phone,
    String? qris,
    String? qrisPath,
    String? bank,
    String? accountNum,
    String? accountName,
  }) {
    if (name != null) _workshopName = name;
    if (address != null) _workshopAddress = address;
    if (phone != null) _workshopPhone = phone;
    if (qris != null) _qrisImageUrl = qris;
    if (qrisPath != null) _qrisLocalPath = qrisPath;
    if (bank != null) _bankName = bank;
    if (accountNum != null) _bankAccountNumber = accountNum;
    if (accountName != null) _bankAccountName = accountName;
    notifyListeners();
  }
}
