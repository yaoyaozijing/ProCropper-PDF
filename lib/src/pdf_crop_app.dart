import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'models/app_grouping_settings.dart';
import 'models/cluster_settings.dart';
import 'pdf_editor_page.dart';
import 'services/android_incoming_pdf_service.dart';
import 'services/app_settings_service.dart';
import 'services/cache_service.dart';
import 'settings_page.dart';
import 'state/pdf_editor_controller.dart';
import 'state/theme_controller.dart';
import 'widgets/status_corner_card.dart';
import 'widgets/windows_window_controls.dart';

class PdfCropApp extends StatefulWidget {
  const PdfCropApp({
    required this.themeController,
    this.initialPdfPath,
    super.key,
  });

  final ThemeController themeController;
  final String? initialPdfPath;

  @override
  State<PdfCropApp> createState() => _PdfCropAppState();
}

class _PdfCropAppState extends State<PdfCropApp> {
  late final PdfEditorController _controller;
  late final AppSettingsService _appSettingsService;
  late final AndroidIncomingPdfService _incomingPdfService;
  late final CacheService _cacheService;
  bool _draggingPdf = false;
  bool _handledInitialPdf = false;
  String? _statusMessage;
  AppGroupingSettings _groupingSettings = const AppGroupingSettings();

  @override
  void initState() {
    super.initState();
    _controller = PdfEditorController();
    _appSettingsService = AppSettingsService();
    _incomingPdfService = AndroidIncomingPdfService();
    _cacheService = CacheService();
    _controller.addListener(_onControllerChanged);
    _loadGroupingSettings();
    _bindIncomingPdfService();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _incomingPdfService.unbind();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadGroupingSettings() async {
    await _appSettingsService.init();
    final settings = _appSettingsService.loadGroupingSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _groupingSettings = settings;
    });
    await _maybeOpenInitialPdf();
  }

  Future<void> _maybeOpenInitialPdf() async {
    if (_handledInitialPdf) {
      return;
    }
    final path = widget.initialPdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    _handledInitialPdf = true;
    if (!_isPdfPath(path)) {
      _showMessage(context.l10n.notPdfInLaunchArgs(path));
      return;
    }
    if (!mounted) {
      return;
    }
    await _openPdfAndNavigate(path);
  }

  Future<void> _bindIncomingPdfService() async {
    try {
      await _incomingPdfService.bind(
        onIncomingPdf: _handleIncomingPdfPath,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.externalPdfFailed(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const WindowsDragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('ProCropper PDF'),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: _openSettingsPage,
            icon: const Icon(Icons.settings_outlined),
          ),
          const WindowsWindowControls(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: DropTarget(
                      onDragEntered: (_) {
                        if (!_draggingPdf) {
                          setState(() => _draggingPdf = true);
                        }
                      },
                      onDragExited: (_) {
                        if (_draggingPdf) {
                          setState(() => _draggingPdf = false);
                        }
                      },
                      onDragDone: (detail) => _handleDropFiles(detail.files),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.all(38),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.alphaBlend(
                                colorScheme.primary.withValues(alpha: _draggingPdf ? 0.24 : 0.16),
                                colorScheme.surfaceContainerLow,
                              ),
                              colorScheme.surfaceContainerLowest,
                            ],
                          ),
                          border: Border.all(
                            color: _draggingPdf ? colorScheme.primary : colorScheme.outlineVariant,
                            width: _draggingPdf ? 2.2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: _draggingPdf ? 0.18 : 0.12),
                              blurRadius: 36,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _draggingPdf ? Icons.file_download_done_rounded : Icons.picture_as_pdf_rounded,
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _draggingPdf ? l10n.releaseToImportPdf : l10n.appName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _draggingPdf
                                  ? l10n.dropPdfToOpen
                                  : l10n.pickOrDropPdf,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: _pickPdfAndOpenEditor,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(l10n.editPdf),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_statusMessage != null)
            StatusCornerCard(
              title: l10n.tips,
              message: _statusMessage!,
              icon: Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
              ),
              bottom: _controller.isBusy ? 186 : 18,
              onClose: _dismissStatusMessage,
            ),
          if (_controller.isBusy)
            StatusCornerCard(
              title: l10n.processing,
              message: _controller.status ?? l10n.processingTask,
              bottom: _statusMessage != null ? 186 : 18,
            ),
        ],
      ),
    );
  }

  Future<void> _pickPdfAndOpenEditor() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null || !mounted) {
        return;
      }
      await _openPdfAndNavigate(path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.openPdfFailedPrefix + error.toString());
    }
  }

  Future<void> _handleDropFiles(List<dynamic> files) async {
    if (_draggingPdf && mounted) {
      setState(() => _draggingPdf = false);
    }
    final dynamic droppedPdf = files.cast<dynamic>().firstWhere(
          (file) => file != null && _isPdfPath(file.path as String),
          orElse: () => null,
        );
    final path = droppedPdf?.path as String?;
    if (path == null) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.pleaseDropPdf);
      return;
    }
    await _openPdfAndNavigate(path);
  }

  Future<void> _openPdfAndNavigate(String path) async {
    await _controller.openFile(
      path,
      initialSettings: ClusterSettings(
        smartGroupingLevel: _groupingSettings.defaultSmartGroupingLevel,
      ),
    );
    if (!mounted || _controller.project == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfEditorPage(
          controller: _controller,
        ),
      ),
    );
    await _clearExportCacheSilently();
  }

  Future<void> _handleIncomingPdfPath(String path) async {
    if (!mounted) {
      return;
    }
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) {
        return;
      }
      await _openPdfAndNavigate(path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.externalPdfOpenFailed(error.toString()));
    }
  }

  bool _isPdfPath(String path) => path.toLowerCase().endsWith('.pdf');

  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(
          themeController: widget.themeController,
        ),
      ),
    );
    await _loadGroupingSettings();
  }

  Future<void> _clearExportCacheSilently() async {
    try {
      await _cacheService.clearTemporaryFiles();
    } catch (_) {
      // Ignore cache cleanup failures when returning to the home page.
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _dismissStatusMessage() {
    if (_statusMessage == null) {
      return;
    }
    setState(() {
      _statusMessage = null;
    });
  }
}
