// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:developer';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/app/constant/osm_place_picker/osm_location_picker_screen.dart';
import 'package:eSellify/app/constant/place_picker/location_picker_screen.dart';
import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/my_address_controller.dart';

class MyAddressView extends GetView<MyAddressController> {
  final bool isFromProfile;

  const MyAddressView({super.key, this.isFromProfile = false});

  /// Promote `address` to the user's default: set its `isDefault=true`, all
  /// others `false`, persist to Firestore, and update the in-memory current
  /// location. Called both from the profile "Set as Default" popup and from
  /// the card body tap so tapping a card is enough on its own.
  Future<void> _setDefaultAddress(MyAddressController controller, AddAddressModel address) async {
    if (address.isDefault == true) return;
    if (address.location == null) {
      ShowToastDialog.showError("Invalid address location".tr);
      return;
    }
    ShowToastDialog.showLoader("Please Wait..".tr);
    for (var e in controller.addresses) {
      e.isDefault = false;
    }
    address.isDefault = true;
    controller.addressModel.value = address;
    controller.addresses.refresh();

    final userAddresses = Constant.userModel?.addAddresses;
    if (userAddresses != null) {
      for (var e in userAddresses) {
        e.isDefault = e.id == address.id;
      }
      await FireStoreUtils.updateUser(Constant.userModel!);
    }
    Constant.currentLocation.value = address;
    ShowToastDialog.closeLoader();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: MyAddressController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "My Address".tr),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Constant.checkPermission(() async {
                      try {
                        dynamic value;

                        if (Constant.selectedMap == "Google Map") {
                          value = await Get.to(LocationPickerScreen());
                        } else {
                          value = await Get.to(OSMLocationPickerScreen());
                        }

                        if (value == null || value.latLng == null) {
                          ShowToastDialog.showError("Location not selected properly. Please try again.".tr);
                          return;
                        }

                        final latLng = value.latLng!;
                        final placeMark = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
                        if (placeMark.isNotEmpty) {
                          final result = placeMark.first;

                          controller.addressController.value.text = "${result.name}, ${result.locality}, ${result.administrativeArea}, ${result.postalCode}, ${result.country}";

                          controller.addressModel.value.locality = result.locality;
                          controller.addressModel.value.landmark = result.subLocality;
                          controller.addressModel.value.location = LocationLatLng(latitude: latLng.latitude, longitude: latLng.longitude);
                          controller.addressModel.value.address = controller.addressController.value.text;
                          controller.addressModel.value.id = Constant.getUuid();
                          controller.addressModel.value.isDefault = false;
                          controller.addressModel.value.name = Constant.userModel!.fullNameString();

                          final value = await Get.dialog(
                            Dialog(
                              backgroundColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                              child: AddAddressBottomSheet(
                                addressId: "",
                                addressModel: controller.addressModel.value,
                                addressController: controller.addressController.value,
                                locationController: controller.locationController.value,
                              ),
                            ),
                          );
                          if (value == true) {
                            controller.getData();
                          }
                        } else {
                          ShowToastDialog.showError("Could not determine address from coordinates.".tr);
                        }
                      } catch (e) {
                        ShowToastDialog.showError("Something went wrong while fetching address.".tr);
                      }
                    });
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset("assets/icons/ic_add.svg"),
                        spaceW(width: 8),
                        TextCustom(title: "Add new address".tr, fontSize: 16, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                      ],
                    ),
                  ),
                ),
                spaceH(height: 16),
                Expanded(
                  child: controller.isLoading.value
                      ? Constant.loader(context: context)
                      : controller.addresses.isEmpty
                      ? Center(child: TextCustom(title: "No Address Found".tr))
                      : SingleChildScrollView(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.addresses.length,
                            itemBuilder: (context, index) {
                              final address = controller.addresses[index];
                              final isSelected = controller.selectedAddress.value?.id == address.id;
                              return _buildAddressCard(
                                index: index,
                                address: address,
                                theme: themeChange,
                                isSelected: isSelected,
                                onEdit: () async {
                                  final value = await Get.dialog(
                                    Dialog(
                                      backgroundColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: AddAddressBottomSheet(
                                        addressId: address.id,
                                        addressModel: address,
                                        addressController: TextEditingController(
                                          text: address.address!.split(',').length > 1 ? address.address!.split(',').sublist(1).join(',') : "",
                                        ),
                                        locationController: TextEditingController(text: address.address?.split(',').isNotEmpty == true ? address.address!.split(',')[0] : ""),
                                      ),
                                    ),
                                  );
                                  if (value == true) {
                                    controller.getData();
                                  }
                                },
                                onDelete: () async {
                                  if (controller.addresses.length == 1) {
                                    ShowToastDialog.showError("Unable to delete this address.".tr);
                                    return;
                                  }
                                  if (address.isDefault == true) {
                                    ShowToastDialog.showError("Cannot delete the default address. Set another address as default first.".tr);
                                    return;
                                  }
                                  await controller.deleteAddress(index);
                                  ShowToastDialog.showSuccess("Address deleted successfully.".tr);
                                  controller.getData();
                                },
                                onSelect: () {
                                  // Tapping the card body selects the location for the
                                  // current session so the Home Screen re-sorts products
                                  // by distance from THIS address. It does NOT flip
                                  // isDefault or write to Firestore — that's reserved
                                  // for the explicit "Set as Default" popup action.
                                  controller.selectedAddress.value = address;
                                  // Force a real notification: an Rxn skips notifiers
                                  // when reassigned to the same instance, and the home
                                  // controller's `ever(Constant.currentLocation)` listener
                                  // depends on this to re-sort the ad list by distance.
                                  Constant.currentLocation.value = null;
                                  Constant.currentLocation.value = address;
                                  Constant.currentLocation.refresh();
                                  // Persist the selection so re-opening the app keeps
                                  // sorting by THIS location, not by whichever address
                                  // is flagged isDefault.
                                  try {
                                    Preferences.setString(Preferences.selectedAddressKey, jsonEncode(address.toJson()));
                                  } catch (_) {}
                                  ShowToastDialog.showSuccess('Location updated'.tr);
                                  // In picker mode we also return to the caller so the
                                  // flow that opened the picker (Home, Add Ad, etc.)
                                  // receives the choice.
                                  if (!isFromProfile) {
                                    Get.back(result: true);
                                  }
                                },
                                onSetDefault: () => _setDefaultAddress(controller, address),
                              );
                            },
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

  Widget _buildAddressCard({
    required int index,
    required AddAddressModel address,
    required DarkThemeProvider theme,
    required bool isSelected,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSelect,
    required VoidCallback onSetDefault,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.fromLTRB(12, 12, 0, 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.isDarkTheme() ? AppThemeData.primary4.withValues(alpha: 0.14) : AppThemeData.primary1)
              : (theme.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppThemeData.primary4 : (theme.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppThemeData.primary4.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  address.addressAs == "Home"
                      ? "assets/icons/ic_home_fill.svg"
                      : address.addressAs == "Work"
                      ? "assets/icons/ic_work_fill.svg"
                      : address.addressAs == "Friends and Family"
                      ? "assets/icons/ic_user_fill.svg"
                      : "assets/icons/ic_map_pin_fill.svg",
                  colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn),
                  height: 24,
                ),
                spaceW(width: 8),
                Expanded(
                  child: TextCustom(
                    title: address.addressAs.toString(),
                    fontSize: 16,
                    fontFamily: FontFamily.medium,
                    color: theme.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                  ),
                ),
                // Top-right action: 3-dot popup menu. Selecting "Set as Default"
                // is the ONLY action that flips isDefault on the addresses and
                // writes to Firestore. Selection of the address itself (radio-
                // like behaviour) happens by tapping the card body.
                address.isDefault == true
                    ? const SizedBox(width: 24)
                    : PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert, color: theme.isDarkTheme() ? AppThemeData.grey3 : AppThemeData.grey7),
                        offset: const Offset(-15, 35),
                        // Explicit background so the menu doesn't inherit the app's
                        // dark popup theme in light mode (which made "Set as
                        // Default" text render black on a near-black card).
                        color: theme.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.primaryWhite,
                        surfaceTintColor: Colors.transparent,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: "SET_DEFAULT",
                              child: Text(
                                "Set as Default".tr,
                                style: TextStyle(fontFamily: FontFamily.regular, color: theme.isDarkTheme() ? AppThemeData.primaryWhite : AppThemeData.primaryBlack, fontSize: 14),
                              ),
                            ),
                          ];
                        },
                        onSelected: (value) {
                          if (value == "SET_DEFAULT") {
                            _setDefaultAddress(controller, address);
                          }
                        },
                      ),
              ],
            ),
            spaceH(height: 8),
            TextCustom(
              title: address.address.toString(),
              fontSize: 12,
              fontFamily: FontFamily.regular,
              color: theme.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6,
              maxLine: 3,
            ),
            spaceH(height: 4),
            TextCustom(title: address.name.toString(), fontSize: 14, fontFamily: FontFamily.medium, color: theme.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
            spaceH(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_edit.svg",
                        colorFilter: ColorFilter.mode(theme.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn),
                        height: 18,
                        width: 18,
                      ),
                      spaceW(width: 4),
                      TextCustom(title: "Edit".tr, fontSize: 13, fontFamily: FontFamily.medium, color: theme.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6),
                    ],
                  ),
                ),
                if (address.isDefault != true) ...[
                  spaceW(width: 20),
                  GestureDetector(
                    onTap: onDelete,
                    child: Row(
                      children: [
                        SvgPicture.asset("assets/icons/ic_delete.svg", colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn), height: 18, width: 18),
                        spaceW(width: 4),
                        TextCustom(title: "Delete".tr, fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.danger300),
                      ],
                    ),
                  ),
                ],
                Spacer(),
                !address.isDefault!
                    ? SizedBox()
                    : Container(
                        margin: const EdgeInsets.only(right: 10, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          "Default".tr,
                          style: TextStyle(fontFamily: FontFamily.medium, fontSize: 14, color: AppThemeData.primaryWhite),
                        ),
                      ).paddingOnly(right: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddAddressBottomSheet extends StatelessWidget {
  final String? addressId;
  final AddAddressModel? addressModel;
  final TextEditingController addressController;
  final TextEditingController locationController;

  const AddAddressBottomSheet({super.key, this.addressId, required this.addressModel, required this.addressController, required this.locationController});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: MyAddressController(),
      builder: (controller) {
        return Form(
          key: controller.formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextCustom(
                          title: addressId!.isNotEmpty ? "Edit Address".tr : "Add Address".tr,
                          fontSize: 20,
                          maxLine: 2,
                          textAlign: TextAlign.start,
                          fontFamily: FontFamily.bold,
                          color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3, shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, color: themeChange.isDarkTheme() ? AppThemeData.grey3 : AppThemeData.grey8, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceH(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextCustom(
                      title: "To ensure accurate delivery or service, please provide your address details below.".tr,
                      fontSize: 16,
                      maxLine: 3,
                      fontFamily: FontFamily.regular,
                      textAlign: TextAlign.start,
                      color: themeChange.isDarkTheme() ? AppThemeData.grey4 : AppThemeData.grey7,
                    ),
                  ),
                  spaceH(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextCustom(
                      title: "Save as".tr,
                      fontSize: 16,
                      fontFamily: FontFamily.medium,
                      color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                    ),
                  ),
                  spaceH(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          CommonTile(
                            title: "Home".tr,
                            icon: "assets/icons/ic_home.svg",
                            textColor: controller.addressAs.value == "Home"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            iconColor: controller.addressAs.value == "Home"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            backgroundColor: controller.addressAs.value == "Home"
                                ? AppThemeData.primary4
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey9
                                : AppThemeData.grey2,
                            onPress: () {
                              controller.addressAs.value = "Home";
                            },
                          ),
                          CommonTile(
                            title: "Work".tr,
                            icon: "assets/icons/ic_work.svg",
                            textColor: controller.addressAs.value == "Work"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            iconColor: controller.addressAs.value == "Work"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            backgroundColor: controller.addressAs.value == "Work"
                                ? AppThemeData.primary4
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey9
                                : AppThemeData.grey2,
                            onPress: () {
                              controller.addressAs.value = "Work";
                            },
                          ),
                          CommonTile(
                            title: "Friends and Family".tr,
                            icon: "assets/icons/ic_user.svg",
                            textColor: controller.addressAs.value == "Friends and Family"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            iconColor: controller.addressAs.value == "Friends and Family"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            backgroundColor: controller.addressAs.value == "Friends and Family"
                                ? AppThemeData.primary4
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey9
                                : AppThemeData.grey2,
                            onPress: () {
                              controller.addressAs.value = "Friends and Family";
                            },
                          ),
                          CommonTile(
                            title: "Other".tr,
                            icon: "assets/icons/ic_map_pin.svg",
                            textColor: controller.addressAs.value == "Other"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            iconColor: controller.addressAs.value == "Other"
                                ? AppThemeData.primaryWhite
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey4
                                : AppThemeData.grey7,
                            backgroundColor: controller.addressAs.value == "Other"
                                ? AppThemeData.primary4
                                : themeChange.isDarkTheme()
                                ? AppThemeData.grey9
                                : AppThemeData.grey2,
                            onPress: () {
                              controller.addressAs.value = "Other";
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  spaceH(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFieldWidget(
                          title: "House / Flat / Floor / Building".tr,
                          hintText: "House / Flat / Floor / Building".tr,
                          controller: locationController,
                          onPress: () {},
                        ),
                        spaceH(height: 16),
                        TextFieldWidget(
                          title: "Area / Sector".tr,
                          hintText: "Area / Sector".tr,
                          controller: addressController,
                          onPress: () {
                            if (addressController.text.isEmpty) {
                              Constant.checkPermission(() async {
                                dynamic value;

                                if (Constant.selectedMap == "Google Map") {
                                  value = Get.to(LocationPickerScreen());
                                } else {
                                  Get.to(OSMLocationPickerScreen());
                                }

                                if (value == null) return;
                                final latLng = value.latLng;

                                final placeMark = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

                                if (placeMark.isEmpty) return;
                                final result = placeMark.first;
                                addressController.text = "${result.name}, ${result.locality}, ${result.administrativeArea}, ${result.postalCode}, ${result.country}";
                                controller.addressModel.value.locality = result.locality;
                                controller.addressModel.value.landmark = result.subLocality;
                                controller.addressModel.value.location = LocationLatLng(latitude: latLng!.latitude, longitude: latLng!.longitude);
                                controller.addressModel.value.address = addressController.text;
                                controller.addressModel.value.id = Constant.getUuid();
                                controller.addressModel.value.isDefault = false;
                                controller.addressModel.value.name = Constant.userModel!.fullNameString();
                              });
                            }
                          },
                        ),
                        spaceH(height: 24),
                        RoundShapeButton(
                          title: "Save".tr,
                          buttonColor: AppThemeData.primary4,
                          buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                          onTap: () async {
                            if (!controller.formKey.currentState!.validate()) return;

                            final updatedAddress = addressModel!
                              ..addressAs = controller.addressAs.value
                              ..address = "${locationController.text.trim()}, ${addressController.text.trim()}"
                              ..id = addressModel!.id ?? Constant.getUuid()
                              ..isDefault = false
                              ..name = Constant.userModel!.fullNameString()
                              ..locality = controller.addressModel.value.locality ?? addressModel!.locality
                              ..landmark = controller.addressModel.value.landmark ?? addressModel!.landmark
                              ..location = controller.addressModel.value.location ?? addressModel!.location;

                            if (addressId == null || addressId!.isEmpty) {
                              await controller.saveAddress(updatedAddress);
                            } else {
                              await controller.updateAddress(addressId!, updatedAddress);
                            }

                            Get.back(result: true);
                          },
                          size: Size(358, ScreenSize.height(7, context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CommonTile extends StatelessWidget {
  String? title;
  String? icon;
  Color? backgroundColor;
  Color? textColor;
  Color? iconColor;
  Function() onPress;

  CommonTile({super.key, this.title, this.icon, this.backgroundColor, this.textColor, this.iconColor, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPress,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              SvgPicture.asset(icon!, color: iconColor, height: 20, width: 20),
              spaceW(width: 8),
              Text(
                title!,
                style: TextStyle(fontFamily: FontFamily.medium, fontSize: 14, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
