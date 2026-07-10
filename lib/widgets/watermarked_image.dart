import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Wraps an image [child] and overlays the app logo as a watermark at the
/// bottom-right corner, OLX-style.
///
/// The watermark size scales with the rendered image size and skips for very
/// small renders (avatars, list-thumbnails under ~60 px) so layouts that
/// already use tiny CachedNetworkImage instances aren't visually disrupted.
///
/// Painting is purely additive — the child's layout/size is unchanged.
class WatermarkedImage extends StatelessWidget {
  final Widget child;
  final double scaleFactor;
  final double minSize;
  final double maxSize;
  final double margin;
  final double opacity;
  final double skipBelow;

  const WatermarkedImage({
    super.key,
    required this.child,
    this.scaleFactor = 0.09,
    this.minSize = 20,
    this.maxSize = 52,
    this.margin = 10,
    this.opacity = 0.75,
    this.skipBelow = 60,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        final ref = (w > 0 && h > 0) ? (w < h ? w : h) : (w > 0 ? w : h);

        if (ref < skipBelow) return child;
        final size = (ref * scaleFactor).clamp(minSize, maxSize);
        final labelSize = (size * 0.42).clamp(11.0, 17.0);

        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            child,
            Positioned(
              right: margin,
              bottom: margin,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Obx(() {
                    final remoteUrl = Constant.watermarkUrl.value;
                    final name = Constant.appName.value.isNotEmpty ? Constant.appName.value : 'eSellify';
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (remoteUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: remoteUrl,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) => SvgPicture.asset('assets/images/logo.svg', width: size, height: size),
                          )
                        else
                          SvgPicture.asset('assets/images/logo.svg', width: size, height: size),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: 0.2,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
