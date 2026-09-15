import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

class LocaleProvider with ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;
  bool get isFrench => _languageCode == 'fr';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('novara_lang') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('novara_lang', code);
    notifyListeners();
  }

  void toggleLanguage() {
    setLocale(_languageCode == 'en' ? 'fr' : 'en');
  }

  String tr(String key) {
    return AppTranslations.tr(key, _languageCode);
  }
}
