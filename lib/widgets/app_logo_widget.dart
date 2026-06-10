import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays the Tireda app logo from local assets.
/// Always uses assets/images/logo.svg — no network dependency.
class AppLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppLogoWidget({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      height: height,
      width: width,
      fit: fit,
    );
  }
}