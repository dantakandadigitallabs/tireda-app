import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/modules/login_screen/views/login_screen_view.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/onboarding_screen_controller.dart';

class OnboardingScreenView extends StatelessWidget {
  const OnboardingScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OnboardingScreenController>(
      init: OnboardingScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              controller.currentPage.value < controller.pages.length - 1
                  ? GestureDetector(
                      onTap: () => controller.skipToEnd,
                      child: Row(
                        children: [
                          TextCustom(title: "Skip", fontSize: 16, color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6, fontFamily: FontFamily.medium),
                          spaceW(width: 4),
                          SvgPicture.asset("assets/icons/ic_arrow_right.svg", color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6),
                        ],
                      ),
                    ).paddingOnly(right: 16)
                  : const SizedBox(),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                spaceH(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(item: controller.pages[index]);
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(controller.pages.length, (index) {
                    bool isActive = controller.currentPage.value == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppThemeData.secondary4.withOpacity(0.15) : Colors.transparent),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppThemeData.secondary4 : AppThemeData.grey4),
                      ),
                    );
                  }),
                ),
                spaceH(height: 32),
                Visibility(
                  visible: controller.currentPage.value != controller.pages.length - 1,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    child: RoundShapeButton(
                      title: "Next",
                      buttonColor: AppThemeData.primary4,
                      buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                      onTap: () {
                        controller.currentPage.value = controller.currentPage.value + 1;
                        controller.pageController.jumpToPage(controller.currentPage.value);
                      },
                      size: Size(450, 56),
                    ),
                  ),
                ),
                Visibility(
                  visible: controller.currentPage.value == controller.pages.length - 1,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    child: RoundShapeButton(
                      title: "Get Started",
                      buttonColor: AppThemeData.primary4,
                      buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                      onTap: () {
                        Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                        Get.offAll(const DashboardScreenView());
                      },
                      size: Size(450, 56),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final dynamic item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(item.image, width: 250, height: 250),
        spaceH(height: 48),
        TitleTextCustom(title: item.title, fontSize: 24, fontFamily: FontFamily.bold, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
        spaceH(height: 4),
        TextCustom(
          title: item.description,
          fontSize: 16,
          color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
          textAlign: TextAlign.center,
          fontFamily: FontFamily.regular,
          maxLine: 4,
        ),
      ],
    );
  }
}
