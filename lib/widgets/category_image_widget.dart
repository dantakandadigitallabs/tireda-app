import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Thumbnail for a category / sub-category tile.
///
/// [NetworkImageWidget] is built for photos: it defaults to screen-percentage
/// sizes when none are given, paints a flat light-grey block that stays light
/// in dark mode, and falls back to the *user avatar* asset — which is why an
/// unreachable category icon used to render as a person silhouette.
///
/// This widget instead fills whatever box the parent tile gives it, runs a
/// rounded theme-aware shimmer for the whole download, and falls back to a
/// neutral category glyph.
class CategoryImageWidget extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  /// Corner radius of the shimmer / image. Should match the tile's inner
  /// container so the placeholder doesn't look like a square patch.
  final double radius;

  /// Size of the fallback glyph. Tiles are 30–36px of content, so the default
  /// keeps the icon comfortably inside.
  final double fallbackIconSize;

  const CategoryImageWidget({super.key, required this.imageUrl, required this.isDark, this.radius = 8, this.fallbackIconSize = 18});

  bool get _isRemote => imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  Color get _base => isDark ? AppThemeData.grey8 : AppThemeData.grey3;

  Color get _highlight => isDark ? AppThemeData.grey7 : AppThemeData.grey1;

  @override
  Widget build(BuildContext context) {
    if (!_isRemote) return _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => _shimmer(),
        errorWidget: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: _base,
    highlightColor: _highlight,
    child: Container(decoration: BoxDecoration(color: _base, borderRadius: BorderRadius.circular(radius))),
  );

  Widget _fallback() => Center(child: Icon(Icons.category_outlined, size: fallbackIconSize, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5));
}
