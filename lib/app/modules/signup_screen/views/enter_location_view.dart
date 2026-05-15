// ignore_for_file: must_be_immutable

import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/osm_place_picker/osm_location_picker_screen.dart';
import 'package:eSellify/app/constant/place_picker/location_picker_screen.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/modules/signup_screen/controllers/enter_location_controller.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class EnterLocationView extends GetView<EnterLocationController> {
  final bool? isRedirectDashboard;

  EnterLocationView({super.key, required this.isRedirectDashboard});

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
      init: EnterLocationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          body: Padding(
            padding: paddingEdgeInsets(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spaceH(height: 100),
                Image.asset("assets/images/map.png", height: 200, width: 200),
                spaceH(height: 100),
                buildTopWidget(context),
                spaceH(height: 70),
                Row(
                  children: [
                    Expanded(
                      child: RoundShapeButton(
                        title: "Current Location".tr,
                        buttonColor: AppThemeData.primary4,
                        buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        onTap: () {
                          controller.getUserLocation();
                        },
                        size: Size(358, ScreenSize.height(7, context)),
                      ),
                    ),
                  ],
                ),
                spaceH(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RoundShapeButton(
                        title: "Select Another Location".tr,
                        buttonColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey2,
                        buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                        onTap: () {
                          Constant.checkPermission(() async {
                            dynamic value;
                            if (Constant.selectedMap == "Google Map") {
                              value = await Get.to(LocationPickerScreen());
                            } else {
                              value = await Get.to(OSMLocationPickerScreen());
                            }

                            if (value == null) return;

                            final latLng = value.latLng;
                            final placeMark = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
                            if (placeMark.isEmpty) return;

                            final result = placeMark.first;

                            final address = "${result.name}, ${result.locality}, ${result.administrativeArea}, ${result.postalCode}, ${result.country}";

                            // Update controller data
                            controller.addressController.value.text = address;
                            controller.addAddressModel.value.locality = result.locality;
                            controller.addAddressModel.value.landmark = result.subLocality;
                            controller.addAddressModel.value.location = LocationLatLng(latitude: latLng!.latitude, longitude: latLng!.longitude);
                            controller.addAddressModel.value.address = controller.addressController.value.text;
                            controller.addAddressModel.value.id = Constant.getUuid();
                            controller.addAddressModel.value.isDefault = true;
                            controller.addAddressModel.value.addressAs = "Home";
                            controller.addAddressModel.value.name = FireStoreUtils.getCurrentUid() != null ? Constant.userModel!.fullNameString() : "";

                            Constant.currentLocation.value = controller.addAddressModel.value;

                            // Save if logged in
                            if (FireStoreUtils.getCurrentUid() != null) {
                              await controller.saveAddress();
                            }

                            // Navigation
                            if (isRedirectDashboard == true) {
                              Get.offAllNamed(Routes.DASHBOARD_SCREEN);
                            } else {
                              Get.back(result: true);
                            }
                          });
                        },
                        size: Size(358, ScreenSize.height(7, context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox buildTopWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Enable Location Access".tr,
            style: TextStyle(fontFamily: FontFamily.bold, fontSize: 24, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          Text(
            "We use your location to suggest nearby listings and improve your buying & selling experience.".tr,
            style: TextStyle(fontSize: 16, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
