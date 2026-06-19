import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_theme_settings.dart';
import '../services/app_settings_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._(this._settingsService, this._settings);

  final AppSettingsService _settingsService;
  AppThemeSettings _settings;

  static Future<ThemeController> create() async {
    final settingsService = AppSettingsService();
    await settingsService.init();
    return ThemeController._(settingsService, settingsService.loadThemeSettings());
  }

  AppThemeSettings get settings => _settings;

  ThemeMode get materialThemeMode {
    switch (_settings.themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Locale? get appLocale {
    switch (_settings.languageMode) {
      case AppLanguageMode.system:
        return null;
      case AppLanguageMode.zhCn:
        return const Locale('zh', 'CN');
      case AppLanguageMode.en:
        return const Locale('en');
    }
  }

  void updateThemeMode(AppThemeMode value) {
    if (_settings.themeMode == value) {
      return;
    }
    _settings = _settings.copyWith(themeMode: value);
    notifyListeners();
    unawaited(_settingsService.saveThemeSettings(_settings));
  }

  void updateLanguageMode(AppLanguageMode value) {
    if (_settings.languageMode == value) {
      return;
    }
    _settings = _settings.copyWith(languageMode: value);
    notifyListeners();
    unawaited(_settingsService.saveThemeSettings(_settings));
  }

  void updateAccentMode(AppAccentMode value) {
    if (_settings.accentMode == value) {
      return;
    }
    _settings = _settings.copyWith(accentMode: value);
    notifyListeners();
    unawaited(_settingsService.saveThemeSettings(_settings));
  }

  void updateOledOptimized(bool value) {
    if (_settings.oledOptimized == value) {
      return;
    }
    _settings = _settings.copyWith(oledOptimized: value);
    notifyListeners();
    unawaited(_settingsService.saveThemeSettings(_settings));
  }

  void updateSettings({
    required AppThemeMode themeMode,
    required AppLanguageMode languageMode,
    required AppAccentMode accentMode,
    required bool oledOptimized,
  }) {
    final next = _settings.copyWith(
      themeMode: themeMode,
      languageMode: languageMode,
      accentMode: accentMode,
      oledOptimized: oledOptimized,
    );
    if (next.themeMode == _settings.themeMode &&
        next.languageMode == _settings.languageMode &&
        next.accentMode == _settings.accentMode &&
        next.oledOptimized == _settings.oledOptimized) {
      return;
    }
    _settings = next;
    notifyListeners();
    unawaited(_settingsService.saveThemeSettings(_settings));
  }
}
