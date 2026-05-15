import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/contact_us_controller.dart';

class ContactUsView extends GetView<ContactUsController> {
  const ContactUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: ContactUsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Contact Us"),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: controller.isLoading.value
                ? Constant.loader(context: context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        title: "Please fill out the form below and we'll get back to you as soon as possible.".tr,
                        fontSize: 14,
                        fontFamily: FontFamily.regular,
                        color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
                        maxLine: 3,
                      ),
                      spaceH(height: 16),
                      _buildOptionCard(
                        method: "Phone / WhatsApp:".tr,
                        icon: "assets/icons/ic_mobile.svg",
                        onTap: () {
                          Constant.redirectCall(phoneNumber: controller.contactUsModel.value.phoneNumber.toString(), countryCode: '');
                        },
                        theme: themeChange,
                      ),
                      spaceH(height: 16),
                      _buildOptionCard(
                        method: "Email:".tr,
                        icon: "assets/icons/ic_mail.svg",
                        onTap: () {
                          Constant.redirectMail(email: controller.contactUsModel.value.email.toString());
                        },
                        theme: themeChange,
                      ),
                      spaceH(height: 16),
                      _buildOptionCard(method: "Website:".tr, icon: "assets/icons/ic_global.svg", onTap: () {}, theme: themeChange),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({required String method, required String icon, required VoidCallback onTap, required DarkThemeProvider theme}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: paddingEdgeInsets(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: theme.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: theme.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
              child: SvgPicture.asset(icon, color: theme.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6),
            ),
            spaceW(width: 12),
            Expanded(
              child: TextCustom(title: method, fontSize: 14, fontFamily: FontFamily.regular, color: theme.isDarkTheme() ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
            ),
            SvgPicture.asset("assets/icons/ic_arrow_right.svg", color: theme.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6),
          ],
        ),
      ),
    );
  }
}
