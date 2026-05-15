// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'text_widget.dart';

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Image.asset(
                "assets/animation/location.gif",
                height: 120.0,
                width: 120.0,
              ),
            ),
            TextCustom(
              title: 'location permission'.tr,
              fontSize: 18,
              fontFamily: FontFamily.bold,
            ),
            spaceH(height: 5),
            TextCustom(
              title: 'Please allow location permission from your app settings and receive more accurate delivery.'.tr,
              fontSize: 14,
              maxLine: 3,
              fontFamily: FontFamily.regular,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
                    minimumSize: const Size(1, 50),
                  ),
                  child: TextCustom(
                    title: 'Cancel'.tr,
                    fontSize: 16,
                    fontFamily: FontFamily.medium,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary4,
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side:  BorderSide(
                          color: AppThemeData.primary4,
                        ),
                      ),
                    ),
                    child: TextCustom(
                      title: 'Settings'.tr,
                      fontSize: 16,
                      fontFamily: FontFamily.medium,
                      color: AppThemeData.primaryWhite,
                    ),
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            ]),
          ]),
        ),
      ),
    );
  }
}
