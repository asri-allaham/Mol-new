import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageProvider extends ChangeNotifier {
  Locale _appLocale = const Locale("en");

  Locale get appLocal => _appLocale;
  String _currentLanguage = "English(US)";

  String get currentLanguage => _currentLanguage;

  AppLanguageProvider() {
    _loadLanguage();
    _loadLocale();
  }

  void setLanguage(String lang) async {
    _currentLanguage = lang;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? "English(US)";
    notifyListeners();
  }

  Future<void> _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code') ?? 'en';
    String? countryCode = prefs.getString('countryCode') ?? 'US';
    _appLocale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> changeLanguageByIndex(int index) async {
    String languageCode = _getLanguageCodeFromIndex(index);
    String countryCode = _getCountryCodeFromIndex(index);

    if (languageCode.isEmpty || countryCode.isEmpty) return;

    _appLocale = Locale(languageCode, countryCode);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    await prefs.setString('countryCode', countryCode);

    notifyListeners();
  }

  static const _languageMap = {
    0: {'languageCode': 'en', 'countryCode': 'US'},
    1: {'languageCode': 'en', 'countryCode': 'GB'},
    2: {'languageCode': 'zh', 'countryCode': 'CN'},
    3: {'languageCode': 'hi', 'countryCode': 'IN'},
    4: {'languageCode': 'es', 'countryCode': 'ES'},
    5: {'languageCode': 'fr', 'countryCode': 'FR'},
    6: {'languageCode': 'ar', 'countryCode': 'SA'},
    7: {'languageCode': 'ru', 'countryCode': 'RU'},
    8: {'languageCode': 'id', 'countryCode': 'ID'},
    9: {'languageCode': 'vi', 'countryCode': 'VN'},
  };

  String _getLanguageCodeFromIndex(int index) =>
      _languageMap[index]?['languageCode'] ?? '';

  String _getCountryCodeFromIndex(int index) =>
      _languageMap[index]?['countryCode'] ?? '';
}
