import 'package:flutter/foundation.dart';

class BadgeCountProvider with ChangeNotifier {
  int _badgeCount = 0;

  int get badgeCount => _badgeCount;

  bool _isTableStatusChecked = false;

  bool get isTableStatusChecked => _isTableStatusChecked;
 
  void setTableStatusChecked(bool value) {
    _isTableStatusChecked = value;
    notifyListeners();
  }
  void updateBadgeCount(int count) {
    _badgeCount = count;
    notifyListeners();
  }
   String _phoneNumber = '';

  String get phoneNumber => _phoneNumber;

  void setPhoneNumber(String number) {
    _phoneNumber = number;
    notifyListeners();
  }
}


class PhoneNumberProvider with ChangeNotifier {
  String _phoneNumber = '';
  String _customerName = '';
  String _customerPoint = '';
  bool _isLoggedIn = false;

  String get phoneNumber => _phoneNumber;
  String get customerName => _customerName;
  String get customerPoint => _customerPoint;
  bool get isLoggedIn => _isLoggedIn;

  set phoneNumber(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  set customerName(String value) {
    _customerName = value;
    notifyListeners();
  }

  set customerPoint(String value) {
    _customerPoint = value;
    notifyListeners();
  }

  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }
}
class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String _phoneNumber = '';

  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;

  void login(String phoneNumber) {
    _isLoggedIn = true;
    _phoneNumber = phoneNumber;
    notifyListeners();
  }
void clearPhoneNumber() {
    _phoneNumber = '';
    notifyListeners();
  }
  void logout() {
    _isLoggedIn = false;
    _phoneNumber = '';
    notifyListeners();
  }
}