import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_theme_settings.dart';

class AppSettingsService {
  static const String _boxName = 'app_settings';
  static const String _themeSettingsKey = 'theme_settings';

  Box<dynamic>? _box;

  Future<void> init() async {
    if (_box?.isOpen ?? false) {
      return;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      final dir = await getApplicationSupportDirectory();
      Hive.init(p.join(dir.path, 'hive'));
      _box = await Hive.openBox<dynamic>(_boxName);
      return;
    }

    _box = Hive.box<dynamic>(_boxName);
  }

  AppThemeSettings loadThemeSettings() {
    final raw = _box?.get(_themeSettingsKey);
    if (raw is! Map) {
      return const AppThemeSettings();
    }

    final themeModeIndex = raw['themeMode'] as int?;
    final styleModeIndex = raw['styleMode'] as int?;
    final accentModeIndex = raw['accentMode'] as int?;
    final oledOptimized = raw['oledOptimized'] as bool?;

    return AppThemeSettings(
      themeMode: themeModeIndex != null &&
              themeModeIndex >= 0 &&
              themeModeIndex < AppThemeMode.values.length
          ? AppThemeMode.values[themeModeIndex]
          : AppThemeMode.system,
      styleMode: styleModeIndex != null &&
              styleModeIndex >= 0 &&
              styleModeIndex < AppStyleMode.values.length
          ? AppStyleMode.values[styleModeIndex]
          : AppStyleMode.material,
      accentMode: accentModeIndex != null &&
              accentModeIndex >= 0 &&
              accentModeIndex < AppAccentMode.values.length
          ? AppAccentMode.values[accentModeIndex]
          : AppAccentMode.system,
      oledOptimized: oledOptimized ?? false,
    );
  }

  Future<void> saveThemeSettings(AppThemeSettings settings) async {
    await _box?.put(_themeSettingsKey, <String, Object>{
      'themeMode': settings.themeMode.index,
      'styleMode': settings.styleMode.index,
      'accentMode': settings.accentMode.index,
      'oledOptimized': settings.oledOptimized,
    });
  }
}
