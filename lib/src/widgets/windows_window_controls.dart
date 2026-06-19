import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';

class WindowsDragToMoveArea extends StatelessWidget {
  const WindowsDragToMoveArea({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return child;
    }
    return DragToMoveArea(child: child);
  }
}

class WindowsWindowControls extends StatefulWidget {
  const WindowsWindowControls({super.key});

  @override
  State<WindowsWindowControls> createState() => _WindowsWindowControlsState();
}

class _WindowsWindowControlsState extends State<WindowsWindowControls>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) {
      return;
    }
    windowManager.addListener(this);
    _refreshWindowState();
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowCaptionButton(
          tooltip: l10n.minimize,
          glyph: '\uE921',
          onPressed: () => windowManager.minimize(),
        ),
        _WindowCaptionButton(
          tooltip: _isMaximized ? l10n.restore : l10n.maximize,
          glyph: _isMaximized ? '\uE923' : '\uE922',
          onPressed: _toggleMaximize,
        ),
        _WindowCaptionButton(
          tooltip: l10n.close,
          glyph: '\uE8BB',
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }

  @override
  void onWindowMaximize() {
    _setMaximized(true);
  }

  @override
  void onWindowUnmaximize() {
    _setMaximized(false);
  }

  Future<void> _refreshWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    if (!mounted) {
      return;
    }
    _setMaximized(isMaximized);
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
      return;
    }
    await windowManager.maximize();
  }

  void _setMaximized(bool value) {
    if (!mounted || _isMaximized == value) {
      return;
    }
    setState(() {
      _isMaximized = value;
    });
  }
}

class _WindowCaptionButton extends StatelessWidget {
  const _WindowCaptionButton({
    required this.tooltip,
    required this.glyph,
    required this.onPressed,
  });

  final String tooltip;
  final String glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: kToolbarHeight,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Text(
          glyph,
          style: TextStyle(
            fontFamily: 'Segoe MDL2 Assets',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
