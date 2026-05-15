import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// Displays the app logo dynamically:
/// - If admin uploaded app icon for the current theme → shows network image
/// - Otherwise → falls back to local assets/images/logo.svg
class AppLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppLogoWidget({super.key, this.height, this.width, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).isDarkTheme();
    final dynamicUrl = isDark ? Constant.appIconDark : Constant.appIconLight;

    // Use dynamic icon if available
    if (dynamicUrl != null && dynamicUrl.isNotEmpty && dynamicUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: dynamicUrl,
        height: height,
        width: width,
        fit: fit,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, _) => _fallbackLogo(isDark),
        errorWidget: (_, _, _) => _fallbackLogo(isDark),
      );
    }

    return _fallbackLogo(isDark);
  }

  Widget _fallbackLogo(bool isDark) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      height: height,
      width: width,
      fit: fit,
    );
  }
}
