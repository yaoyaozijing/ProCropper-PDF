import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations current = AppLocalizations(const Locale('zh', 'CN'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(value != null, 'No AppLocalizations found in context.');
    return value!;
  }

  bool get isZh => locale.languageCode.toLowerCase().startsWith('zh');
  bool get isJa => locale.languageCode.toLowerCase().startsWith('ja');

  String get appName => 'ProCropper PDF';
  String get settings => isZh ? '设置' : (isJa ? '設定' : 'Settings');
  String get themeSettings => isZh ? '主题设置' : (isJa ? 'テーマ設定' : 'Theme Settings');
  String get appearanceSettings => isZh ? '外观设置' : (isJa ? '外観設定' : 'Appearance Settings');
  String get tips => isZh ? '提示' : (isJa ? 'ヒント' : 'Tip');
  String get processing => isZh ? '正在处理' : (isJa ? '処理中' : 'Processing');
  String get processingTask => isZh
      ? '正在处理任务...'
      : (isJa ? 'タスクを処理しています...' : 'Processing task...');
  String get cropPdf => isZh ? '裁切 PDF' : (isJa ? 'PDFをトリミング' : 'Crop PDF');
  String get batchCrop => isZh ? '批量裁边' : (isJa ? '一括トリミング' : 'Batch Crop');
  String get batchCropUnsupported => isZh
      ? '当前平台暂不支持批量裁边。'
      : (isJa
          ? 'このプラットフォームでは一括トリミングを利用できません。'
          : 'Batch crop is not supported on this platform.');
  String get batchCropDialogTitle => isZh
      ? '批量裁边'
      : (isJa ? '一括トリミング' : 'Batch Crop');
  String get batchCropDialogDescription => isZh
      ? '选择输入和输出目录，并配置本次批量裁边任务。'
      : (isJa
          ? '入力フォルダーと出力フォルダーを選択し、今回の一括トリミング設定を行います。'
          : 'Choose the input and output folders, then configure this batch crop task.');
  String get batchCropPathSection => isZh ? '路径' : (isJa ? 'フォルダー' : 'Folders');
  String get batchCropOptionsSection => isZh ? '选项' : (isJa ? 'オプション' : 'Options');
  String get batchCropRecursive => isZh
      ? '支持递归子目录，并保持目录结构导出'
      : (isJa
          ? 'サブフォルダーを再帰的に含め、フォルダー構成を維持して書き出す'
          : 'Include subfolders and preserve folder structure on export');
  String get batchCropRecursiveDescription => isZh
      ? '开启后会递归扫描子目录，并按原有相对路径导出裁边后的 PDF。'
      : (isJa
          ? '有効にするとサブフォルダーも再帰的に走査し、トリミング後の PDF を元の相対パス構成のまま書き出します。'
          : 'When enabled, subfolders are scanned recursively and cropped PDFs keep their relative paths.');
  String get useOriginalFileNameForExport => isZh
      ? '导出时使用原文件名'
      : (isJa ? '書き出し時に元のファイル名を使う' : 'Use Original File Name on Export');
  String get useOriginalFileNameForExportDescription => isZh
      ? '开启后，导出文件会直接使用原 PDF 文件名，不再自动追加“裁边后”后缀。'
      : (isJa
          ? '有効にすると、書き出しファイルは元の PDF ファイル名をそのまま使い、トリミング後の接尾辞を追加しません。'
          : 'When enabled, exports keep the original PDF file name instead of appending a cropped suffix.');
  String get selectBatchInputDirectory => isZh
      ? '选择待处理目录'
      : (isJa ? '入力フォルダーを選択' : 'Select Input Folder');
  String get selectBatchOutputDirectory => isZh
      ? '选择导出目录'
      : (isJa ? '出力フォルダーを選択' : 'Select Output Folder');
  String get batchPathNotSelected => isZh ? '未选择' : (isJa ? '未選択' : 'Not selected');
  String get chooseFolder => isZh ? '选择文件夹' : (isJa ? 'フォルダーを選択' : 'Choose Folder');
  String get changeFolder => isZh ? '更改文件夹' : (isJa ? 'フォルダーを変更' : 'Change Folder');
  String get startBatchCrop => isZh ? '开始批量裁边' : (isJa ? '一括トリミング開始' : 'Start Batch Crop');
  String get batching => isZh ? '批量处理中' : (isJa ? '一括処理中' : 'Batch Processing');
  String get batchPreparing => isZh
      ? '正在准备批量裁边任务...'
      : (isJa ? '一括トリミングの準備中...' : 'Preparing batch crop task...');
  String batchScanningDirectory(String path) => isZh
      ? '正在扫描目录：$path'
      : (isJa ? 'フォルダーをスキャンしています: $path' : 'Scanning folder: $path');
  String batchNoPdfFound(String path) => isZh
      ? '所选目录中没有 PDF 文件：$path'
      : (isJa ? '選択したフォルダーに PDF が見つかりません: $path' : 'No PDF files were found in: $path');
  String get batchFailedToReadSourceFile => isZh
      ? '读取源文件失败'
      : (isJa ? '元ファイルの読み込みに失敗しました' : 'Failed to read source file');
  String batchProcessingFile(
    int current,
    int total,
    String fileName,
  ) => isZh
      ? '正在处理第 $current / $total 个文件：$fileName'
      : (isJa
          ? 'ファイル $current / $total を処理しています: $fileName'
          : 'Processing file $current / $total: $fileName');
  String batchCompleted(int successCount, int failedCount) => isZh
      ? '批量裁边完成，成功 $successCount 个，失败 $failedCount 个。'
      : (isJa
          ? '一括トリミングが完了しました。成功 $successCount 件、失敗 $failedCount 件。'
          : 'Batch crop finished. $successCount succeeded, $failedCount failed.');
  String batchFailedWithDetails(String summary) => isZh
      ? '批量裁边失败：$summary'
      : (isJa ? '一括トリミングに失敗しました: $summary' : 'Batch crop failed: $summary');
  String batchPartialFailureSummary(
    int successCount,
    int failedCount,
    String details,
  ) => isZh
      ? '批量裁边完成，成功 $successCount 个，失败 $failedCount 个。\n$details'
      : (isJa
          ? '一括トリミングが完了しました。成功 $successCount 件、失敗 $failedCount 件。\n$details'
          : 'Batch crop finished. $successCount succeeded, $failedCount failed.\n$details');
  String get releaseToImportPdf =>
      isZh ? '松开即可导入 PDF' : (isJa ? 'ドロップして PDF を取り込む' : 'Release to import PDF');
  String get dropPdfToOpen => isZh
      ? '把 PDF 文件拖到这个区域，松开后会直接进入编辑页。'
      : (isJa ? 'この領域に PDF ファイルをドロップすると、直接エディターで開きます。' : 'Drop a PDF file here to open it directly in the editor.');
  String get pickOrDropPdf => isZh
      ? '点击选择 PDF，或直接把 PDF 文件拖到这个区域开始编辑。'
      : (isJa ? 'PDF を選択するか、この領域にドラッグして編集を開始します。' : 'Pick a PDF or drag one into this area to start editing.');
  String get pickPdfOnly => isZh
      ? '点击选择 PDF 开始编辑。'
      : (isJa ? 'PDF を選択して編集を開始します。' : 'Pick a PDF to start editing.');
  String get openPdfFailedPrefix =>
      isZh ? '打开 PDF 失败：' : (isJa ? 'PDF を開けませんでした: ' : 'Failed to open PDF: ');
  String get passwordProtectedPdf =>
      isZh ? '受密码保护的 PDF' : (isJa ? 'パスワード保護された PDF' : 'Password-Protected PDF');
  String passwordRequiredForPdf(String fileName) => isZh
      ? '请输入“$fileName”的密码。'
      : (isJa ? '"$fileName" のパスワードを入力してください。' : 'Enter the password for "$fileName".');
  String get pdfPassword => isZh ? '密码' : (isJa ? 'パスワード' : 'Password');
  String get wrongPdfPassword =>
      isZh ? '密码错误，请重试。' : (isJa ? 'パスワードが正しくありません。再試行してください。' : 'Incorrect password. Please try again.');
  String get passwordRequiredToOpenPdf => isZh
      ? '该 PDF 需要密码才能打开。'
      : (isJa ? 'この PDF を開くにはパスワードが必要です。' : 'This PDF requires a password to open.');
  String batchPasswordPromptTitle(String fileName) => isZh
      ? '请输入“$fileName”的密码'
      : (isJa ? '"$fileName" のパスワードを入力' : 'Enter password for "$fileName"');
  String get batchPasswordSkipped => isZh
      ? '已取消输入密码，跳过该文件。'
      : (isJa ? 'パスワード入力がキャンセルされたため、このファイルをスキップしました。' : 'Password entry was cancelled, and this file was skipped.');
  String get pleaseDropPdf =>
      isZh ? '请拖入一个 PDF 文件。' : (isJa ? 'PDF ファイルをドロップしてください。' : 'Please drop a PDF file.');
  String notPdfInLaunchArgs(String path) => isZh
      ? '启动参数中的文件不是 PDF：$path'
      : (isJa ? '起動引数のファイルは PDF ではありません: $path' : 'The launch argument is not a PDF: $path');
  String externalPdfFailed(String error) => isZh
      ? '接收外部 PDF 失败：$error'
      : (isJa ? '外部 PDF の受信に失敗しました: $error' : 'Failed to receive external PDF: $error');
  String externalPdfOpenFailed(String error) => isZh
      ? '打开外部 PDF 失败：$error'
      : (isJa ? '外部 PDF を開けませんでした: $error' : 'Failed to open external PDF: $error');
  String get close => isZh ? '关闭' : (isJa ? '閉じる' : 'Close');
  String get cancel => isZh ? '取消' : (isJa ? 'キャンセル' : 'Cancel');
  String get apply => isZh ? '应用' : (isJa ? '適用' : 'Apply');
  String get save => isZh ? '保存' : (isJa ? '保存' : 'Save');
  String get share => isZh ? '分享' : (isJa ? '共有' : 'Share');
  String get export => isZh ? '导出' : (isJa ? '書き出し' : 'Export');
  String get open => isZh ? '打开' : (isJa ? '開く' : 'Open');
  String get reopenPdf => isZh ? '重新打开 PDF' : (isJa ? 'PDF を再度開く' : 'Reopen PDF');
  String get openPdf => isZh ? '打开 PDF' : (isJa ? 'PDF を開く' : 'Open PDF');
  String get revealFile => isZh ? '定位文件' : (isJa ? 'ファイルを表示' : 'Reveal File');
  String get exportCompleted => isZh ? '导出完成' : (isJa ? '書き出し完了' : 'Export Complete');
  String get exportFailed => isZh ? '导出失败' : (isJa ? '書き出し失敗' : 'Export Failed');
  String get exportingInBackground =>
      isZh ? '正在后台导出' : (isJa ? 'バックグラウンドで書き出し中' : 'Exporting in Background');
  String get exportShareOpened =>
      isZh ? '分享窗口已打开。' : (isJa ? '共有シートを開きました。' : 'Share sheet opened.');
  String exportFailedWithError(String error) =>
      '${isZh ? '导出失败：' : (isJa ? '書き出しに失敗しました: ' : 'Export failed: ')}$error';
  String get chooseExportMethodTitle =>
      isZh ? '导出 PDF' : (isJa ? 'PDF を書き出し' : 'Export PDF');
  String get chooseExportMethodDescription => isZh
      ? '请选择导出方式。保存会写入你选择的位置，分享会先导出再打开系统分享窗口。'
      : (isJa
          ? '書き出し方法を選択してください。保存は選択した場所に書き込み、共有は先に書き出してからシステム共有シートを開きます。'
          : 'Choose how to export. Save writes to your chosen location, while Share exports first and then opens the system share sheet.');
  String get doNotAskAgain => isZh ? '请勿询问' : (isJa ? '今後は確認しない' : "Don't ask again");
  String get rememberExportChoice => isZh
      ? '之后默认使用本次选择的导出方式。'
      : (isJa ? '今後はこの書き出し方法を既定で使います。' : 'Use this export method by default from now on.');
  String get saveCroppedPdf =>
      isZh ? '保存裁边后的 PDF' : (isJa ? 'トリミング後の PDF を保存' : 'Save Cropped PDF');
  String get clusterPanelOpen =>
      isZh ? '打开分组面板' : (isJa ? 'グループパネルを開く' : 'Open Groups Panel');
  String get collapseClusterPanel =>
      isZh ? '收起分组栏' : (isJa ? 'グループパネルを折りたたむ' : 'Collapse Groups Panel');
  String get expandClusterPanel =>
      isZh ? '展开分组栏' : (isJa ? 'グループパネルを展開' : 'Expand Groups Panel');
  String get collapseToolbar =>
      isZh ? '收起工具栏' : (isJa ? 'ツールバーを折りたたむ' : 'Collapse Toolbar');
  String get expandToolbar =>
      isZh ? '展开工具栏' : (isJa ? 'ツールバーを展開' : 'Expand Toolbar');
  String get toolMenu => isZh ? '工具菜单' : (isJa ? 'ツールメニュー' : 'Tools Menu');
  String get toolSection => isZh ? '工具' : (isJa ? 'ツール' : 'Tools');
  String get cropPreview => isZh ? '裁切预览' : (isJa ? 'トリミングプレビュー' : 'Crop Preview');
  String previewPageLabel(int pageNumber) =>
      isZh ? '第 $pageNumber 页' : (isJa ? '$pageNumber ページ' : 'Page $pageNumber');
  String get previousPage => isZh ? '上一页' : (isJa ? '前のページ' : 'Previous');
  String get nextPage => isZh ? '下一页' : (isJa ? '次のページ' : 'Next');
  String get pageNumber => isZh ? '页码' : (isJa ? 'ページ番号' : 'Page');
  String pageCountWithCurrent(int current, int total) =>
      isZh ? '$current / $total' : '$current / $total';
  String totalPageCount(int total) =>
      isZh ? '共 $total 页' : (isJa ? '全 $total ページ' : '$total pages total');
  String get zoomOut => isZh ? '缩小' : (isJa ? '縮小' : 'Zoom Out');
  String get zoomIn => isZh ? '放大' : (isJa ? '拡大' : 'Zoom In');
  String get recalculateCurrent => isZh ? '计算当前' : (isJa ? '現在を再計算' : 'Recalculate Current');
  String get recalculateAll => isZh ? '计算全部' : (isJa ? 'すべて再計算' : 'Recalculate All');
  String get addCropRect => isZh ? '添加裁剪框' : (isJa ? 'トリミング枠を追加' : 'Add Crop Box');
  String get removeCurrentRect => isZh ? '移除当前框' : (isJa ? '現在の枠を削除' : 'Remove Current Box');
  String get splitHorizontal => isZh ? '水平拆分' : (isJa ? '横方向に分割' : 'Split Horizontally');
  String get splitVertical => isZh ? '垂直拆分' : (isJa ? '縦方向に分割' : 'Split Vertically');
  String get expandToFullPage => isZh ? '扩展到全页面' : (isJa ? 'ページ全体に広げる' : 'Expand to Full Page');
  String get copyPreset => isZh ? '复制方案' : (isJa ? 'プリセットをコピー' : 'Copy Preset');
  String get pastePreset => isZh ? '粘贴方案' : (isJa ? 'プリセットを貼り付け' : 'Paste Preset');
  String get applyToAll => isZh ? '应用到全部' : (isJa ? 'すべてに適用' : 'Apply to All');
  String get applyToEven => isZh ? '应用到偶数' : (isJa ? '偶数に適用' : 'Apply to Even');
  String get applyToOdd => isZh ? '应用到奇数' : (isJa ? '奇数に適用' : 'Apply to Odd');
  String summaryText({
    required int pageCount,
    required int clusterCount,
    required String excludedText,
    required String filterText,
  }) {
    return isZh
        ? '共 $pageCount 页，$clusterCount 个分组，排除$excludedText，过滤 $filterText'
        : (isJa
            ? '全 $pageCount ページ、$clusterCount グループ、除外 $excludedText、フィルター $filterText'
            : '$pageCount pages, $clusterCount groups, excluded $excludedText, filter $filterText');
  }

  String get noExcludedPages => isZh ? '无' : (isJa ? 'なし' : 'none');
  String excludedPagesLabel(String ranges) =>
      isZh ? '第 $ranges 页' : (isJa ? '$ranges ページ' : 'pages $ranges');
  String get locatePageHint =>
      isZh ? '输入页码定位分组' : (isJa ? 'ページ番号を入力してグループを探す' : 'Enter a page number to locate its group');
  String get confirmLocate =>
      isZh ? '确认定位' : (isJa ? '移動' : 'Confirm');
  String get locate => isZh ? '定位' : (isJa ? '検索' : 'Locate');
  String get collapse => isZh ? '收起' : (isJa ? '折りたたむ' : 'Collapse');
  String get reset => isZh ? '重置' : (isJa ? 'リセット' : 'Reset');
  String get merge => isZh ? '合并' : (isJa ? '結合' : 'Merge');
  String get create => isZh ? '新建' : (isJa ? '作成' : 'Create');
  String get regroupSettings =>
      isZh ? '重新分组设置' : (isJa ? '再グループ化設定' : 'Regroup Settings');
  String get separateOddEven => isZh ? '区分奇偶页' : (isJa ? '奇数・偶数ページを分ける' : 'Separate Odd/Even Pages');
  String get separateOddEvenDescription => isZh
      ? '关闭后，奇偶页会按尺寸合并到同一类分组。'
      : (isJa
          ? '無効にすると、奇数ページと偶数ページが同じサイズベースのグループにまとめられることがあります。'
          : 'When disabled, odd and even pages can be merged into the same size-based groups.');
  String get smartGroupingLevel =>
      isZh ? '智能分组等级' : (isJa ? 'スマートグループ化レベル' : 'Smart Grouping Level');
  String get edgeFilterPercentage =>
      isZh ? '四边过滤百分比' : (isJa ? '四辺の除外率' : 'Edge Filter Percentages');
  String get edgeFilterDescription => isZh
      ? '会先忽略页面四周对应比例的区域，再进行分组分析和自动识别。'
      : (isJa
          ? '指定した割合のページ周辺領域を先に無視してから、グループ分析と自動認識を行います。'
          : 'These edge percentages are ignored before grouping analysis and auto-detection.');
  String get ignoreHeaderFooter =>
      isZh ? '忽略页眉页脚' : (isJa ? 'ヘッダーとフッターを無視' : 'Ignore Header/Footer');
  String get ignoreSideMarks =>
      isZh ? '忽略侧边标记' : (isJa ? '側面マークを無視' : 'Ignore Side Marks');
  String get gentleFilter => isZh ? '温和过滤' : (isJa ? '弱めのフィルター' : 'Gentle Filter');
  String get leftPercent => isZh ? '左 %' : (isJa ? '左 %' : 'Left %');
  String get topPercent => isZh ? '上 %' : (isJa ? '上 %' : 'Top %');
  String get rightPercent => isZh ? '右 %' : (isJa ? '右 %' : 'Right %');
  String get bottomPercent => isZh ? '下 %' : (isJa ? '下 %' : 'Bottom %');
  String get excludedPages => isZh ? '排除页码' : (isJa ? '除外ページ' : 'Excluded Pages');
  String get pageRangeExample => isZh ? '例如：1, 3, 5-8' : (isJa ? '例: 1, 3, 5-8' : 'For example: 1, 3, 5-8');
  String get excludedPagesDescription => isZh
      ? '这些页面不会参与自动分组与预览生成。'
      : (isJa ? 'これらのページは自動グループ化とプレビュー生成の対象外になります。' : 'These pages are excluded from automatic grouping and preview generation.');
  String regroupFailed(String error) =>
      '${isZh ? '重新分组失败：' : (isJa ? '再グループ化に失敗しました: ' : 'Failed to regroup: ')}$error';
  String mergeFailed(String error) =>
      '${isZh ? '合并分组失败：' : (isJa ? 'グループの結合に失敗しました: ' : 'Failed to merge groups: ')}$error';
  String get createGroupTitle => isZh ? '新建分组' : (isJa ? 'グループを作成' : 'Create Group');
  String get createGroupDescription => isZh
      ? '输入要归入新分组的页码。创建后，这些页会自动从其它分组中移除。'
      : (isJa
          ? '新しいグループに入れるページ番号を入力してください。作成後、それらのページは他のグループから自動的に外されます。'
          : 'Enter the pages to move into a new group. Those pages will be removed from other groups automatically.');
  String totalPagesHelper(int pageCount) =>
      isZh ? '总页数：$pageCount 页' : (isJa ? '総ページ数: $pageCount' : 'Total pages: $pageCount');
  String get createGroupAction => isZh ? '创建分组' : (isJa ? 'グループを作成' : 'Create Group');
  String get invalidPageSelection =>
      isZh ? '请输入有效页码。' : (isJa ? '有効なページ番号を入力してください。' : 'Please enter valid page numbers.');
  String createGroupFailed(String error) =>
      '${isZh ? '新建分组失败：' : (isJa ? 'グループの作成に失敗しました: ' : 'Failed to create group: ')}$error';
  String pageOutOfRange(int pageCount) => isZh
      ? '页码超出范围，请输入 1 到 $pageCount 之间的数字。'
      : (isJa ? 'ページ番号が範囲外です。1 から $pageCount の間の数字を入力してください。' : 'Page number out of range. Enter a number between 1 and $pageCount.');
  String get pageNotFoundInAnyGroup =>
      isZh ? '没有在任何分组中找到该页。' : (isJa ? 'そのページはどのグループにも見つかりませんでした。' : 'That page was not found in any group.');
  String locatePageFailed(String error) =>
      '${isZh ? '查找页面失败：' : (isJa ? 'ページの検索に失敗しました: ' : 'Failed to locate page: ')}$error';
  String cropBoxTitle(int index) =>
      isZh ? '裁剪框 #$index' : (isJa ? 'トリミング枠 #$index' : 'Crop Box #$index');
  String pixelLeft(double value) =>
      isZh ? '左 ${_one(value)} px' : (isJa ? '左 ${_one(value)} px' : 'Left ${_one(value)} px');
  String pixelTop(double value) =>
      isZh ? '上 ${_one(value)} px' : (isJa ? '上 ${_one(value)} px' : 'Top ${_one(value)} px');
  String pixelRight(double value) =>
      isZh ? '右 ${_one(value)} px' : (isJa ? '右 ${_one(value)} px' : 'Right ${_one(value)} px');
  String pixelBottom(double value) =>
      isZh ? '下 ${_one(value)} px' : (isJa ? '下 ${_one(value)} px' : 'Bottom ${_one(value)} px');
  String pixelSize(double width, double height) => isZh
      ? '宽 ${_one(width)} px  高 ${_one(height)} px'
      : (isJa ? '幅 ${_one(width)} px  高さ ${_one(height)} px' : 'Width ${_one(width)} px  Height ${_one(height)} px');
  String get lockAspectRatio =>
      isZh ? '锁定纵横比' : (isJa ? '縦横比を固定' : 'Lock Aspect Ratio');
  String get lockAspectRatioDescription => isZh
      ? '拖动当前裁剪框时保持指定的长宽比例。'
      : (isJa ? '現在のトリミング枠をドラッグするときに指定した縦横比を維持します。' : 'Keep the selected crop box at the specified aspect ratio when dragging.');
  String get width => isZh ? '宽' : (isJa ? '幅' : 'Width');
  String get height => isZh ? '高' : (isJa ? '高さ' : 'Height');
  String get aspectRatioPositive =>
      isZh ? '宽和高都必须大于 0。' : (isJa ? '幅と高さはどちらも 0 より大きい必要があります。' : 'Width and height must both be greater than 0.');
  String aspectRatioFailed(String error) =>
      '${isZh ? '设置纵横比失败：' : (isJa ? '縦横比の設定に失敗しました: ' : 'Failed to set aspect ratio: ')}$error';
  String invalidPageFormat(String part) =>
      '${isZh ? '页码格式不正确：' : (isJa ? 'ページ形式が正しくありません: ' : 'Invalid page format: ')}$part';
  String get groupingLevelBasic => isZh ? '基础' : (isJa ? '基本' : 'Basic');
  String get groupingLevelBalanced => isZh ? '智能' : (isJa ? 'スマート' : 'Smart');
  String get groupingLevelStrict => isZh ? '严格' : (isJa ? '厳格' : 'Strict');
  String get groupingLevelBasicDescription => isZh
      ? '仅按页面尺寸和奇偶页分组，速度最快。'
      : (isJa ? 'ページサイズと奇数・偶数だけでグループ化します。最も高速です。' : 'Groups only by page size and parity. Fastest option.');
  String get groupingLevelBalancedDescription => isZh
      ? '按尺寸粗分后，再结合页面版式指纹细分，适合大多数文档。'
      : (isJa ? 'まずページサイズで大まかに分け、その後レイアウト指紋で細分化します。ほとんどの文書に適しています。' : 'Starts with page size and then refines using layout fingerprints. Good for most documents.');
  String get groupingLevelStrictDescription => isZh
      ? '更敏感地拆分不同版式页面，裁边更稳，但分组会更多。'
      : (isJa ? 'レイアウト差異をより敏感に分離します。トリミングは安定しますが、グループ数は増えます。' : 'More aggressively separates layout variations. More stable crops, but more groups.');
  String invalidPercentFormat(String text) =>
      '${isZh ? '过滤百分比格式不正确：' : (isJa ? 'フィルター率の形式が正しくありません: ' : 'Invalid filter percentage: ')}$text';
  String edgeFilterSummary({
    required String left,
    required String top,
    required String right,
    required String bottom,
  }) {
    return isZh
        ? '左$left 上$top 右$right 下$bottom'
        : (isJa ? '左$left 上$top 右$right 下$bottom' : 'L$left T$top R$right B$bottom');
  }

  String croppedFileName(String fileName) => isZh
      ? '${fileName.substring(0, fileName.length - 4)}_裁边后.pdf'
      : (isJa
          ? '${fileName.substring(0, fileName.length - 4)}_トリミング後.pdf'
          : '${fileName.substring(0, fileName.length - 4)}_cropped.pdf');
  String croppedFileNameFallback(String fileName) =>
      isZh ? '${fileName}_裁边后.pdf' : (isJa ? '${fileName}_トリミング後.pdf' : '${fileName}_cropped.pdf');
  String get revealFileUnsupported =>
      isZh ? '当前平台暂不支持定位导出文件。' : (isJa ? 'このプラットフォームでは書き出したファイルの表示をサポートしていません。' : 'Revealing the exported file is not supported on this platform.');
  String revealFileFailed(String error) =>
      '${isZh ? '定位文件失败：' : (isJa ? 'ファイルの表示に失敗しました: ' : 'Failed to reveal file: ')}$error';
  String get openPdfUnsupported =>
      isZh ? '当前平台暂不支持自动打开 PDF。' : (isJa ? 'このプラットフォームでは書き出した PDF の自動オープンをサポートしていません。' : 'Opening exported PDFs is not supported on this platform.');
  String openPdfFailed(String error) =>
      '${isZh ? '打开 PDF 失败：' : (isJa ? 'PDF を開けませんでした: ' : 'Failed to open PDF: ')}$error';
  String get outlierPage => isZh ? '离群页' : (isJa ? '外れ値ページ' : 'Outlier');
  String pageCountLabel(int count) =>
      isZh ? '共 $count 页' : (isJa ? '$count ページ' : '$count pages');
  String get minimize => isZh ? '最小化' : (isJa ? '最小化' : 'Minimize');
  String get maximize => isZh ? '最大化' : (isJa ? '最大化' : 'Maximize');
  String get restore => isZh ? '还原' : (isJa ? '元に戻す' : 'Restore');
  String get darkMode => isZh ? '深色' : (isJa ? 'ダーク' : 'Dark');
  String get lightMode => isZh ? '浅色' : (isJa ? 'ライト' : 'Light');
  String get systemMode => isZh ? '跟随系统' : (isJa ? 'システムに従う' : 'Follow System');
  String get language => isZh ? '语言' : (isJa ? '言語' : 'Language');
  String get simplifiedChinese => isZh ? '简体中文' : (isJa ? '簡体字中国語' : 'Simplified Chinese');
  String get english => isZh ? '英语' : (isJa ? '英語' : 'English');
  String get japanese => isZh ? '日语' : (isJa ? '日本語' : 'Japanese');
  String get languageSettingsDescription => isZh
      ? '默认跟随系统，也可以在应用内固定为中文或英文。'
      : (isJa
          ? '既定ではシステムに従いますが、アプリ内で中国語・英語・日本語に固定することもできます。'
          : 'Follows the system by default, or you can force Chinese or English in the app.');
  String get appearance => isZh ? '外观' : (isJa ? '外観' : 'Appearance');
  String get themeColors => isZh ? '主题色' : (isJa ? 'テーマカラー' : 'Theme Colors');
  String get oledOptimization => isZh ? 'OLED 优化' : (isJa ? 'OLED 最適化' : 'OLED Optimization');
  String get enableOledOptimization =>
      isZh ? 'OLED 优化' : (isJa ? 'OLED 最適化' : 'OLED Optimization');
  String get oledOnlyInDark =>
      isZh ? '仅在深色主题下生效' : (isJa ? 'ダークテーマ時のみ有効です' : 'Only takes effect in dark mode');
  String get oledConfigurableOnlyInDark => isZh
      ? '当前仅在深色主题下可配置'
      : (isJa ? '現在はダークテーマ時のみ設定できます' : 'Only configurable in dark mode');
  String get enableEInkOptimization =>
      isZh ? 'E-ink 优化' : (isJa ? 'E-Ink 最適化' : 'E-Ink Optimization');
  String get eInkOnlyInLight => isZh
      ? '仅在浅色主题下生效，会关闭动画并切换为白底黑色主题。'
      : (isJa
          ? 'ライトテーマ時のみ有効です。アニメーションを無効にし、白背景と黒のアクセントに切り替えます。'
          : 'Only takes effect in light mode. Disables animations and switches to a white background with pure black accents.');
  String get eInkConfigurableOnlyInLight => isZh
      ? '当前仅在浅色主题下可配置'
      : (isJa ? '現在はライトテーマ時のみ設定できます' : 'Only configurable in light mode');
  String get enableWindowsMica =>
      isZh ? 'Windows Mica 背景' : (isJa ? 'Windows Mica 背景' : 'Windows Mica Background');
  String get windowsMicaDescription => isZh
      ? '仅在 Windows 上生效。开启后使用系统 Mica 材质作为窗口背景。'
      : (isJa
          ? 'Windows のみ有効です。有効にするとシステムの Mica 素材をウィンドウ背景として使用します。'
          : 'Windows only. Uses the system Mica material as the window background when enabled.');
  String get windowsMicaUnavailableWhenEInk => isZh
      ? '启用 E-ink 优化时不可配置'
      : (isJa ? 'E-Ink 最適化が有効な間は設定できません' : 'Unavailable while E-Ink optimization is enabled');
  String get multiWindowMode => isZh ? '多窗口模式' : (isJa ? 'マルチウィンドウモード' : 'Multi-Window Mode');
  String get enableMultiWindowMode =>
      isZh ? '启用多窗口模式' : (isJa ? 'マルチウィンドウモードを有効化' : 'Enable Multi-Window Mode');
  String get multiWindowModeDescription => isZh
      ? '开启后，打开 PDF 会始终在独立窗口中进行编辑，编辑窗口不显示左上角返回按钮。'
      : (isJa
          ? '有効にすると、PDF は常に独立した編集ウィンドウで開かれ、そのウィンドウでは左上の戻るボタンが非表示になります。'
          : 'When enabled, opening a PDF always uses a separate editor window, and that window hides the top-left back button.');
  String get jade => isZh ? '玉石绿' : (isJa ? 'ジェイド' : 'Jade');
  String get amber => isZh ? '琥珀金' : (isJa ? 'アンバー' : 'Amber');
  String get ocean => isZh ? '海湾蓝' : (isJa ? 'オーシャン' : 'Ocean');
  String get coral => isZh ? '珊瑚橙' : (isJa ? 'コーラル' : 'Coral');
  String get ruby => isZh ? '石榴红' : (isJa ? 'ルビー' : 'Ruby');
  String get graphite => isZh ? '石墨灰' : (isJa ? 'グラファイト' : 'Graphite');
  String get documents => isZh ? '文档' : (isJa ? '書類' : 'Documents');
  String get defaultGroupingMode =>
      isZh ? '默认分组模式' : (isJa ? '既定のグループ化モード' : 'Default Grouping Mode');
  String get defaultGroupingModeDescription => isZh
      ? '打开 PDF 时默认使用这个智能分组等级。'
      : (isJa ? 'PDF を開くときに既定で使うスマートグループ化レベルです。' : 'This smart grouping level is used by default when opening PDFs.');
  String get defaultSeparateOddEvenForNewPdf => isZh
      ? '默认区分奇偶页'
      : (isJa ? '既定で奇数・偶数を分ける' : 'Separate Odd/Even by Default');
  String get defaultSeparateOddEvenForNewPdfDescription => isZh
      ? '新打开 PDF 或批量裁边时，默认按奇偶页拆分分组。'
      : (isJa ? '新しく開く PDF や一括トリミングでは、既定で奇数ページと偶数ページを別グループにします。' : 'New PDFs and batch crop tasks separate odd and even pages by default.');
  String get allowCropOutsidePage => isZh
      ? '允许裁切框超出页面'
      : (isJa ? 'トリミング枠をページ外へ出せるようにする' : 'Allow Crop Boxes Outside Page');
  String get allowCropOutsidePageDescription => isZh
      ? '开启后可将裁切框拖出页面范围，并允许缩小到页面周围出现留白。'
      : (isJa
          ? '有効にすると、トリミング枠をページ外までドラッグでき、ページ周囲に余白が見えるまで縮小できます。'
          : 'When enabled, crop boxes can be dragged outside the page and the view can zoom out enough to leave margins around the page.');
  String get defaultExportMode =>
      isZh ? '默认导出方式' : (isJa ? '既定の書き出し方法' : 'Default Export Mode');
  String get defaultExportModeDescription => isZh
      ? '用于安卓导出。可选择每次询问，或直接保存、直接分享。'
      : (isJa ? 'Android の書き出しに使用します。毎回確認、直接保存、直接共有から選べます。' : 'Used for Android export. Choose ask every time, save directly, or share directly.');
  String get clearCache => isZh ? '清理缓存' : (isJa ? 'キャッシュを消去' : 'Clear Cache');
  String get clearCacheDescription => isZh
      ? '清除应用临时目录中的导出缓存和残留文件。'
      : (isJa ? 'アプリの一時ディレクトリにある書き出しキャッシュと残留ファイルを削除します。' : 'Remove export cache and leftover files from the app temporary directory.');
  String get about => isZh ? '关于' : (isJa ? '情報' : 'About');
  String get versionLabel => isZh ? 'ProCropper PDF 版本' : (isJa ? 'ProCropper PDF バージョン' : 'ProCropper PDF Version');
  String get loading => isZh ? '读取中...' : (isJa ? '読み込み中...' : 'Loading...');
  String get thirdPartyLicenses =>
      isZh ? 'Third Party Licences' : (isJa ? 'サードパーティライセンス' : 'Third Party Licences');
  String get thirdPartyLicensesDescription =>
      isZh ? '查看第三方依赖许可信息' : (isJa ? 'サードパーティ依存関係のライセンス情報を表示' : 'View third-party dependency licenses');
  String cacheCleared(int count) => count > 0
      ? (isZh
          ? '已清理 $count 项缓存。'
          : (isJa ? '$count 件のキャッシュを消去しました。' : 'Cleared $count cached item(s).'))
      : (isZh
          ? '没有发现可清理的缓存。'
          : (isJa ? '消去できるキャッシュはありません。' : 'No cache found to clear.'));
  String clearCacheFailed(String error) =>
      '${isZh ? '清理缓存失败：' : (isJa ? 'キャッシュの消去に失敗しました: ' : 'Failed to clear cache: ')}$error';
  String get groupingModeBalanced => isZh ? '平衡' : (isJa ? 'バランス' : 'Balanced');
  String get groupingModeBasicDescription => isZh
      ? '优先按基础尺寸分组，速度更快，细分更少。'
      : (isJa ? '基本的なサイズグループ化を優先し、高速で分割数も少なめです。' : 'Prioritizes basic size grouping for higher speed and fewer splits.');
  String get groupingModeBalancedDescription => isZh
      ? '在准确度和分组数量之间保持平衡，适合作为默认模式。'
      : (isJa ? '精度とグループ数のバランスが良く、既定モードに適しています。' : 'Balances accuracy and group count. Recommended as the default.');
  String get groupingModeStrictDescription => isZh
      ? '更积极地区分版式差异，适合页面结构变化较多的文档。'
      : (isJa ? 'レイアウト差をより積極的に区別します。ページ構造の変化が多い文書に適しています。' : 'More aggressively distinguishes layout differences. Best for documents with varied page structures.');
  String get askEveryTime => isZh ? '每次询问' : (isJa ? '毎回確認' : 'Ask Every Time');
  String get saveDirectly => isZh ? '直接保存' : (isJa ? '直接保存' : 'Save Directly');
  String get shareDirectly => isZh ? '直接分享' : (isJa ? '直接共有' : 'Share Directly');
  String get askEveryTimeDescription => isZh
      ? '每次导出时都先选择保存还是分享。'
      : (isJa ? '書き出すたびに保存するか共有するかを確認します。' : 'Ask whether to save or share every time you export.');
  String get saveDirectlyDescription => isZh
      ? '直接进入保存流程，使用系统文档选择器。'
      : (isJa ? 'システムのドキュメント選択を使って直接保存します。' : 'Go straight to the save flow using the system document picker.');
  String get shareDirectlyDescription => isZh
      ? '直接导出到临时文件，并打开系统分享窗口。'
      : (isJa ? '一時ファイルに直接書き出して、システム共有シートを開きます。' : 'Export directly to a temporary file and open the system share sheet.');
  String get loadingPdf => isZh ? '正在加载 PDF...' : (isJa ? 'PDF を読み込み中...' : 'Loading PDF...');
  String get recalculatingCurrentAutoCrop =>
      isZh ? '正在重新计算当前分组的自动裁边...' : (isJa ? '現在のグループの自動トリミングを再計算しています...' : 'Recalculating auto crop for the current group...');
  String get recalculatingAllAutoCrop =>
      isZh ? '正在重新计算全部分组的自动裁边...' : (isJa ? 'すべてのグループの自動トリミングを再計算しています...' : 'Recalculating auto crop for all groups...');
  String get regrouping => isZh ? '正在重新分组...' : (isJa ? '再グループ化しています...' : 'Regrouping...');
  String get cannotMergeDifferentSizes =>
      isZh ? '不能合并不同页面尺寸的分组。' : (isJa ? 'ページサイズの異なるグループは結合できません。' : 'Cannot merge groups with different page sizes.');
  String get mergingGroups => isZh ? '正在合并分组...' : (isJa ? 'グループを結合しています...' : 'Merging groups...');
  String get creatingGroup => isZh ? '正在新建分组...' : (isJa ? 'グループを作成しています...' : 'Creating group...');
  String get preparingExport => isZh ? '正在准备导出...' : (isJa ? '書き出しを準備しています...' : 'Preparing export...');
  String get mixed => isZh ? '混合' : (isJa ? '混合' : 'Mixed');
  String get even => isZh ? '偶数' : (isJa ? '偶数' : 'Even');
  String get odd => isZh ? '奇数' : (isJa ? '奇数' : 'Odd');
  String clusterTitle(
    String parityLabel,
    String layoutLabel,
    int pageCount,
    String samplePages,
    String suffix,
  ) {
    return isZh
        ? '$parityLabel · $layoutLabel（$pageCount页）[$samplePages$suffix]'
        : (isJa
            ? '$parityLabel · $layoutLabel（$pageCountページ）[$samplePages$suffix]'
            : '$parityLabel · $layoutLabel ($pageCount pages) [$samplePages$suffix]');
  }

  String get mixedLayout => isZh ? '混合版式' : (isJa ? '混合レイアウト' : 'Mixed Layout');
  String get anomalyPage => isZh ? '异常页' : (isJa ? '異常ページ' : 'Anomalous Page');
  String get outlierSuffix => isZh ? '离群' : (isJa ? '外れ値' : 'Outlier');
  String get manualSinglePage => isZh ? '手动单页' : (isJa ? '手動単一ページ' : 'Manual Single Page');
  String get manualMixedGroup => isZh ? '手动混合组' : (isJa ? '手動混合グループ' : 'Manual Mixed Group');
  String get manualGroup => isZh ? '手动分组' : (isJa ? '手動グループ' : 'Manual Group');
  String groupingReason({
    required String parityLabel,
    required String layoutLabel,
    required int roundedWidth,
    required int roundedHeight,
    required int pageCount,
    required bool smartGroupingApplied,
    required bool containsOutlierPage,
  }) {
    final parts = <String>[
      isZh ? '奇偶标签：$parityLabel' : (isJa ? '奇偶ラベル: $parityLabel' : 'Parity: $parityLabel'),
      isZh ? '尺寸桶：$roundedWidth x $roundedHeight' : (isJa ? 'サイズバケット: $roundedWidth x $roundedHeight' : 'Size bucket: $roundedWidth x $roundedHeight'),
      isZh ? '版式标签：$layoutLabel' : (isJa ? 'レイアウトラベル: $layoutLabel' : 'Layout label: $layoutLabel'),
      isZh ? '页数：$pageCount' : (isJa ? 'ページ数: $pageCount' : 'Pages: $pageCount'),
      smartGroupingApplied
          ? (isZh ? '细分方式：版式指纹智能细分' : (isJa ? '細分方法: レイアウト指紋によるスマート分割' : 'Refinement: smart layout fingerprint split'))
          : (isZh ? '细分方式：仅基础尺寸分组' : (isJa ? '細分方法: 基本サイズのみでグループ化' : 'Refinement: basic size grouping only')),
    ];
    if (containsOutlierPage) {
      parts.add(
        isZh
            ? '特殊说明：该组由离群页自动拆出'
            : (isJa ? '特記事項: このグループは外れ値ページとして自動的に分離されました' : 'Note: this group was automatically split out as an outlier page'),
      );
    }
    return parts.join('\n');
  }

  String manualGroupingReason({
    required String parityLabel,
    required int roundedWidth,
    required int roundedHeight,
    required int pageCount,
  }) {
    return [
      isZh ? '奇偶标签：$parityLabel' : (isJa ? '奇偶ラベル: $parityLabel' : 'Parity: $parityLabel'),
      isZh ? '尺寸桶：$roundedWidth x $roundedHeight' : (isJa ? 'サイズバケット: $roundedWidth x $roundedHeight' : 'Size bucket: $roundedWidth x $roundedHeight'),
      isZh ? '页数：$pageCount' : (isJa ? 'ページ数: $pageCount' : 'Pages: $pageCount'),
      isZh ? '细分方式：手动创建分组' : (isJa ? '細分方法: 手動作成グループ' : 'Refinement: manually created group'),
    ].join('\n');
  }

  String get writingSelectedLocation =>
      isZh ? '正在写入所选位置...' : (isJa ? '選択した場所に書き込んでいます...' : 'Writing to the selected location...');
  String get readingSourceFile =>
      isZh ? '正在读取源文件...' : (isJa ? '元ファイルを読み込んでいます...' : 'Reading source file...');
  String processingPage(int current, int total) => isZh
      ? '正在处理第 $current / $total 页...'
      : (isJa ? 'ページ $current / $total を処理しています...' : 'Processing page $current / $total...');
  String get generatingExportFile =>
      isZh ? '正在生成导出文件...' : (isJa ? '書き出しファイルを生成しています...' : 'Generating export file...');
  String get writingToDisk => isZh ? '正在写入磁盘...' : (isJa ? 'ディスクに書き込んでいます...' : 'Writing to disk...');
  String get blankPage => isZh ? '空白页' : (isJa ? '空白ページ' : 'Blank Page');
  String get heavyContentPage => isZh ? '重内容页' : (isJa ? '高密度コンテンツページ' : 'Dense Content Page');
  String get titlePage => isZh ? '标题页' : (isJa ? '表紙ページ' : 'Title Page');
  String get headerProminent => isZh ? '页眉明显' : (isJa ? 'ヘッダーが目立つ' : 'Prominent Header');
  String get footerProminent => isZh ? '页脚明显' : (isJa ? 'フッターが目立つ' : 'Prominent Footer');
  String get bodyPage => isZh ? '正文页' : (isJa ? '本文ページ' : 'Body Page');

  static String _one(double value) => value.toStringAsFixed(1);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' ||
      locale.languageCode == 'en' ||
      locale.languageCode == 'ja';

  @override
  Future<AppLocalizations> load(Locale locale) {
    final resolved = locale.languageCode == 'zh'
        ? const Locale('zh', 'CN')
        : locale.languageCode == 'ja'
        ? const Locale('ja')
        : const Locale('en');
    final value = AppLocalizations(resolved);
    AppLocalizations.current = value;
    return SynchronousFuture<AppLocalizations>(value);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
