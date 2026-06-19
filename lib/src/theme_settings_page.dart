import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'models/app_theme_settings.dart';
import 'state/theme_controller.dart';
import 'widgets/windows_window_controls.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = widget.themeController.settings;

    return Scaffold(
      appBar: AppBar(
        title: WindowsDragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.appearanceSettings),
          ),
        ),
        actions: const [
          WindowsWindowControls(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsSection(
            title: l10n.language,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageSettingsDescription,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppLanguageMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(_languageModeLabel(mode)),
                      selected: settings.languageMode == mode,
                      onSelected: (_) => widget.themeController.updateLanguageMode(mode),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: '${l10n.darkMode} / ${l10n.lightMode}',
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
            title: l10n.themeColors,
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
            title: l10n.oledOptimization,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.oledOptimized,
              onChanged: widget.themeController.updateOledOptimized,
              title: Text(l10n.enableOledOptimization),
              subtitle: Text(l10n.oledOnlyInDark),
            ),
          ),
        ],
      ),
    );
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
