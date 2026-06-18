import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
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
