import 'dart:ui' show ImageFilter;
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/data/nigeria_locations.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/modules/ads_listing/views/ads_listing_view.dart';
import 'package:eSellify/app/modules/sub_category/views/sub_category_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/price_formatter.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/category_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:eSellify/widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';
import 'package:eSellify/utils/navigation_helper.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // Tireda Custom: memoization caches for per-card derived text (condition
  // label, short location string). Safe because DashboardScreenController
  // holds a single const HomeView instance in pageList for the app's
  // lifetime, so this cache persists correctly across rebuilds without ever
  // going stale for a given ad/address — any cache miss just recomputes,
  // identical output to before. _conditionCache is keyed by object identity
  // since AdModel doesn't guarantee a stable equality/hashCode; _locationCache
  // is keyed by the address String itself since Dart Strings compare by
  // content (identityHashCode on a String is unreliable across instances
  // with the same content).
  static final Map<int, String> _conditionCache = {};
  static final Map<String, String> _locationCache = {};

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          // Tireda Custom: profile avatar leading icon, Nigeria state/LGA location
          // picker (see picker classes below), dark mode toggle, and unread
          // notification dot — none of these exist in the eSellify 1.5 base.
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: 1,
            shadowColor: isDark ? Colors.black26 : Colors.black12,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () {
                  if (FireStoreUtils.getCurrentUid() == null) {
                    Get.toNamed(Routes.LOGIN_SCREEN);
                    return;
                  }
                  Get.toNamed(Routes.PROFILE);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppThemeData.primary4, width: 1.8),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    backgroundImage: (Constant.userModel?.profilePic != null && Constant.userModel!.profilePic!.startsWith('http'))
                        ? NetworkImage(Constant.userModel!.profilePic!)
                        : null,
                    child: (Constant.userModel?.profilePic == null || !Constant.userModel!.profilePic!.startsWith('http'))
                        ? Icon(HugeIcons.strokeRoundedUser03, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)
                        : null,
                  ),
                ),
              ),
            ),
            title: GestureDetector(
              onTap: () async {
                // ── Nigerian State / LGA picker ──
                final result = await _showNigeriaLocationPicker(context, isDark);
                if (result == null) return;

                final address = result.lga.name == "All Nigeria"
                    ? "All Nigeria"
                    : "${result.lga.name}, ${result.state.state}";

                final model = AddAddressModel(
                  id: Constant.getUuid(),
                  address: address,
                  locality: result.lga.name == "All Nigeria" ? "" : result.lga.name,
                  landmark: result.lga.name == "All Nigeria" ? "" : result.state.state,  addressAs: "Home",
                  isDefault: true,
                  name: FireStoreUtils.getCurrentUid() != null
                      ? Constant.userModel?.fullNameString() ?? ""
                      : "",
                  location: LocationLatLng(
                    latitude: result.lga.lat,
                    longitude: result.lga.lng,
                  ),
                );

                Constant.currentLocation.value = model;

                if (FireStoreUtils.getCurrentUid() != null) {
                  Constant.userModel?.addAddresses ??= [];
                  final existing = Constant.userModel!.addAddresses!
                      .indexWhere((a) => a.isDefault == true);
                  if (existing >= 0) {
                    Constant.userModel!.addAddresses![existing] = model;
                  } else {
                    Constant.userModel!.addAddresses!.add(model);
                  }
                  await FireStoreUtils.updateUser(Constant.userModel!);
                } else {
                  Preferences.setString(
                    Preferences.selectedAddressKey,
                    jsonEncode(model.toJson()),
                  );
                }

                controller.getData();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "assets/icons/ic_map_pin.svg",
                    colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn),
                    height: 16,
                  ),
                  spaceW(width: 6),
                  Flexible(
                    child: Obx(
                          () => TextCustom(
                        title: Constant.currentLocation.value?.getFullAddress() ?? "Select Location".tr,
                        fontSize: 14,
                        fontFamily: FontFamily.semiBold,
                        maxLine: 1,
                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                      ),
                    ),
                  ),
                  spaceW(width: 4),
                  Icon(HugeIcons.strokeRoundedArrowDown01, color: isDark ? AppThemeData.grey5 : AppThemeData.grey7, size: 16),
                ],
              ).paddingOnly(right: 12, left: 12),
            ),
            actions: [
              // ── Dark Mode Toggle ──
              GestureDetector(
                onTap: () => themeChange.darkTheme = themeChange.isDarkTheme() ? 1 : 0,
                child: Icon(
                  isDark ? HugeIcons.strokeRoundedSun03 : HugeIcons.strokeRoundedMoon02,
                  size: 22,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                ),
              ),
              spaceW(width: 16),
              // ── Notification Bell with dynamic dot badge ──
              GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.NOTIFICATIONS);
                },
                child: Obx(
                      () => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_bell.svg",
                        height: 24,
                        colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn),
                      ),
                      if (controller.hasUnreadNotifications.value)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            height: 9,
                            width: 9,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ).paddingOnly(right: 16),
            ],
          ),
          // Tireda Custom: scoped Obx wraps only the body content instead of
          // the entire Scaffold rebuilding on every controller change. The
          // AppBar (avatar, location text, dark-mode toggle, bell) and the
          // Scaffold shell no longer rebuild when categories/banners/sections/
          // all-ads independently finish loading.
          body: RefreshIndicator(
            onRefresh: () async {
              controller.getData();
            },
            child: Obx(() {
              if (controller.isSectionsLoading.value && controller.categoryList.isEmpty) {
                return ShimmerWidgets.homeShimmer(isDark);
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tireda Custom: two-part search bar (input + "Explore" button)
                      _buildSearchBar(themeChange, controller),
                      spaceH(height: 16),

                      // Ad Banner
                      const Center(child: AdBannerWidget()),
                      spaceH(height: 8),

                      // Banner Carousel — Tireda Custom: scoped Obx so a banner
                      // reload doesn't rebuild categories/sections/all-ads below it.
                      Obx(() {
                        if (controller.bannerList.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _buildBannerCarousel(controller, isDark),
                            spaceH(height: 16),
                          ],
                        );
                      }),

                      // Tireda Custom: full category list in a 4-column grid,
                      // no section header (kept intentionally, do not restyle).
                      // Tireda Custom: scoped Obx so category reload doesn't
                      // rebuild banners/sections/all-ads.
                      Obx(() {
                        if (controller.categoryList.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            // _buildSectionHeader("Categories", isDark: isDark),
                            // spaceH(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                // Tireda Custom: raised from 0.90 to 1.05 to shrink
                                // overall category card height (see _buildCategoryChip
                                // for the matching icon/text size reduction).
                                childAspectRatio: 1.05,
                              ),
                              itemCount: controller.categoryList.length,
                              itemBuilder: (context, index) {
                                CategoryModel category = controller.categoryList[index];
                                return _buildCategoryChip(category, themeChange);
                              },
                            ),
                            spaceH(height: 20),
                          ],
                        );
                      }),

                      // Feature Sections — Tireda Custom: scoped Obx so section
                      // reload doesn't rebuild categories/banners/all-ads.
                      Obx(
                            () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: controller.featureSections.map((section) {
                            final ads = controller.sectionAds[section.id] ?? [];
                            if (ads.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  // Tireda Custom Merge (eSellify 1.5): localized section title/description.
                                  section.titleFor(Get.locale?.languageCode),
                                  isDark: isDark,
                                  onViewAll: () => Get.to(() => const AdsListingView(), arguments: {"section": section}),
                                ),
                                if (section.descriptionFor(Get.locale?.languageCode).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: TextCustom(title: section.descriptionFor(Get.locale?.languageCode), fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                  ),
                                spaceH(height: 8),
                                _buildAdSection(ads, section.styleIndex ?? 0, isDark, context),
                                spaceH(height: 20),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      // All Ads section
                      _buildAllAdsSection(controller, isDark, context),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─── All Ads Section ──────────────────────────────────────
  Widget _buildAllAdsSection(HomeController controller, bool isDark, BuildContext context) {
    return Obx(() {
      if (controller.isAllAdsLoading.value && controller.allAdsPreview.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4),
          ),
        );
      }

      final ads = controller.allAdsPreview;
      if (ads.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'All Ads'.tr,
            isDark: isDark,
            onViewAll: () => Get.to(() => const AdsListingView()),
          ),
          spaceH(height: 8),
          _buildGridStyle(ads, isDark, context),
          spaceH(height: 20),
        ],
      );
    });
  }

  // ─── Section Header ────────────────────────────────────────
  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll, required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextCustom(title: title, fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: TextCustom(title: "View All".tr, fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
          ),
      ],
    );
  }

  // ─── Ad Section (4 styles) ─────────────────────────────────
  Widget _buildAdSection(List<AdModel> ads, int styleIndex, bool isDark, BuildContext context) {
    switch (styleIndex) {
      case 0:
        return _buildHorizontalList(ads, isDark);
      case 1:
        return _buildVerticalList(ads, isDark);
      case 2:
        return _buildGridStyle(ads, isDark, context);
      case 3:
      // Tireda Custom Merge (eSellify 1.5): adopted 1.5's auto-advancing
      // blurred-background banner carousel, replacing Tireda's simpler
      // PageView carousel style.
        return _buildCarouselStyle(ads, isDark, context);
      default:
        return _buildHorizontalList(ads, isDark);
    }
  }

  // ─── Jiji-Style "Verified ID" Badge ───
  // Tireda Custom: not present in eSellify 1.5.
  Widget _verifiedBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user, size: 10, color: AppThemeData.primary4),
        spaceW(width: 4),
        TextCustom(title: "Verified ID".tr, fontSize: 10, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4),
      ],
    );
  }

  // ─── Style 0: Horizontal List ──────────────────────────────
  // Tireda Custom: distinct card layout (condition + verified badges,
  // PriceFormatter, goToAdDetail nav) vs. eSellify 1.5's simpler version.
  Widget _buildHorizontalList(List<AdModel> ads, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ads.length,
        itemBuilder: (_, index) {
          final ad = ads[index];
          final isFeatured = ad.isFeatured == true;
          return GestureDetector(
            onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ad)),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: double.infinity,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: isFeatured
                          ? Border.all(color: AppThemeData.primary4, width: 2.4)
                          : Border.all(color: Colors.transparent, width: 0),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _adImage(ad, isDark, height: double.infinity, width: double.infinity),
                        if (isFeatured) Positioned(top: 4, left: 4, child: _featuredBadge(fontSize: 8, iconSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tireda Custom Merge (eSellify 1.5): localized title.
                          TextCustom(title: PriceFormatter.format(ad), fontSize: 15, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                          spaceH(height: 4),
                          TextCustom(title: ad.titleFor(Get.locale?.languageCode), fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                          spaceH(height: 4),

                          if (ad.isSellerVerified == true) ...[
                            _verifiedBadge(),
                            spaceH(height: 4),
                          ],

                          Row(
                            children: [
                              Icon(HugeIcons.strokeRoundedLocation01, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                              spaceW(width: 4),
                              Expanded(
                                child: TextCustom(title: ad.address.toString(), fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Style 1: Vertical List ────────────────────────────────
  // Tireda Custom: not present as a distinct style with this layout in eSellify 1.5.
  Widget _buildVerticalList(List<AdModel> ads, bool isDark) {
    return Column(
      children: ads.map((ad) {
        final isFeatured = ad.isFeatured == true;
        return GestureDetector(
          onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ad)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isFeatured
                        ? Border.all(color: AppThemeData.primary4, width: 2.4)
                        : Border.all(color: Colors.transparent, width: 0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _adImage(ad, isDark, height: double.infinity, width: double.infinity),
                      if (isFeatured) Positioned(top: 4, left: 4, child: _featuredBadge(fontSize: 8, iconSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(title: PriceFormatter.format(ad), fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                        spaceH(height: 6),
                        // Tireda Custom Merge (eSellify 1.5): localized title.
                        TextCustom(title: ad.titleFor(Get.locale?.languageCode), fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
                        spaceH(height: 6),

                        if (ad.isSellerVerified == true) ...[
                          _verifiedBadge(),
                          spaceH(height: 6),
                        ],

                        Row(
                          children: [
                            Icon(HugeIcons.strokeRoundedLocation01, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            spaceW(width: 4),
                            Expanded(
                              child: TextCustom(title: ad.address.toString(), fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Style 2: Grid (2 columns) ────────────────────────────
  Widget _buildGridStyle(List<AdModel> ads, bool isDark, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ads.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 265, // Increased slightly for compact metadata
      ),
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ads[index])),
        child: _buildAdCard(ads[index], isDark),
      ),
    );
  }

  // ─── Style 3: Carousel ─────────────────────────────────────
  Widget _buildCarouselStyle(List<AdModel> ads, bool isDark, BuildContext context) {
    return _SectionBannerCarousel(ads: ads, isDark: isDark);
  }

  // ─── Location Formatter ─────────────────────────────────────
  // Tireda Custom: not present in eSellify 1.5.
  // Tireda Custom: memoized — see _locationCache doc comment at class top.
  String _formatShortLocation(String? address) {
    if (address == null || address.isEmpty) return '';

    final cached = _locationCache[address];
    if (cached != null) return cached;

    final parts = address.split(',');

    String result;
    if (parts.length < 2) {
      result = address.replaceAll('State', '').trim();
    } else {
      final localGovt = parts.first.trim();

      String state = parts[1]
          .replaceAll('State', '')
          .replaceAll('(FCT)', '')
          .trim();

      result = '$state, $localGovt';
    }

    _locationCache[address] = result;
    return result;
  }

  // ─── Condition Extractor ────────────────────────────────────
  // Tireda Custom: not present in eSellify 1.5.
  // Tireda Custom: memoized — see _conditionCache doc comment at class top.
  String _getCondition(AdModel ad) {
    final key = identityHashCode(ad);
    final cached = _conditionCache[key];
    if (cached != null) return cached;

    String result = '';
    try {
      if (ad.customFields != null && ad.customFields!.isNotEmpty) {
        for (final field in ad.customFields!) {
          final name = field['name']?.toString().toLowerCase() ?? '';

          if (name.contains('condition')) {
            result = field['value']?.toString() ?? '';
            break;
          }
        }
      }
    } catch (e) {
      result = '';
    }

    _conditionCache[key] = result;
    return result;
  }

  // ─── Ad Card (Grid) ────────────────────────────────────────
  // Tireda Custom: condition + verified badges, PriceFormatter, no like icon
  // (eSellify 1.5's grid card is simpler and adds a like/favorite icon —
  // intentionally not adopted here).
  Widget _buildAdCard(AdModel ad, bool isDark) {
    final condition = _getCondition(ad);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ad.isFeatured == true
              ? AppThemeData.primary4
              : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── IMAGE AREA ─────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _adImage(
                    ad,
                    isDark,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),

                if (ad.isFeatured == true)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _featuredBadge(
                      fontSize: 8,
                      iconSize: 10,
                    ),
                  ),
              ],
            ),
          ),

          // ─── TEXT AREA ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // PRICE
                TextCustom(
                  title: PriceFormatter.format(ad),
                  fontSize: 14,
                  fontFamily: FontFamily.bold,
                  color: AppThemeData.primary4,
                  maxLine: 1,
                ),

                spaceH(height: 2),

                // TITLE
                // Tireda Custom Merge (eSellify 1.5): localized title.
                TextCustom(
                  title: ad.titleFor(Get.locale?.languageCode),
                  fontSize: 12,
                  fontFamily: FontFamily.medium,
                  color: isDark
                      ? AppThemeData.grey1
                      : AppThemeData.grey10,
                  maxLine: 1,
                ),

                spaceH(height: 4),

                // CONDITION + VERIFIED
                Row(
                  children: [

                    if (condition.isNotEmpty) ...[
                      Flexible(
                        child: TextCustom(
                          title: condition,
                          fontSize: 10,
                          fontFamily: FontFamily.medium,
                          color: isDark
                              ? AppThemeData.grey5
                              : AppThemeData.grey6,
                          maxLine: 1,
                        ),
                      ),
                    ],

                    if (condition.isNotEmpty && ad.isSellerVerified == true) ...[
                      spaceW(width: 5),

                      TextCustom(
                        title: "•",
                        fontSize: 10,
                        fontFamily: FontFamily.medium,
                        color: isDark
                            ? AppThemeData.grey5
                            : AppThemeData.grey6,
                      ),

                      spaceW(width: 5),
                    ],

                    if (ad.isSellerVerified == true) ...[
                      Icon(
                        Icons.verified_user,
                        size: 11,
                        color: AppThemeData.primary4,
                      ),

                      spaceW(width: 4),

                      TextCustom(
                        title: "Verified ID".tr,
                        fontSize: 10,
                        fontFamily: FontFamily.semiBold,
                        color: AppThemeData.primary4,
                      ),
                    ],
                  ],
                ),

                spaceH(height: 4),

                // LOCATION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    Icon(
                      HugeIcons.strokeRoundedLocation01,
                      size: 11,
                      color: isDark
                          ? AppThemeData.grey5
                          : AppThemeData.grey6,
                    ),

                    spaceW(width: 3),

                    Expanded(
                      child: TextCustom(
                        title: _formatShortLocation(ad.address),
                        fontSize: 10,
                        color: isDark
                            ? AppThemeData.grey5
                            : AppThemeData.grey6,
                        maxLine: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Featured Badge ────────────────────────────────────────
  Widget _featuredBadge({double fontSize = 9, double iconSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(HugeIcons.strokeRoundedStar, size: iconSize, color: Colors.white),
          const SizedBox(width: 2),
          Text("Featured".tr, style: TextStyle(fontSize: fontSize, fontFamily: FontFamily.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // ─── Ad Image ──────────────────────────────────────────────
  Widget _adImage(AdModel ad, bool isDark, {required double height, double? width}) {
    return (ad.mainImage != null && ad.mainImage!.isNotEmpty)
        ? CachedNetworkImage(
      imageUrl: ad.mainImage!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(height: height, width: width, color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
      errorWidget: (_, __, ___) => Container(
        height: height,
        width: width,
        color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
        child: Center(child: Icon(HugeIcons.strokeRoundedImage03, size: 32, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
      ),
    )
        : Container(
      height: height,
      width: width,
      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
      child: Center(child: Icon(HugeIcons.strokeRoundedImage03, size: 32, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
    );
  }

  // ─── Category Card Background ───────────────────────────────
  // Tireda Custom: not present in eSellify 1.5.
  Color _getCategoryCardBg(bool isDark) {
    if (isDark) {
      return AppThemeData.grey9;
    }
    return AppThemeData.primary1.withOpacity(0.4);
  }

  // ─── Category Card Border ───────────────────────────────────
  // Tireda Custom: not present in eSellify 1.5.
  Color _getCategoryCardBorderColor(bool isDark) {
    if (isDark) {
      return AppThemeData.grey8;
    }
    return AppThemeData.grey3;
  }

  // ─── Category Chip ─────────────────────────────────────────
  // Tireda Custom: haptic feedback + Material/InkWell splash styling not
  // present in eSellify 1.5. Image widget, display name, and navigation
  // updated to match the CategoryImageWidget/categoryNameFor/constructor-nav
  // pattern already merged in CategoriesView and SubCategoryView.
  // Tireda Custom (design): icon shrunk 40x40 -> 32x32, label 10 -> 9,
  // icon/label gap 4 -> 3, paired with childAspectRatio 0.90 -> 1.05 on the
  // GridView above, to reduce how much vertical space the category section
  // takes on the home screen while keeping the 8px grid spacing unchanged.
  Widget _buildCategoryChip(CategoryModel category, DarkThemeProvider themeChange) {
    final isDark = themeChange.isDarkTheme();
    final cardBg = _getCategoryCardBg(isDark);
    final borderColor = _getCategoryCardBorderColor(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => SubCategoryView(category: category));
        },
        borderRadius: BorderRadius.circular(14),
        splashColor: AppThemeData.primary4.withOpacity(0.12),
        highlightColor: AppThemeData.primary4.withOpacity(0.06),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon centered inside the card ──
              SizedBox(
                width: 32,
                height: 32,
                child: CategoryImageWidget(
                  imageUrl: category.image.toString(),
                  isDark: isDark,
                  radius: 6,
                  fallbackIconSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              // ── Text inside the card, below icon ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextCustom(
                  title: category.categoryNameFor(Get.locale?.languageCode),
                  fontSize: 9,
                  fontFamily: FontFamily.semiBold,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                  textAlign: TextAlign.center,
                  maxLine: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner Carousel ───────────────────────────────────────
  Widget _buildBannerCarousel(HomeController controller, bool isDark) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 15 / 7,
          child: PageView.builder(
            controller: controller.bannerPageController,
            itemCount: controller.bannerList.length,
            onPageChanged: controller.onBannerPageChanged,
            itemBuilder: (_, index) {
              final banner = controller.bannerList[index];
              return GestureDetector(
                onTap: () => controller.onBannerTap(banner),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (banner.image != null && banner.image!.startsWith('http'))
                      ? CachedNetworkImage(
                    imageUrl: banner.image!,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    placeholder: (_, _) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                    errorWidget: (_, _, _) => Container(
                      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                      child: Center(child: Icon(HugeIcons.strokeRoundedImage03, size: 40, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Icon(HugeIcons.strokeRoundedImage03, size: 40, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                  ),
                ),
              );
            },
          ),
        ),
        if (controller.bannerList.length > 1) ...[
          spaceH(height: 10),
          Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(controller.bannerList.length, (index) {
                final isActive = controller.currentBannerIndex.value == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4), borderRadius: BorderRadius.circular(3)),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Search Bar ────────────────────────────────────────────
  // Tireda Custom: two-part search bar (input + "Explore" button) — eSellify
  // 1.5 uses a single simple search field.
  Widget _buildSearchBar(DarkThemeProvider themeChange, HomeController controller) {
    final isDark = themeChange.isDarkTheme();
    return Row(
      children: [
        // ── Search input (~70% width) ──
        Expanded(
          flex: 7,
          child: GestureDetector(
            onTap: () => Get.toNamed(Routes.SEARCH),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(HugeIcons.strokeRoundedSearch01, size: 18, color: AppThemeData.primary4),
                  spaceW(width: 12),
                  TextCustom(title: "Search ads, categories...".tr, fontSize: 14, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                ],
              ),
            ),
          ),
        ),

        // ── "or" separator ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextCustom(
            title: "or",
            fontSize: 12,
            fontFamily: FontFamily.regular,
            color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
          ),
        ),

        // ── Explore button (~25% width) ──
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => Get.to(() => const AdsListingView()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppThemeData.primary4,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedCatalogue, size: 16, color: Colors.white),
                  spaceW(width: 5),
                  Flexible(
                    child: TextCustom(
                      title: "Explore",
                      fontSize: 13,
                      fontFamily: FontFamily.semiBold,
                      color: Colors.white,
                      maxLine: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Tireda Custom Merge (eSellify 1.5): adopted banner-type carousel for the
// "Carousel Style" feature section — one full-width slide per ad (blurred
// cover background + full-contain product image + gradient + title/price
// overlay), auto-advancing with dot indicators. Navigation and price
// formatting adapted to use Tireda's goToAdDetail() helper and
// PriceFormatter.format() instead of 1.5's inline equivalents.
class _SectionBannerCarousel extends StatefulWidget {
  const _SectionBannerCarousel({required this.ads, required this.isDark});
  final List<AdModel> ads;
  final bool isDark;

  @override
  State<_SectionBannerCarousel> createState() => _SectionBannerCarouselState();
}

class _SectionBannerCarouselState extends State<_SectionBannerCarousel> {
  // 80% width per slide so the next ad peeks in from the right.
  final PageController _controller = PageController(viewportFraction: 0.8);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.ads.length < 2 || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % widget.ads.length, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: ads.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final ad = ads[i];
              return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: GestureDetector(
                        onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ad)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Product photos have arbitrary aspect ratios — a plain cover fit
                            // crops/zooms them into a stretched-looking mess. Show the FULL image
                            // (contain) over a blurred cover of itself so the banner stays filled
                            // without distorting the product.
                            if (ad.mainImage != null && ad.mainImage!.isNotEmpty) ...[
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: CachedNetworkImage(imageUrl: ad.mainImage!, fit: BoxFit.cover),
                              ),
                              Container(color: Colors.black.withValues(alpha: 0.25)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: CachedNetworkImage(imageUrl: ad.mainImage!, fit: BoxFit.contain),
                              ),
                            ] else
                              Container(color: widget.isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.4, 1.0],
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.titleFor(Get.locale?.languageCode),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 17, fontFamily: FontFamily.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(PriceFormatter.format(ad), style: TextStyle(fontSize: 15, fontFamily: FontFamily.bold, color: AppThemeData.primary2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )));
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < ads.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppThemeData.primary4 : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nigeria Location Picker ──────────────────────────────────────────────────
// Tireda Custom: entire section below is not present in eSellify 1.5, which
// uses a generic MyAddressView/EnterLocationView flow instead.

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
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Select State", style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: textColor)),
      ),
      body: Column(
        children: [
          // Search
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
                prefixIcon: Icon(HugeIcons.strokeRoundedSearch01, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          // All Nigeria option
          InkWell(
            onTap: () {
              final allNigeriaLGA = NigeriaLGA(name: "All Nigeria", lat: NigeriaLocations.allNigeriaLat, lng: NigeriaLocations.allNigeriaLng);
              final allNigeriaState = NigeriaLocation(state: "All Nigeria", stateLat: NigeriaLocations.allNigeriaLat, stateLng: NigeriaLocations.allNigeriaLng, lgas: []);
              Navigator.of(context).pop(_LocationResult(state: allNigeriaState, lga: allNigeriaLGA));
            },
            child: Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Row(
                children: [
                  Icon(HugeIcons.strokeRoundedGlobe02, size: 20, color: AppThemeData.primary4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("All Nigeria", style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: AppThemeData.primary4)),
                        const SizedBox(height: 2),
                        Text("Browse ads across Nigeria", style: TextStyle(fontSize: 12, color: subColor)),
                      ],
                    ),
                  ),
                  Icon(HugeIcons.strokeRoundedTick01, color: AppThemeData.primary4, size: 20),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          // States list
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final state = _filtered[i];
                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context).push<_LocationResult>(
                      MaterialPageRoute(builder: (_) => _NigeriaLGAPicker(state: state, isDark: widget.isDark)),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: Row(
                      children: [
                        Icon(HugeIcons.strokeRoundedCity01, size: 20, color: subColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.state, style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: textColor)),
                              const SizedBox(height: 2),
                              Text("${state.lgas.length} LGAs", style: TextStyle(fontSize: 12, color: subColor)),
                            ],
                          ),
                        ),
                        Icon(HugeIcons.strokeRoundedArrowRight01, color: subColor, size: 20),
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
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select LGA", style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: textColor)),
            Text(widget.state.state, style: TextStyle(fontSize: 12, color: AppThemeData.primary4)),
          ],
        ),
      ),
      body: Column(
        children: [
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
                prefixIcon: Icon(HugeIcons.strokeRoundedSearch01, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final lga = _filtered[i];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(_LocationResult(state: widget.state, lga: lga)),
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: Row(
                      children: [
                        Icon(HugeIcons.strokeRoundedLocation01, size: 20, color: subColor),
                        const SizedBox(width: 12),
                        Expanded(child: Text(lga.name, style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: textColor))),
                        Icon(HugeIcons.strokeRoundedArrowRight01, color: subColor, size: 20),
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