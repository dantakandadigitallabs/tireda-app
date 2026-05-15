import 'package:eSellify/utils/font_family.dart';
import 'package:flutter/material.dart';

class RoundShapeButton extends StatelessWidget {
  final String title;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color? borderColor;
  final VoidCallback onTap;
  final Size size;
  final double? textSize;
  final double? borderRadius;
  final Widget? titleWidget;

  const RoundShapeButton({
    super.key,
    required this.title,
    required this.buttonColor,
    required this.buttonTextColor,
    this.borderColor,
    required this.onTap,
    this.textSize,
    this.borderRadius = 12,
    this.titleWidget,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        fixedSize: WidgetStateProperty.all<Size>(size),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        backgroundColor: WidgetStateProperty.all<Color>(buttonColor),
        elevation: WidgetStateProperty.all<double>(0),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
            side: BorderSide(color: borderColor ?? Colors.transparent, width: 1.5),
          ),
        ),
      ),
      onPressed: onTap,
      child:
          titleWidget ??
          Text(
            title,
            style: TextStyle(fontFamily: FontFamily.regular, fontSize: textSize ?? 16, fontWeight: FontWeight.w600, color: buttonTextColor),
          ),
    );
  }
}
