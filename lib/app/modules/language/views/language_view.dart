import 'dart:convert';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/app/modules/onboarding_screen/views/onboarding_screen_view.dart';
import 'package:eSellify/app/services/localization_service.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/language_controller.dart';

class LanguageView extends GetView<LanguageController> {
  final bool isFirstTime;

  const LanguageView({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: LanguageController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: isFirstTime ? UiInterface.customAppBar(context, themeChange, "Language") : UiInterface.customAppBar(context, themeChange, "Language", isBack: true),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        title: "Choose your language".tr,
                        fontSize: 16,
                        fontFamily: FontFamily.regular,
                        color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                      ),
                      spaceH(height: 2),
                      TextCustom(
                        title: "language_desc".trParams({"appname": Constant.appName.value}),
                        fontSize: 14,
                        fontFamily: FontFamily.regular,
                        color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
                      ),
                      spaceH(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: controller.isLoading.value
                              ? Constant.loader(context: context)
                              : Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: controller.languageList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    separatorBuilder: (context, index) =>
                                        Divider(height: 12, thickness: 1, color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3),
                                    itemBuilder: (context, index) {
                                      return Obx(
                                        () => Center(
                                          child: RadioGroup<LanguageModel>(
                                            groupValue: controller.selectedLanguage.value,
                                            onChanged: (value) {
                                              controller.selectedLanguage.value = value!;
                                            },
                                            child: RadioListTile(
                                              dense: true,
                                              value: controller.languageList[index],
                                              contentPadding: EdgeInsets.zero,
                                              controlAffinity: ListTileControlAffinity.trailing,
                                              activeColor: AppThemeData.primary4,
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextCustom(
                                                    title: controller.languageList[index].name.toString(),
                                                    fontSize: 16,
                                                    color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                                                    fontFamily: FontFamily.medium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
                      child: RoundShapeButton(
                        title: "Save".tr,
                        buttonColor: AppThemeData.primary4,
                        buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        onTap: () async {
                          LocalizationService().changeLocale(controller.selectedLanguage.value.code.toString());
                          await Preferences.setString(Preferences.languageCodeKey, jsonEncode(controller.selectedLanguage.value.toJson()));

                          ShowToastDialog.showSuccess("Language Changed Successfully.".tr);

                          if (isFirstTime) {
                            Get.offAll(const OnboardingScreenView());
                          } else {
                            Get.back();
                          }
                        },
                        size: Size(0, ScreenSize.height(7, context)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
