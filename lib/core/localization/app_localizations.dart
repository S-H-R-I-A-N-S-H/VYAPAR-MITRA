import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lightweight JSON-backed localization loader supporting Hindi & English
/// Designed for easy extension to Marathi, Gujarati, etc.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    } catch (_) {
      jsonString = await rootBundle.loadString('assets/i18n/en.json');
    }

    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
