import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  int? _id;
  String? _role; // "manager" или "partner"
  String? _name;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  String? get name => _name;
  int? get id => _id;

  void setUser(int id, String role, String name) {
    _id = id;
    _role = role;
    _name = name;
    _isAuthenticated = true;
    notifyListeners(); // Уведомляем UI об обновлении
  }

  void logout() {
    _id = null;
    _role = null;
    _name = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}