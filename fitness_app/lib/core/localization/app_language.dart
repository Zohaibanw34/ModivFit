import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static const String _storageKey = 'app_language_code';
  static const String englishCode = 'en';
  static const String arabicCode = 'ar';
  static const String urduCode = 'ur';

  static const List<Locale> supportedLocales = <Locale>[
    Locale(englishCode),
    Locale(arabicCode),
    Locale(urduCode),
  ];

  static Future<Locale> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey) ?? englishCode;
    return _localeFromCode(code);
  }

  static Future<void> changeLocale(String code) async {
    final locale = _localeFromCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
    Get.updateLocale(locale);
  }

  static Locale _localeFromCode(String code) {
    switch (code.toLowerCase()) {
      case arabicCode:
        return const Locale(arabicCode);
      case urduCode:
        return const Locale(urduCode);
      case englishCode:
      default:
        return const Locale(englishCode);
    }
  }
}
