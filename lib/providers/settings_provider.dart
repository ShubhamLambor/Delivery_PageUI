// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;

  // Notifications
  bool _newOrderAlerts = true;
  bool _paymentAlerts = true;
  bool _systemMessages = true;

  // Sound & Vibration
  bool _orderSound = true;
  bool _vibration = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get newOrderAlerts => _newOrderAlerts;
  bool get paymentAlerts => _paymentAlerts;
  bool get systemMessages => _systemMessages;
  bool get orderSound => _orderSound;
  bool get vibration => _vibration;

  // Initialize and load saved settings
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    // Load theme (0=system, 1=light, 2=dark)
    int themeModeIndex = _prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];

    // Load notifications
    _newOrderAlerts = _prefs.getBool('new_order_alerts') ?? true;
    _paymentAlerts = _prefs.getBool('payment_alerts') ?? true;
    _systemMessages = _prefs.getBool('system_messages') ?? true;

    // Load sound & vibration
    _orderSound = _prefs.getBool('order_sound') ?? true;
    _vibration = _prefs.getBool('vibration') ?? true;

    notifyListeners();
  }

  // Theme setter
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  // Notification setters
  Future<void> setNewOrderAlerts(bool value) async {
    _newOrderAlerts = value;
    await _prefs.setBool('new_order_alerts', value);
    notifyListeners();
  }

  Future<void> setPaymentAlerts(bool value) async {
    _paymentAlerts = value;
    await _prefs.setBool('payment_alerts', value);
    notifyListeners();
  }

  Future<void> setSystemMessages(bool value) async {
    _systemMessages = value;
    await _prefs.setBool('system_messages', value);
    notifyListeners();
  }

  // Sound & Vibration setters
  Future<void> setOrderSound(bool value) async {
    _orderSound = value;
    await _prefs.setBool('order_sound', value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _vibration = value;
    await _prefs.setBool('vibration', value);
    notifyListeners();
  }
}
