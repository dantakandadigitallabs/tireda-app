import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/widgets/watermarked_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Full-screen image preview with pinch-to-zoom, pan, horizontal swipe between
/// images, page indicator, and a close button.
///
/// Use [ImagePreviewDialog.show] to open. Doesn't navigate to a new route in
/// the GetX sense — uses [showGeneralDialog] so the parent screen stays
/// mounted and the preview animates in/out as an overlay.
class ImagePreviewDialog {
  const ImagePreviewDialog._();

  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    final clamped = initialIndex.clamp(0, images.length - 1);
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Image preview'.tr,
      barrierColor: Colors.black,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _ImagePreviewBody(images: images, initialIndex: clamped),
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _ImagePreviewBody extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewBody({required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewBody> createState() => _ImagePreviewBodyState();
}

class _ImagePreviewBodyState extends State<_ImagePreviewBody> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Pager with zoomable pages
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _ZoomablePage(imageUrl: widget.images[i]),
              ),
            ),
            // Top bar: counter + close
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    tooltip: 'Close'.tr,
                  ),
                  const Spacer(),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom indicators
            if (widget.images.length > 1)
              Positioned(
                bottom: 16 + mq.padding.bottom,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    final active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  final String imageUrl;
  const _ZoomablePage({required this.imageUrl});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  TapDownDetails? _doubleTapDetails;
  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnim;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        if (_zoomAnim != null) _controller.value = _zoomAnim!.value;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    final current = _controller.value;
    final isZoomed = current.getMaxScaleOnAxis() > 1.01;

    Matrix4 target;
    if (isZoomed) {
      target = Matrix4.identity();
    } else if (position != null) {
      const scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      target = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    } else {
      target = Matrix4.identity()..scale(2.5);
    }

    _zoomAnim = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (d) => _doubleTapDetails = d,
      onDoubleTap: _handleDoubleTap,
      // Single tap on empty area dismisses
      onTap: () {
        // Only dismiss if not zoomed in
        if (_controller.value.getMaxScaleOnAxis() <= 1.01) {
          Navigator.of(context).maybePop();
        }
      },
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        clipBehavior: Clip.none,
        child: Center(
          child: WatermarkedImage(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, _) => const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _RoundIconButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
