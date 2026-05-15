import 'package:eSellify/utils/app_colors.dart';
import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: AppThemeData.primary4,
      size: size,
    );
  }
}
