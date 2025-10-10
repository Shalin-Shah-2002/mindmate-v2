import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends GetxController {
  static const _prefKey = 'app_theme_mode';
  // values: 'light' | 'dark' (system removed)
  final RxString _themePref = 'light'.obs;

  ThemeMode get themeMode {
    return _themePref.value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => _themePref.value == 'dark';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    // migrate any legacy 'system' to 'light'
    if (stored == null || stored == 'system') {
      _themePref.value = 'light';
      await _save();
    } else {
      _themePref.value = stored;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _themePref.value);
  }

  void toggleDark(bool value) {
    _themePref.value = value ? 'dark' : 'light';
    _save();
    update();
  }
}
