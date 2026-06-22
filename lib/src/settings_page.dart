import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';

import 'l10n/app_localizations.dart';
import 'models/app_grouping_settings.dart';
import 'models/app_theme_settings.dart';
import 'models/cluster_settings.dart';
import 'services/app_settings_service.dart';
import 'services/cache_service.dart';
import 'services/windowing_service.dart';
import 'state/theme_controller.dart';
import 'widgets/windows_window_controls.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.themeController,
    super.key,
  });

  final ThemeController themeController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo? _packageInfo;
  late final AppSettingsService _appSettingsService;
  late final CacheService _cacheService;
  AppGroupingSettings _groupingSettings = const AppGroupingSettings();
  bool _groupingSettingsLoaded = false;
  bool _clearingCache = false;

  @override
  void initState() {
    super.initState();
    _appSettingsService = AppSettingsService();
    _cacheService = CacheService();
    _loadPackageInfo();
    _loadGroupingSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBrightness = _effectiveThemeBrightness();
    final oledConfigurable = effectiveBrightness == Brightness.dark;
    final eInkConfigurable = effectiveBrightness == Brightness.light;
    final micaConfigurable =
        Platform.isWindows &&
        !(widget.themeController.settings.eInkOptimized &&
            effectiveBrightness == Brightness.light);

    return Scaffold(
      appBar: AppBar(
        title: WindowsDragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.settings),
          ),
        ),
        actions: const [
          WindowsWindowControls(),
          SizedBox(width: 8),
        ],
      ),
      body: SettingsList(
        platform: DevicePlatform.android,
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          settingsSectionBackground: Theme.of(context).cardColor,
          dividerColor: colorScheme.outlineVariant,
          tileDescriptionTextColor: colorScheme.onSurfaceVariant,
          leadingIconsColor: colorScheme.primary,
          settingsTileTextColor: colorScheme.onSurface,
          inactiveTitleColor: colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        darkTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          settingsSectionBackground: Theme.of(context).cardColor,
          dividerColor: colorScheme.outlineVariant,
          tileDescriptionTextColor: colorScheme.onSurfaceVariant,
          leadingIconsColor: colorScheme.primary,
          settingsTileTextColor: colorScheme.onSurface,
          inactiveTitleColor: colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        sections: [
          SettingsSection(
            title: Text(l10n.language),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.language),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppLanguageMode>(
                    value: widget.themeController.settings.languageMode,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (value) {
                      if (value != null) {
                        widget.themeController.updateLanguageMode(value);
                      }
                    },
                    items: AppLanguageMode.values
                        .map(
                          (mode) => DropdownMenuItem<AppLanguageMode>(
                            value: mode,
                            child: Text(_languageModeLabel(mode)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.appearance),
            tiles: [
              SettingsTile(
                leading:
                    widget.themeController.settings.themeMode ==
                        AppThemeMode.system
                    ? const Icon(Icons.brightness_auto_rounded)
                    : widget.themeController.settings.themeMode ==
                          AppThemeMode.light
                    ? const Icon(Icons.light_mode_rounded)
                    : const Icon(Icons.dark_mode_rounded),
                title: Text('${l10n.darkMode} / ${l10n.lightMode}'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppThemeMode>(
                    value: widget.themeController.settings.themeMode,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (value) {
                      if (value != null) {
                        widget.themeController.updateThemeMode(value);
                      }
                    },
                    items: AppThemeMode.values
                        .map(
                          (mode) => DropdownMenuItem<AppThemeMode>(
                            value: mode,
                            child: Text(_themeModeLabel(mode)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              SettingsTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                title: Text(l10n.themeColors),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppAccentMode>(
                    value: widget.themeController.settings.accentMode,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (value) {
                      if (value != null) {
                        widget.themeController.updateAccentMode(value);
                      }
                    },
                    items: AppAccentMode.values
                        .map(
                          (mode) => DropdownMenuItem<AppAccentMode>(
                            value: mode,
                            child: Text(_accentModeLabel(mode)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              SettingsTile.switchTile(
                initialValue: widget.themeController.settings.oledOptimized,
                leading: const Icon(Icons.contrast_rounded),
                title: Text(l10n.enableOledOptimization),
                description: oledConfigurable
                    ? null
                    : Text(l10n.oledConfigurableOnlyInDark),
                enabled: oledConfigurable,
                onToggle: oledConfigurable
                    ? widget.themeController.updateOledOptimized
                    : null,
              ),
              SettingsTile.switchTile(
                initialValue: widget.themeController.settings.eInkOptimized,
                leading: const Icon(Icons.auto_awesome_mosaic_rounded),
                title: Text(l10n.enableEInkOptimization),
                description: eInkConfigurable
                    ? null
                    : Text(l10n.eInkConfigurableOnlyInLight),
                enabled: eInkConfigurable,
                onToggle: eInkConfigurable
                    ? widget.themeController.updateEInkOptimized
                    : null,
              ),
              if (Platform.isWindows)
                SettingsTile.switchTile(
                  initialValue:
                      widget.themeController.settings.windowsMicaEnabled,
                  leading: const Icon(Icons.blur_on_rounded),
                  title: Text(l10n.enableWindowsMica),
                  description: micaConfigurable
                      ? null
                      : Text(l10n.windowsMicaUnavailableWhenEInk),
                  enabled: micaConfigurable,
                  onToggle: micaConfigurable
                      ? widget.themeController.updateWindowsMicaEnabled
                      : null,
                ),
              if (isFlutterWindowingAvailable)
                SettingsTile.switchTile(
                  initialValue: widget.themeController.settings.multiWindowMode,
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: Text(l10n.enableMultiWindowMode),
                  description: Text(l10n.multiWindowModeDescription),
                  onToggle: widget.themeController.updateMultiWindowMode,
                ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.documents),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(l10n.defaultGroupingMode),
                description: Text(
                  _groupingSettingsLoaded
                      ? _smartGroupingLevelDescription(
                          _groupingSettings.defaultSmartGroupingLevel,
                        )
                      : l10n.loading,
                ),
                enabled: _groupingSettingsLoaded,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<SmartGroupingLevel>(
                    value: _groupingSettings.defaultSmartGroupingLevel,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: _groupingSettingsLoaded
                        ? (value) {
                            if (value != null) {
                              _updateDefaultGroupingLevel(value);
                            }
                          }
                        : null,
                    items: SmartGroupingLevel.values
                        .map(
                          (level) => DropdownMenuItem<SmartGroupingLevel>(
                            value: level,
                            child: Text(_smartGroupingLevelLabel(level)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              SettingsTile.switchTile(
                initialValue: _groupingSettings.defaultSeparateOddEven,
                leading: const Icon(Icons.filter_2_outlined),
                title: Text(l10n.defaultSeparateOddEvenForNewPdf),
                description: Text(
                  l10n.defaultSeparateOddEvenForNewPdfDescription,
                ),
                onToggle: _groupingSettingsLoaded
                    ? _updateDefaultSeparateOddEven
                    : null,
              ),
              SettingsTile.switchTile(
                initialValue: _groupingSettings.batchCropRecursive,
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(l10n.batchCropRecursive),
                description: Text(l10n.batchCropRecursiveDescription),
                onToggle: _groupingSettingsLoaded
                    ? _updateBatchCropRecursive
                    : null,
              ),
              SettingsTile.switchTile(
                initialValue: _groupingSettings.useOriginalFileNameForExport,
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: Text(l10n.useOriginalFileNameForExport),
                description: Text(
                  l10n.useOriginalFileNameForExportDescription,
                ),
                onToggle: _groupingSettingsLoaded
                    ? _updateUseOriginalFileNameForExport
                    : null,
              ),
              SettingsTile.switchTile(
                initialValue: _groupingSettings.allowCropOutsidePage,
                leading: const Icon(Icons.crop_free_outlined),
                title: Text(l10n.allowCropOutsidePage),
                description: Text(l10n.allowCropOutsidePageDescription),
                onToggle: _groupingSettingsLoaded
                    ? _updateAllowCropOutsidePage
                    : null,
              ),
              SettingsTile.navigation(
                leading: _clearingCache
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.cleaning_services_outlined),
                title: Text(l10n.clearCache),
                description: Text(l10n.clearCacheDescription),
                enabled: !_clearingCache,
                onPressed: _clearingCache ? null : (_) => _clearCache(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.about),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.versionLabel),
                value: Text(
                  _packageInfo == null ? l10n.loading : _packageInfo!.version,
                ),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.thirdPartyLicenses),
                description: Text(l10n.thirdPartyLicensesDescription),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LicensePage(
                        applicationName: 'ProCropper PDF',
                        applicationVersion:
                            _packageInfo == null ? '0.2.0' : _packageInfo!.version,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = packageInfo;
      });
    }
  }

  Future<void> _loadGroupingSettings() async {
    await _appSettingsService.init();
    final groupingSettings = _appSettingsService.loadGroupingSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _groupingSettings = groupingSettings;
      _groupingSettingsLoaded = true;
    });
  }

  Future<void> _updateDefaultGroupingLevel(SmartGroupingLevel level) async {
    if (_groupingSettings.defaultSmartGroupingLevel == level) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      defaultSmartGroupingLevel: level,
    );
    setState(() {
      _groupingSettings = nextSettings;
    });
    await _appSettingsService.saveGroupingSettings(nextSettings);
  }

  Future<void> _updateDefaultSeparateOddEven(bool value) async {
    if (_groupingSettings.defaultSeparateOddEven == value) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      defaultSeparateOddEven: value,
    );
    setState(() {
      _groupingSettings = nextSettings;
    });
    await _appSettingsService.saveGroupingSettings(nextSettings);
  }

  Future<void> _updateBatchCropRecursive(bool value) async {
    if (_groupingSettings.batchCropRecursive == value) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      batchCropRecursive: value,
    );
    setState(() {
      _groupingSettings = nextSettings;
    });
    await _appSettingsService.saveGroupingSettings(nextSettings);
  }

  Future<void> _updateUseOriginalFileNameForExport(bool value) async {
    if (_groupingSettings.useOriginalFileNameForExport == value) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      useOriginalFileNameForExport: value,
    );
    setState(() {
      _groupingSettings = nextSettings;
    });
    await _appSettingsService.saveGroupingSettings(nextSettings);
  }

  Future<void> _updateAllowCropOutsidePage(bool value) async {
    if (_groupingSettings.allowCropOutsidePage == value) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      allowCropOutsidePage: value,
    );
    setState(() {
      _groupingSettings = nextSettings;
    });
    await _appSettingsService.saveGroupingSettings(nextSettings);
  }

  Future<void> _clearCache() async {
    setState(() {
      _clearingCache = true;
    });
    try {
      final deletedCount = await _cacheService.clearTemporaryFiles();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.current.cacheCleared(deletedCount)),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.current.clearCacheFailed(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _clearingCache = false;
        });
      }
    }
  }

  String _smartGroupingLevelLabel(SmartGroupingLevel level) {
    final l10n = AppLocalizations.current;
    switch (level) {
      case SmartGroupingLevel.basic:
        return l10n.groupingLevelBasic;
      case SmartGroupingLevel.balanced:
        return l10n.groupingModeBalanced;
      case SmartGroupingLevel.strict:
        return l10n.groupingLevelStrict;
    }
  }

  String _smartGroupingLevelDescription(SmartGroupingLevel level) {
    final l10n = AppLocalizations.current;
    switch (level) {
      case SmartGroupingLevel.basic:
        return l10n.groupingModeBasicDescription;
      case SmartGroupingLevel.balanced:
        return l10n.groupingModeBalancedDescription;
      case SmartGroupingLevel.strict:
        return l10n.groupingModeStrictDescription;
    }
  }

  String _languageModeLabel(AppLanguageMode mode) {
    final l10n = AppLocalizations.current;
    switch (mode) {
      case AppLanguageMode.system:
        return l10n.systemMode;
      case AppLanguageMode.zhCn:
        return l10n.simplifiedChinese;
      case AppLanguageMode.en:
        return l10n.english;
      case AppLanguageMode.ja:
        return l10n.japanese;
    }
  }

  String _themeModeLabel(AppThemeMode mode) {
    final l10n = AppLocalizations.current;
    switch (mode) {
      case AppThemeMode.system:
        return l10n.systemMode;
      case AppThemeMode.light:
        return l10n.lightMode;
      case AppThemeMode.dark:
        return l10n.darkMode;
    }
  }

  String _accentModeLabel(AppAccentMode mode) {
    final l10n = AppLocalizations.current;
    switch (mode) {
      case AppAccentMode.system:
        return l10n.systemMode;
      case AppAccentMode.jade:
        return l10n.jade;
      case AppAccentMode.amber:
        return l10n.amber;
      case AppAccentMode.ocean:
        return l10n.ocean;
      case AppAccentMode.coral:
        return l10n.coral;
      case AppAccentMode.ruby:
        return l10n.ruby;
      case AppAccentMode.graphite:
        return l10n.graphite;
    }
  }

  Brightness _effectiveThemeBrightness() {
    final mode = widget.themeController.settings.themeMode;
    return switch (mode) {
      AppThemeMode.system => View.of(context).platformDispatcher.platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
  }
}
