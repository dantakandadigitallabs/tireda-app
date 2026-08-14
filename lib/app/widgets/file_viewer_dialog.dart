import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app viewer for a custom-field attachment (image / PDF / office doc),
/// shown in a dialog. The raw file URL is NEVER surfaced to the user — only
/// the rendered content and a friendly [title].
///
///  * images  → rendered directly (private)
///  * PDF      → rendered directly with the PDF viewer (private)
///  * office   → previewed via Google Docs Viewer inside an in-app WebView
class FileViewerDialog extends StatefulWidget {
  final String url;
  final String title;

  const FileViewerDialog({super.key, required this.url, this.title = 'Attachment'});

  /// Opens the viewer. Uses [Get.dialog] so no BuildContext is required.
  static Future<void> open(String url, {String title = 'Attachment'}) {
    return Get.dialog(FileViewerDialog(url: url, title: title));
  }

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  static const _imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

  // Set once the optimistic image attempt fails for an extension-less URL, so
  // we fall through to the Office/Google-Docs viewer instead.
  bool _imageFailed = false;

  String get _ext {
    final path = Uri.tryParse(widget.url)?.path ?? widget.url;
    final dot = path.lastIndexOf('.');
    return dot >= 0 && dot < path.length - 1 ? path.substring(dot + 1).toLowerCase() : '';
  }

  bool get _isImage => _imageExts.contains(_ext);
  bool get _isPdf => _ext == 'pdf';
  // Firebase Storage URLs store the object with no file extension, so we can't
  // tell the type from the URL. Try rendering as an image first, then fall back.
  bool get _extUnknown => _ext.isEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 720,
        height: size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: _body(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isDark) {
    // Render as an image for known image types, and as a first attempt for
    // extension-less URLs (Firebase files) — a real JPG/PNG displays fine even
    // without a `.jpg` in the URL. If that fails, fall back to the PDF / Office
    // viewers below.
    if (_isImage || (_extUnknown && !_imageFailed)) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) {
              if (_extUnknown && !_imageFailed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _imageFailed = true);
                });
                return const Center(child: CircularProgressIndicator());
              }
              return _unsupported(isDark);
            },
          ),
        ),
      );
    }
    if (_isPdf) {
      return SfPdfViewer.network(widget.url);
    }
    // Office / other → Google Docs Viewer inside an in-app WebView.
    return _OfficeWebView(url: widget.url, fallback: _unsupported(isDark));
  }

  Widget _unsupported(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 48, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            const SizedBox(height: 12),
            Text(
              'This file type can\'t be previewed.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders an Office document (doc/xls/ppt …) through Google Docs Viewer inside
/// an in-app WebView. Stateful so the controller is created exactly once.
class _OfficeWebView extends StatefulWidget {
  final String url;
  final Widget fallback;
  const _OfficeWebView({required this.url, required this.fallback});

  @override
  State<_OfficeWebView> createState() => _OfficeWebViewState();
}

class _OfficeWebViewState extends State<_OfficeWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final gview = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(gview));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
