import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_grouping_settings.dart';
import '../models/cluster_settings.dart';
import '../models/app_theme_settings.dart';

class AppSettingsService {
  static const String _boxName = 'app_settings';
  static const String _themeSettingsKey = 'theme_settings';
  static const String _groupingSettingsKey = 'grouping_settings';

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
    final languageModeIndex = raw['languageMode'] as int?;
    final accentModeIndex = raw['accentMode'] as int?;
    final oledOptimized = raw['oledOptimized'] as bool?;
    final eInkOptimized = raw['eInkOptimized'] as bool?;
    final multiWindowMode = raw['multiWindowMode'] as bool?;
    final windowsMicaEnabled = raw['windowsMicaEnabled'] as bool?;

    return AppThemeSettings(
      themeMode: themeModeIndex != null &&
              themeModeIndex >= 0 &&
              themeModeIndex < AppThemeMode.values.length
          ? AppThemeMode.values[themeModeIndex]
          : AppThemeMode.system,
      languageMode: languageModeIndex != null &&
              languageModeIndex >= 0 &&
              languageModeIndex < AppLanguageMode.values.length
          ? AppLanguageMode.values[languageModeIndex]
          : AppLanguageMode.system,
      accentMode: accentModeIndex != null &&
              accentModeIndex >= 0 &&
              accentModeIndex < AppAccentMode.values.length
          ? AppAccentMode.values[accentModeIndex]
          : AppAccentMode.system,
      oledOptimized: oledOptimized ?? false,
      eInkOptimized: eInkOptimized ?? false,
      multiWindowMode: multiWindowMode ?? false,
      windowsMicaEnabled: windowsMicaEnabled ?? false,
    );
  }

  Future<void> saveThemeSettings(AppThemeSettings settings) async {
    await _box?.put(_themeSettingsKey, <String, Object>{
      'themeMode': settings.themeMode.index,
      'languageMode': settings.languageMode.index,
      'accentMode': settings.accentMode.index,
      'oledOptimized': settings.oledOptimized,
      'eInkOptimized': settings.eInkOptimized,
      'multiWindowMode': settings.multiWindowMode,
      'windowsMicaEnabled': settings.windowsMicaEnabled,
    });
  }

  AppGroupingSettings loadGroupingSettings() {
    final raw = _box?.get(_groupingSettingsKey);
    if (raw is! Map) {
      return const AppGroupingSettings();
    }

    final smartGroupingLevelIndex = raw['defaultSmartGroupingLevel'] as int?;
    final defaultSeparateOddEven = raw['defaultSeparateOddEven'] as bool?;
    final batchCropRecursive = raw['batchCropRecursive'] as bool?;
    final useOriginalFileNameForExport =
        raw['useOriginalFileNameForExport'] as bool?;
    final allowCropOutsidePage = raw['allowCropOutsidePage'] as bool?;
    return AppGroupingSettings(
      defaultSmartGroupingLevel: smartGroupingLevelIndex != null &&
              smartGroupingLevelIndex >= 0 &&
              smartGroupingLevelIndex < SmartGroupingLevel.values.length
          ? SmartGroupingLevel.values[smartGroupingLevelIndex]
          : SmartGroupingLevel.balanced,
      defaultSeparateOddEven: defaultSeparateOddEven ?? true,
      batchCropRecursive: batchCropRecursive ?? false,
      useOriginalFileNameForExport: useOriginalFileNameForExport ?? false,
      allowCropOutsidePage: allowCropOutsidePage ?? false,
    );
  }

  Future<void> saveGroupingSettings(AppGroupingSettings settings) async {
    await _box?.put(_groupingSettingsKey, <String, Object>{
      'defaultSmartGroupingLevel': settings.defaultSmartGroupingLevel.index,
      'defaultSeparateOddEven': settings.defaultSeparateOddEven,
      'batchCropRecursive': settings.batchCropRecursive,
      'useOriginalFileNameForExport': settings.useOriginalFileNameForExport,
      'allowCropOutsidePage': settings.allowCropOutsidePage,
    });
  }
}
