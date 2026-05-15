import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/app_logo_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/splash_controller.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppThemeData.primary4,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLogoWidget(height: 80),
                spaceH(height: 24),
                TextCustom(title: Constant.appName.value, fontSize: 24, color: AppThemeData.primaryWhite, fontFamily: FontFamily.bold),
                spaceH(height: 4),
                TextCustom(title: "Buy Smart. Sell Fast.", fontSize: 14, color: AppThemeData.primaryWhite, fontFamily: FontFamily.regular),
              ],
            ),
          ),
        );
      },
    );
  }
}
