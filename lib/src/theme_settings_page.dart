import 'package:flutter/material.dart';

import 'models/app_theme_settings.dart';
import 'state/theme_controller.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({
    required this.themeController,
    super.key,
  });

  final ThemeController themeController;

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.themeController.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('外观设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsSection(
            title: '样式',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppStyleMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(_styleModeLabel(mode)),
                  selected: settings.styleMode == mode,
                  onSelected: (_) => widget.themeController.updateStyleMode(mode),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '深浅模式',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppThemeMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(_themeModeLabel(mode)),
                  selected: settings.themeMode == mode,
                  onSelected: (_) => widget.themeController.updateThemeMode(mode),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '主题色',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppAccentMode.values.map((mode) {
                return ChoiceChip(
                  avatar: CircleAvatar(
                    radius: 9,
                    backgroundColor: _accentPreviewColor(mode, theme.brightness),
                  ),
                  label: Text(_accentModeLabel(mode)),
                  selected: settings.accentMode == mode,
                  onSelected: (_) => widget.themeController.updateAccentMode(mode),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'OLED 优化',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.oledOptimized,
              onChanged: widget.themeController.updateOledOptimized,
              title: const Text('启用 OLED 优化'),
              subtitle: const Text('仅在深色主题下生效'),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return '跟随系统';
      case AppThemeMode.light:
        return '浅色';
      case AppThemeMode.dark:
        return '深色';
    }
  }

  String _styleModeLabel(AppStyleMode mode) {
    switch (mode) {
      case AppStyleMode.material:
        return 'Material Design';
      case AppStyleMode.cupertino:
        return 'Cupertino';
      case AppStyleMode.fluent:
        return 'Fluent UI';
    }
  }

  String _accentModeLabel(AppAccentMode mode) {
    switch (mode) {
      case AppAccentMode.system:
        return '跟随系统';
      case AppAccentMode.jade:
        return '玉石绿';
      case AppAccentMode.amber:
        return '琥珀金';
      case AppAccentMode.ocean:
        return '海湾蓝';
      case AppAccentMode.coral:
        return '珊瑚橙';
      case AppAccentMode.ruby:
        return '石榴红';
      case AppAccentMode.graphite:
        return '石墨灰';
    }
  }

  Color _accentPreviewColor(AppAccentMode mode, Brightness brightness) {
    switch (mode) {
      case AppAccentMode.system:
        return brightness == Brightness.dark ? const Color(0xFF7BC4B3) : const Color(0xFF0E6B5C);
      case AppAccentMode.jade:
        return const Color(0xFF0E6B5C);
      case AppAccentMode.amber:
        return const Color(0xFF9A6A14);
      case AppAccentMode.ocean:
        return const Color(0xFF0B6E8A);
      case AppAccentMode.coral:
        return const Color(0xFFB85C38);
      case AppAccentMode.ruby:
        return const Color(0xFF9F2F4F);
      case AppAccentMode.graphite:
        return const Color(0xFF4A5568);
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
