import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/gym_info.dart';
import '../services/auth_service.dart';

class GymProvider extends ChangeNotifier {
  // -------------------------------------------------------
  // Estado
  // -------------------------------------------------------

  User? _user;
  bool _isAuthLoading = true;
  GymInfo? _gymInfo;
  bool _isDarkMode = false;
  bool _hasUnreadNotifications = false;

  Timer? _notificationTimer;

  // -------------------------------------------------------
  // Getters
  // -------------------------------------------------------

  User? get user => _user;
  bool get isAuthLoading => _isAuthLoading;
  GymInfo? get gymInfo => _gymInfo;
  bool get isDarkMode => _isDarkMode;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  // -------------------------------------------------------
  // Constructor: se inicializa al arrancar la app
  // -------------------------------------------------------

  GymProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadTheme();
    await _checkAuth();
  }

  // -------------------------------------------------------
  // Tema (persistido en SharedPreferences)
  // Equivalente a los dos useEffect de darkMode en GymContext
  // -------------------------------------------------------

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando el tema: $e');
    }
  }

  Future<void> setIsDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', value);
    } catch (e) {
      debugPrint('Error guardando el tema: $e');
    }
  }

  Future<void> checkAuth() async {
    _isAuthLoading = true;
    notifyListeners();

    final token = await AuthService.refreshAccessToken();

    if (token != null) {
      await refreshUser();
      await getGymInfo();
    } else {
      await handleLogout();
    }

    _isAuthLoading = false;
    notifyListeners();
  }

  // -------------------------------------------------------
  // refreshUser: GET /users/me/
  // Equivalente a refreshUser() de GymContext
  // -------------------------------------------------------

  Future<void> refreshUser() async {
    try {
      final response = await AuthService.get('/users/me/');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        await handleLogout();
        return;
      }

      final user = User.fromJson(data);
      if (user.status == 'DEL') {
        debugPrint('Usuario inactivo. Cerrando sesión.');
        await handleLogout();
        return;
      }

      _user = user;

      // Inicia polling de notificaciones si el usuario aceptó los T&C
      if (user.termsAccepted) {
        await getHasUnreadNotifications();
        _startNotificationPolling();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error actualizando el usuario: $e');
      await handleLogout();
    }
  }

  // -------------------------------------------------------
  // gymInfo: GET /users/gym/info/
  // Equivalente a getGymInfo() de GymContext
  // -------------------------------------------------------

  Future<void> getGymInfo() async {
    if (_user == null) return;
    try {
      final response = await AuthService.get('/users/gym/info/');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        _gymInfo = GymInfo.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error obteniendo la info del gimnasio: $e');
    }
  }

  // -------------------------------------------------------
  // Notificaciones: GET /notifications/unread/
  // Equivalente a getHasUnreadNotifications() de GymContext
  // -------------------------------------------------------

  Future<void> getHasUnreadNotifications() async {
    try {
      final response = await AuthService.get('/notifications/unread/');
      final data = response.data['data'] as Map<String, dynamic>?;
      final hasUnread = data?['has_unread'] as bool? ?? false;
      if (_hasUnreadNotifications != hasUnread) {
        _hasUnreadNotifications = hasUnread;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error obteniendo notificaciones: $e');
    }
  }

  void _startNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => getHasUnreadNotifications(),
    );
  }

  void _stopNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  // -------------------------------------------------------
  // Login: recibe tokens del backend, guarda y carga usuario
  // -------------------------------------------------------

  Future<void> handleLogin(String accessToken, String refreshToken) async {
    await AuthService.saveToken(accessToken, refreshToken);
    await refreshUser();
    await getGymInfo();
  }

  // -------------------------------------------------------
  // Logout
  // -------------------------------------------------------

  Future<void> handleLogout() async {
    _stopNotificationPolling();
    await AuthService.logout();
    _user = null;
    _gymInfo = null;
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  // -------------------------------------------------------
  // Actualiza termsAccepted localmente después de que el usuario acepta
  // -------------------------------------------------------

  void markTermsAccepted() {
    if (_user == null) return;
    // Reconstruimos el objeto User con termsAccepted = true
    final updated = User.fromJson({
      ..._user!.toJson(),
      'terms_accepted': true,
    });
    _user = updated;
    getHasUnreadNotifications();
    _startNotificationPolling();
    getGymInfo();
    notifyListeners();
  }

  // -------------------------------------------------------
  // checkAuth inicial - alias público
  // -------------------------------------------------------

  Future<void> _checkAuth() => checkAuth();

  @override
  void dispose() {
    _stopNotificationPolling();
    super.dispose();
  }
}
