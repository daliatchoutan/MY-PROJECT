import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  String get role => _user?['role'] ?? 'Customer';

  ApiService get api => ApiService(token: _token);

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        final profileRes = await api.getProfile();
        _user = profileRes['user'];
      }
    } catch (e) {
      // Token invalid or server unreachable -> clear saved token
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService().login(email, password);
      _token = res['token'];
      _user = res['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);

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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService().register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        address: address,
      );
      _token = res['token'];
      _user = res['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);

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
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
