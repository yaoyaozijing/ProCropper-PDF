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
              _SegmentedSettingsTile<AppLanguageMode>(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.language),
                selectedValue: widget.themeController.settings.languageMode,
                options: AppLanguageMode.values
                    .map(
                      (mode) => _SegmentedOption(
                        value: mode,
                        label: _languageModeLabel(mode),
                      ),
                    )
                    .toList(),
                onChanged: widget.themeController.updateLanguageMode,
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.appearance),
            tiles: [
              _SegmentedSettingsTile<AppThemeMode>(
                leading:
                    widget.themeController.settings.themeMode ==
                        AppThemeMode.system
                    ? const Icon(Icons.brightness_auto_rounded)
                    : widget.themeController.settings.themeMode ==
                          AppThemeMode.light
                    ? const Icon(Icons.light_mode_rounded)
                    : const Icon(Icons.dark_mode_rounded),
                title: Text('${l10n.darkMode} / ${l10n.lightMode}'),
                selectedValue: widget.themeController.settings.themeMode,
                options: AppThemeMode.values
                    .map(
                      (mode) => _SegmentedOption(
                        value: mode,
                        label: _themeModeLabel(mode),
                      ),
                    )
                    .toList(),
                onChanged: widget.themeController.updateThemeMode,
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
                description: Text(l10n.oledOnlyInDark),
                onToggle: widget.themeController.updateOledOptimized,
              ),
              SettingsTile.switchTile(
                initialValue: widget.themeController.settings.eInkOptimized,
                leading: const Icon(Icons.auto_awesome_mosaic_rounded),
                title: Text(l10n.enableEInkOptimization),
                description: Text(l10n.eInkOnlyInLight),
                onToggle: widget.themeController.updateEInkOptimized,
              ),
              if (Platform.isWindows)
                SettingsTile.switchTile(
                  initialValue:
                      widget.themeController.settings.windowsMicaEnabled,
                  leading: const Icon(Icons.blur_on_rounded),
                  title: Text(l10n.enableWindowsMica),
                  description: Text(l10n.windowsMicaDescription),
                  onToggle: widget.themeController.updateWindowsMicaEnabled,
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
              _SegmentedSettingsTile<SmartGroupingLevel>(
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
                selectedValue: _groupingSettings.defaultSmartGroupingLevel,
                options: SmartGroupingLevel.values
                    .map(
                      (level) => _SegmentedOption(
                        value: level,
                        label: _smartGroupingLevelLabel(level),
                      ),
                )
                    .toList(),
                onChanged: _updateDefaultGroupingLevel,
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
}

class _SegmentedSettingsTile<T> extends AbstractSettingsTile {
  const _SegmentedSettingsTile({
    required this.leading,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.description,
    this.enabled = true,
  });

  final Widget leading;
  final Widget title;
  final Widget? description;
  final T selectedValue;
  final List<_SegmentedOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      leading: leading,
      title: title,
      description: description,
      enabled: enabled,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: options
                .map(
                  (option) => ButtonSegment<T>(
                    value: option.value,
                    label: Text(option.label),
                  ),
                )
                .toList(),
            selected: <T>{selectedValue},
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isNotEmpty) {
                      onChanged(selection.first);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _SegmentedOption<T> {
  const _SegmentedOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}
