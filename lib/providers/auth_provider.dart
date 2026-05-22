import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Constructor con inyección de dependencia (por defecto MockAuthService)
  AuthProvider([AuthService? authService])
      : _authService = authService ?? MockAuthService();

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}