import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/app_grouping_settings.dart';
import 'models/cluster_settings.dart';
import 'pdf_editor_page.dart';
import 'services/app_settings_service.dart';
import 'settings_page.dart';
import 'state/pdf_editor_controller.dart';
import 'state/theme_controller.dart';
import 'widgets/status_corner_card.dart';

class PdfCropApp extends StatefulWidget {
  const PdfCropApp({
    required this.themeController,
    super.key,
  });

  final ThemeController themeController;

  @override
  State<PdfCropApp> createState() => _PdfCropAppState();
}

class _PdfCropAppState extends State<PdfCropApp> {
  late final PdfEditorController _controller;
  late final AppSettingsService _appSettingsService;
  bool _draggingPdf = false;
  String? _statusMessage;
  AppGroupingSettings _groupingSettings = const AppGroupingSettings();

  @override
  void initState() {
    super.initState();
    _controller = PdfEditorController();
    _appSettingsService = AppSettingsService();
    _controller.addListener(_onControllerChanged);
    _loadGroupingSettings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Briss'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: _openSettingsPage,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: Stack(
        children: [
          Center(
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
                width: 960,
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
                      _draggingPdf ? '松开即可导入 PDF' : 'PDF 裁边工具',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _draggingPdf
                          ? '把 PDF 文件拖到这个区域，松开后会直接进入编辑页。'
                          : '点击选择 PDF，或直接把 PDF 文件拖到这个区域开始编辑。',
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
                      label: Text('编辑 PDF'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_statusMessage != null)
            StatusCornerCard(
              title: '提示',
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
              title: '正在处理',
              message: _controller.status ?? '正在处理任务...',
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
      _showMessage('打开 PDF 失败：$error');
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
      _showMessage('请拖入一个 PDF 文件。');
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
