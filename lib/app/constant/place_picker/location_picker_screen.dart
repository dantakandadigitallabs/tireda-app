import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/place_picker/location_controller.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: LocationController(),
      builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: GestureDetector(
              onTap: () async {
                Prediction? p = await PlacesAutocomplete.show(context: context, apiKey: Constant.googleMapKey, mode: Mode.overlay, language: "en");
                if (p != null) {
                  final detail = await controller.places.getDetailsByPlaceId(p.placeId!);
                  final lat = detail.result.geometry!.location.lat;
                  final lng = detail.result.geometry!.location.lng;
                  final LatLng pos = LatLng(lat, lng);
                  controller.selectedLocation.value = pos;
                  controller.mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
                  controller.getAddressFromLatLng(pos);
                }
              },
              child: Container(
                width: ScreenSize.width(100, context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search),
                    spaceW(width: 8),
                    Expanded(
                      child: TextCustom(
                        title: controller.address.value.isEmpty ? "Search place..." : controller.address.value,
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        fontFamily: FontFamily.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: controller.selectedLocation.value == null
              ? Center(child: Constant.loader())
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controllers) {
                        controller.mapController = controllers;
                      },
                      initialCameraPosition: CameraPosition(target: controller.selectedLocation.value!, zoom: 15),
                      onCameraMove: controller.onMapMoved,
                      onCameraIdle: () {
                        if (controller.selectedLocation.value != null) {
                          controller.getAddressFromLatLng(controller.selectedLocation.value!);
                        }
                      },
                    ),
                    Center(child: Icon(Icons.location_pin, size: 40, color: Colors.red)),
                    Positioned(
                      bottom: 40,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(
                              () => Text(
                                controller.address.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: FontFamily.medium,
                                  color: themeChange.isDarkTheme() ? AppThemeData.primaryWhite : AppThemeData.primaryBlack,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            RoundShapeButton(
                              title: "Confirm Location".tr,
                              buttonColor: AppThemeData.primary4,
                              buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                              onTap: () {
                                controller.confirmLocation();
                              },
                              size: Size(200, 48),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
