import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/app_grouping_settings.dart';
import 'models/cluster_settings.dart';
import 'services/app_settings_service.dart';
import 'services/cache_service.dart';
import 'state/theme_controller.dart';
import 'theme_settings_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsGroup(
            title: '外观',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('主题设置'),
                subtitle: const Text('深浅模式、主题色与 OLED 优化'),
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
            title: '文档',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '默认分组模式',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '打开 PDF 时默认使用这个智能分组等级。',
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
                      const Text(
                        '默认导出方式',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '用于安卓导出。可选择每次询问，或直接保存、直接分享。',
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
                      title: const Text('清理缓存'),
                      subtitle: const Text('清除应用临时目录中的导出缓存和残留文件。'),
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
            title: '关于',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Briss_Flutter 版本'),
                subtitle: Text(_packageInfo == null ? '读取中...' : _packageInfo!.version),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Third Party Licences'),
                subtitle: const Text('查看第三方依赖许可信息'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LicensePage(
                        applicationName: 'Briss_Flutter',
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
          content: Text(
            deletedCount > 0 ? '已清理 $deletedCount 项缓存。' : '没有发现可清理的缓存。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清理缓存失败：$error'),
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
    switch (level) {
      case SmartGroupingLevel.basic:
        return '基础';
      case SmartGroupingLevel.balanced:
        return '平衡';
      case SmartGroupingLevel.strict:
        return '严格';
    }
  }

  String _smartGroupingLevelDescription(SmartGroupingLevel level) {
    switch (level) {
      case SmartGroupingLevel.basic:
        return '优先按基础尺寸分组，速度更快，细分更少。';
      case SmartGroupingLevel.balanced:
        return '在准确度和分组数量之间保持平衡，适合作为默认模式。';
      case SmartGroupingLevel.strict:
        return '更积极地区分版式差异，适合页面结构变化较多的文档。';
    }
  }

  String _androidExportModeLabel(AndroidExportMode mode) {
    switch (mode) {
      case AndroidExportMode.askEveryTime:
        return '每次询问';
      case AndroidExportMode.save:
        return '直接保存';
      case AndroidExportMode.share:
        return '直接分享';
    }
  }

  String _androidExportModeDescription(AndroidExportMode mode) {
    switch (mode) {
      case AndroidExportMode.askEveryTime:
        return '每次导出时都先选择保存还是分享。';
      case AndroidExportMode.save:
        return '直接进入保存流程，使用系统文档选择器。';
      case AndroidExportMode.share:
        return '直接导出到临时文件，并打开系统分享窗口。';
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
