import 'cluster_settings.dart';

enum AndroidExportMode {
  askEveryTime,
  save,
  share,
}

class AppGroupingSettings {
  const AppGroupingSettings({
    this.defaultSmartGroupingLevel = SmartGroupingLevel.balanced,
    this.androidExportMode = AndroidExportMode.askEveryTime,
  });

  final SmartGroupingLevel defaultSmartGroupingLevel;
  final AndroidExportMode androidExportMode;

  AppGroupingSettings copyWith({
    SmartGroupingLevel? defaultSmartGroupingLevel,
    AndroidExportMode? androidExportMode,
  }) {
    return AppGroupingSettings(
      defaultSmartGroupingLevel:
          defaultSmartGroupingLevel ?? this.defaultSmartGroupingLevel,
      androidExportMode: androidExportMode ?? this.androidExportMode,
    );
  }
}
