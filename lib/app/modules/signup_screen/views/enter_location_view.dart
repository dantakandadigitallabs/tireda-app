// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/data/nigeria_locations.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/modules/signup_screen/controllers/enter_location_controller.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
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
                // ── Current Location (GPS) ──
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
                // ── Select State / LGA ──
                Row(
                  children: [
                    Expanded(
                      child: RoundShapeButton(
                        title: "Select State & LGA".tr,
                        buttonColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey2,
                        buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                        onTap: () async {
                          final result = await _showNigeriaLocationPicker(
                            context,
                            themeChange.isDarkTheme(),
                          );
                          if (result == null) return;

                          // Build AddAddressModel from selected LGA
                          final address = "${result.lga.name}, ${result.state.state}";
                          final model = AddAddressModel(
                            id: Constant.getUuid(),
                            address: address,
                            locality: result.lga.name,
                            landmark: result.state.state,
                            addressAs: "Home",
                            isDefault: true,
                            name: FireStoreUtils.getCurrentUid() != null ? Constant.userModel!.fullNameString() : "",
                            location: LocationLatLng(
                              latitude: result.lga.lat,
                              longitude: result.lga.lng,
                            ),
                          );

                          controller.addAddressModel.value = model;
                          controller.addressController.value.text = address;
                          Constant.currentLocation.value = model;

                          // Save if logged in
                          if (await FireStoreUtils.isLogin()) {
                            await controller.saveAddress();
                          } else {
                            Preferences.setString(
                              Preferences.selectedAddressKey,
                              jsonEncode(model.toJson()),
                            );
                          }

                          // Navigate
                          if (isRedirectDashboard == true) {
                            Get.offAllNamed(Routes.DASHBOARD_SCREEN);
                          } else {
                            Get.back(result: true);
                          }
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

// ─── Nigeria Location Picker ──────────────────────────────────────────────────

class _LocationResult {
  final NigeriaLocation state;
  final NigeriaLGA lga;
  const _LocationResult({required this.state, required this.lga});
}

Future<_LocationResult?> _showNigeriaLocationPicker(
    BuildContext context,
    bool isDark,
    ) async {
  return await Navigator.of(context).push<_LocationResult>(
    MaterialPageRoute(
      builder: (_) => _NigeriaStatePicker(isDark: isDark),
    ),
  );
}

// ── Step 1: State Picker ──────────────────────────────────────────────────────
class _NigeriaStatePicker extends StatefulWidget {
  final bool isDark;
  const _NigeriaStatePicker({required this.isDark});

  @override
  State<_NigeriaStatePicker> createState() => _NigeriaStatePickerState();
}

class _NigeriaStatePickerState extends State<_NigeriaStatePicker> {
  final TextEditingController _search = TextEditingController();
  List<NigeriaLocation> _filtered = NigeriaLocations.states;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = NigeriaLocations.searchStates(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppThemeData.grey10 : AppThemeData.grey1;
    final cardBg = widget.isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    final textColor = widget.isDark ? AppThemeData.grey1 : AppThemeData.grey10;
    final subColor = widget.isDark ? AppThemeData.grey5 : AppThemeData.grey6;
    final borderColor = widget.isDark ? AppThemeData.grey8 : AppThemeData.grey3;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Select State",
          style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: textColor),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Find state...",
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          // All Nigeria option
          _buildTile(
            context: context,
            title: "All Nigeria",
            subtitle: "Browse ads across Nigeria",
            isAllNigeria: true,
            isDark: widget.isDark,
            textColor: textColor,
            subColor: subColor,
            borderColor: borderColor,
            cardBg: cardBg,
            onTap: () {
              // All Nigeria — use center coords, no state/LGA
              final allNigeriaLGA = NigeriaLGA(
                name: "All Nigeria",
                lat: NigeriaLocations.allNigeriaLat,
                lng: NigeriaLocations.allNigeriaLng,
              );
              final allNigeriaState = NigeriaLocation(
                state: "All Nigeria",
                stateLat: NigeriaLocations.allNigeriaLat,
                stateLng: NigeriaLocations.allNigeriaLng,
                lgas: [],
              );
              Navigator.of(context).pop(
                _LocationResult(state: allNigeriaState, lga: allNigeriaLGA),
              );
            },
          ),
          Divider(height: 1, color: borderColor),
          // States list
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final state = _filtered[i];
                return _buildTile(
                  context: context,
                  title: state.state,
                  subtitle: "${state.lgas.length} LGAs",
                  isDark: widget.isDark,
                  textColor: textColor,
                  subColor: subColor,
                  borderColor: borderColor,
                  cardBg: cardBg,
                  onTap: () async {
                    // Go to LGA picker
                    final result = await Navigator.of(context).push<_LocationResult>(
                      MaterialPageRoute(
                        builder: (_) => _NigeriaLGAPicker(
                          state: state,
                          isDark: widget.isDark,
                        ),
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    required Color cardBg,
    required VoidCallback onTap,
    bool isAllNigeria = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isAllNigeria ? Icons.language_rounded : Icons.location_city_rounded,
              size: 20,
              color: isAllNigeria ? AppThemeData.primary4 : subColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: FontFamily.medium,
                      color: isAllNigeria ? AppThemeData.primary4 : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
            ),
            if (!isAllNigeria)
              Icon(Icons.chevron_right, color: subColor, size: 20),
            if (isAllNigeria)
              Icon(Icons.check, color: AppThemeData.primary4, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: LGA Picker ────────────────────────────────────────────────────────
class _NigeriaLGAPicker extends StatefulWidget {
  final NigeriaLocation state;
  final bool isDark;
  const _NigeriaLGAPicker({required this.state, required this.isDark});

  @override
  State<_NigeriaLGAPicker> createState() => _NigeriaLGAPickerState();
}

class _NigeriaLGAPickerState extends State<_NigeriaLGAPicker> {
  final TextEditingController _search = TextEditingController();
  late List<NigeriaLGA> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.state.lgas;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = NigeriaLocations.searchLGAs(widget.state, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppThemeData.grey10 : AppThemeData.grey1;
    final cardBg = widget.isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    final textColor = widget.isDark ? AppThemeData.grey1 : AppThemeData.grey10;
    final subColor = widget.isDark ? AppThemeData.grey5 : AppThemeData.grey6;
    final borderColor = widget.isDark ? AppThemeData.grey8 : AppThemeData.grey3;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select LGA",
              style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: textColor),
            ),
            Text(
              widget.state.state,
              style: TextStyle(fontSize: 12, color: AppThemeData.primary4),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Find LGA...",
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          // LGA list
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final lga = _filtered[i];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(
                      _LocationResult(state: widget.state, lga: lga),
                    );
                  },
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 20, color: subColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lga.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: FontFamily.medium,
                              color: textColor,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: subColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}