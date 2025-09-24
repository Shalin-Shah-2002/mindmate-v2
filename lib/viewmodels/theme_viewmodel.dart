import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends GetxController {
  static const _prefKey = 'app_theme_mode';
  // values: 'system' | 'light' | 'dark'
  final RxString _themePref = 'system'.obs;

  ThemeMode get themeMode {
    switch (_themePref.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get followSystem => _themePref.value == 'system';
  bool get isDark => _themePref.value == 'dark';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themePref.value = prefs.getString(_prefKey) ?? 'system';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _themePref.value);
  }

  void setFollowSystem(bool value) {
    _themePref.value = value ? 'system' : 'light';
    _save();
    update();
  }

  void toggleDark(bool value) {
    _themePref.value = value ? 'dark' : 'light';
    _save();
    update();
  }
}
