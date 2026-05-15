import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;

  const NetworkImageWidget({super.key, this.height, this.width, this.fit, required this.imageUrl, this.borderRadius, this.errorWidget, this.color});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    if (imageUrl.isEmpty || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
        child: Container(
          height: height ?? ScreenSize.height(8, context),
          width: width ?? ScreenSize.width(15, context),
          color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
          child: errorWidget ?? Image.asset(Constant.userPlaceHolder, height: height ?? ScreenSize.height(8, context), width: width ?? ScreenSize.width(15, context), fit: fit ?? BoxFit.fill),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 0),
      child: CachedNetworkImage(
        fit: fit ?? BoxFit.fill,
        height: height ?? ScreenSize.height(8, context),
        width: width ?? ScreenSize.width(15, context),
        imageUrl: imageUrl,
        color: color,
        progressIndicatorBuilder: (context, url, downloadProgress) => Shimmer.fromColors(
          baseColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
          highlightColor: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
          child: Container(height: height ?? ScreenSize.height(8, context), width: width ?? ScreenSize.width(15, context), color: AppThemeData.grey3),
        ),
        errorWidget: (context, url, error) => Container(
          height: height ?? ScreenSize.height(8, context),
          width: width ?? ScreenSize.width(15, context),
          color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
          child: errorWidget ?? Image.asset(Constant.userPlaceHolder, height: height ?? ScreenSize.height(8, context), width: width ?? ScreenSize.width(15, context)),
        ),
      ),
    );
  }
}
