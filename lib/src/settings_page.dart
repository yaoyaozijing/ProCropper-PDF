import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'l10n/app_localizations.dart';
import 'models/app_grouping_settings.dart';
import 'models/cluster_settings.dart';
import 'services/app_settings_service.dart';
import 'services/cache_service.dart';
import 'state/theme_controller.dart';
import 'theme_settings_page.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsGroup(
            title: l10n.appearance,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.themeSettings),
                subtitle: Text(
                  '${l10n.darkMode}/${l10n.lightMode}、${l10n.themeColors}、${l10n.oledOptimization}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ThemeSettingsPage(
                        themeController: widget.themeController,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: l10n.documents,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.defaultGroupingMode,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.defaultGroupingModeDescription,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!_groupingSettingsLoaded)
                      const LinearProgressIndicator(minHeight: 2)
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: SmartGroupingLevel.values.map((level) {
                          return ChoiceChip(
                            label: Text(_smartGroupingLevelLabel(level)),
                            selected:
                                _groupingSettings.defaultSmartGroupingLevel == level,
                            onSelected: (_) => _updateDefaultGroupingLevel(level),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      _smartGroupingLevelDescription(
                        _groupingSettings.defaultSmartGroupingLevel,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 22),
                      Text(
                        l10n.defaultExportMode,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.defaultExportModeDescription,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AndroidExportMode.values.map((mode) {
                          return ChoiceChip(
                            label: Text(_androidExportModeLabel(mode)),
                            selected: _groupingSettings.androidExportMode == mode,
                            onSelected: (_) => _updateAndroidExportMode(mode),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    Text(
                      _androidExportModeDescription(
                        _groupingSettings.androidExportMode,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _clearingCache
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.cleaning_services_outlined),
                      title: Text(l10n.clearCache),
                      subtitle: Text(l10n.clearCacheDescription),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      enabled: !_clearingCache,
                      onTap: _clearingCache ? null : _clearCache,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: l10n.about,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.versionLabel),
                subtitle: Text(_packageInfo == null ? l10n.loading : _packageInfo!.version),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.thirdPartyLicenses),
                subtitle: Text(l10n.thirdPartyLicensesDescription),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LicensePage(
                        applicationName: 'ProCropper PDF',
                        applicationVersion: _packageInfo == null ? '0.1.0' : _packageInfo!.version,
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

  Future<void> _updateAndroidExportMode(AndroidExportMode mode) async {
    if (_groupingSettings.androidExportMode == mode) {
      return;
    }
    final nextSettings = _groupingSettings.copyWith(
      androidExportMode: mode,
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

  String _androidExportModeLabel(AndroidExportMode mode) {
    final l10n = AppLocalizations.current;
    switch (mode) {
      case AndroidExportMode.askEveryTime:
        return l10n.askEveryTime;
      case AndroidExportMode.save:
        return l10n.saveDirectly;
      case AndroidExportMode.share:
        return l10n.shareDirectly;
    }
  }

  String _androidExportModeDescription(AndroidExportMode mode) {
    final l10n = AppLocalizations.current;
    switch (mode) {
      case AndroidExportMode.askEveryTime:
        return l10n.askEveryTimeDescription;
      case AndroidExportMode.save:
        return l10n.saveDirectlyDescription;
      case AndroidExportMode.share:
        return l10n.shareDirectlyDescription;
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
