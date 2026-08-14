// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/custom_field_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/utils/price_formatter.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/native_ad_widget.dart';
import 'package:eSellify/widgets/shimmer_widgets.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';

import '../controllers/ads_listing_controller.dart';
import 'package:eSellify/utils/navigation_helper.dart';

class AdsListingView extends GetView<AdsListingController> {
  const AdsListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<AdsListingController>(
      init: AdsListingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, controller.title.value),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),

              // ── Sticky Header ──────────────────────────────────────
              Container(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                child: Column(
                  children: [
                    // Row 1: Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: controller.searchController,
                          style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          decoration: InputDecoration(
                            hintText: "Search any advertisement...".tr,
                            hintStyle: TextStyle(fontSize: 13, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                            prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppThemeData.primary4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Row 2: Quick filter chips (Tireda Customization)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Filters chip
                          _QuickChip(
                            label: "Filters".tr,
                            icon: Icons.tune_rounded,
                            isActive: controller.hasActiveFilter,
                            isDark: isDark,
                            onTap: () => Get.to(() => _FilterView(controller: controller)),
                          ),
                          spaceW(width: 6),

                          // Price preset chips
                          _QuickChip(
                            label: "< ₦500K",
                            isActive: controller.filterMaxPrice.value == 500000 && controller.filterMinPrice.value == null,
                            isDark: isDark,
                            onTap: () {
                              if (controller.filterMaxPrice.value == 500000 && controller.filterMinPrice.value == null) {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = null;
                              } else {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = 500000;
                                controller.minPriceController.clear();
                                controller.maxPriceController.text = '500000';
                              }
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),
                          _QuickChip(
                            label: "₦500K–1M",
                            isActive: controller.filterMinPrice.value == 500000 && controller.filterMaxPrice.value == 1000000,
                            isDark: isDark,
                            onTap: () {
                              if (controller.filterMinPrice.value == 500000 && controller.filterMaxPrice.value == 1000000) {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = null;
                              } else {
                                controller.filterMinPrice.value = 500000;
                                controller.filterMaxPrice.value = 1000000;
                                controller.minPriceController.text = '500000';
                                controller.maxPriceController.text = '1000000';
                              }
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),
                          _QuickChip(
                            label: "₦1M–3M",
                            isActive: controller.filterMinPrice.value == 1000000 && controller.filterMaxPrice.value == 3000000,
                            isDark: isDark,
                            onTap: () {
                              if (controller.filterMinPrice.value == 1000000 && controller.filterMaxPrice.value == 3000000) {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = null;
                              } else {
                                controller.filterMinPrice.value = 1000000;
                                controller.filterMaxPrice.value = 3000000;
                                controller.minPriceController.text = '1000000';
                                controller.maxPriceController.text = '3000000';
                              }
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),
                          _QuickChip(
                            label: "₦3M–5M",
                            isActive: controller.filterMinPrice.value == 3000000 && controller.filterMaxPrice.value == 5000000,
                            isDark: isDark,
                            onTap: () {
                              if (controller.filterMinPrice.value == 3000000 && controller.filterMaxPrice.value == 5000000) {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = null;
                              } else {
                                controller.filterMinPrice.value = 3000000;
                                controller.filterMaxPrice.value = 5000000;
                                controller.minPriceController.text = '3000000';
                                controller.maxPriceController.text = '5000000';
                              }
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),
                          _QuickChip(
                            label: "> ₦5M",
                            isActive: controller.filterMinPrice.value == 5000000 && controller.filterMaxPrice.value == null,
                            isDark: isDark,
                            onTap: () {
                              if (controller.filterMinPrice.value == 5000000 && controller.filterMaxPrice.value == null) {
                                controller.filterMinPrice.value = null;
                                controller.filterMaxPrice.value = null;
                              } else {
                                controller.filterMinPrice.value = 5000000;
                                controller.filterMaxPrice.value = null;
                                controller.minPriceController.text = '5000000';
                                controller.maxPriceController.clear();
                              }
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),

                          // Verified seller chip
                          _QuickChip(
                            label: "Verified".tr,
                            icon: Icons.verified_user_outlined,
                            isActive: controller.filterVerifiedOnly.value,
                            isDark: isDark,
                            onTap: () {
                              controller.filterVerifiedOnly.value = !controller.filterVerifiedOnly.value;
                              controller.applyFilter();
                            },
                          ),
                          spaceW(width: 6),

                          // Promoted ads chip
                          _QuickChip(
                            label: "Promoted".tr,
                            icon: Icons.star_outline_rounded,
                            isActive: controller.filterFeaturedOnly.value,
                            isDark: isDark,
                            onTap: () {
                              controller.filterFeaturedOnly.value = !controller.filterFeaturedOnly.value;
                              controller.applyFilter();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Row 3: Results count + Sort + View toggle
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          // Results count
                          Expanded(
                            child: TextCustom(
                              title: controller.isLoading.value
                                  ? "Loading...".tr
                                  : "Found ${controller.filteredAds.length} ad${controller.filteredAds.length == 1 ? '' : 's'}".tr,
                              fontSize: 13,
                              fontFamily: FontFamily.medium,
                              color: isDark ? AppThemeData.grey4 : AppThemeData.grey7,
                            ),
                          ),

                          // Sort button
                          GestureDetector(
                            onTap: () => _showSortSheet(context, controller, isDark),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                                color: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_vert, size: 16, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
                                  spaceW(width: 4),
                                  TextCustom(
                                    title: AdsListingController.sortOptions.firstWhere(
                                          (o) => o['key'] == controller.sortBy.value,
                                      orElse: () => {'label': 'Sort'.tr},
                                    )['label']!,
                                    fontSize: 12,
                                    fontFamily: FontFamily.medium,
                                    color: isDark ? AppThemeData.grey4 : AppThemeData.grey7,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          spaceW(width: 8),

                          // List toggle
                          _viewToggle(controller, 0, Icons.view_list_rounded, isDark),
                          spaceW(width: 6),
                          // Grid toggle
                          _viewToggle(controller, 1, Icons.grid_view_rounded, isDark),
                        ],
                      ),
                    ),

                    Divider(height: 1, thickness: 0.5, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                  ],
                ),
              ),

              // ── Ads List ───────────────────────────────────────────
              Expanded(
                child: controller.isLoading.value
                    ? ShimmerWidgets.adListShimmer(isDark)
                    : controller.filteredAds.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                      spaceH(height: 12),
                      TextCustom(title: "No Ads Found".tr, fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    Expanded(
                      child: controller.viewMode.value == 1
                          ? _buildListView(controller, isDark)
                          : _buildGridView(controller, isDark),
                    ),
                    if (controller.isLoadingMore.value)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _viewToggle(AdsListingController controller, int mode, IconData icon, bool isDark) {
    final isActive = controller.viewMode.value == mode;
    return GestureDetector(
      onTap: () => controller.viewMode.value = mode,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
          color: isActive ? AppThemeData.primary4.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(icon, size: 18, color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
      ),
    );
  }

  // ─── Tireda Location Formatter ────────────────────────────
  String _formatShortLocation(String? address) {
    if (address == null || address.isEmpty) return '';
    final parts = address.split(',');
    if (parts.length < 2) {
      return address.replaceAll('State', '').trim();
    }
    final localGovt = parts.first.trim();
    String state = parts[1]
        .replaceAll('State', '')
        .replaceAll('(FCT)', '')
        .trim();
    return '$state, $localGovt';
  }

  // ─── Tireda Condition Extractor ───────────────────────────
  String _getCondition(AdModel ad) {
    try {
      if (ad.customFields == null || ad.customFields!.isEmpty) {
        return '';
      }
      for (final field in ad.customFields!) {
        final name = field['name']?.toString().toLowerCase() ?? '';
        if (name.contains('condition')) {
          return field['value']?.toString() ?? '';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // ─── List View ─────────────────────────────────────────────
  Widget _buildListView(AdsListingController controller, bool isDark) {
    final data = controller.filteredAds;
    return ListView.separated(
      controller: controller.scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: data.length + (data.length ~/ 5),
      separatorBuilder: (_, _) => spaceH(height: 10),
      itemBuilder: (_, index) {
        if (index % 6 == 5) return NativeAdWidget(key: ValueKey('native_list_$index'));
        final realIndex = index - (index ~/ 6);
        if (realIndex >= data.length) return const SizedBox.shrink();
        final ad = data[realIndex];
        return GestureDetector(
          onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ad)),
          child: _buildListCard(ad, isDark),
        );
      },
    );
  }

  Widget _buildListCard(AdModel ad, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                child: _adImage(ad, isDark, width: 130, height: 130),
              ),
              if (ad.isFeatured == true)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [const Icon(Icons.star_rounded, size: 12, color: Colors.white), const SizedBox(width: 2), Text("Featured".tr, style: const TextStyle(fontSize: 9, fontFamily: FontFamily.bold, color: Colors.white))],
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextCustom(title: _formatPrice(ad), fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                      ),
                      _LikeButton(ad: ad, size: 22),
                    ],
                  ),
                  spaceH(height: 4),
                  // Using v1.5 localized title logic
                  TextCustom(title: ad.titleFor(Get.locale?.languageCode), fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
                  spaceH(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      spaceW(width: 4),
                      Expanded(
                        child: TextCustom(title: ad.address.toString(), fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                      ),
                    ],
                  ),
                  spaceH(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      spaceW(width: 4),
                      TextCustom(title: _timeAgo(ad), fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid View ─────────────────────────────────────────────
  Widget _buildGridView(AdsListingController controller, bool isDark) {
    return GridView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredAds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 265,
      ),
      itemBuilder: (_, index) {
        final ad = controller.filteredAds[index];
        return GestureDetector(
          onTap: () => AdService.showInterstitial(onDismissed: () => goToAdDetail(ad)),
          child: _buildGridCard(ad, isDark),
        );
      },
    );
  }

  Widget _buildGridCard(AdModel ad, bool isDark) {
    final condition = _getCondition(ad);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ad.isFeatured == true
              ? AppThemeData.primary4
              : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
          width: 1.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffFF9500),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text("Featured".tr, style: const TextStyle(fontSize: 8, fontFamily: FontFamily.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price
                TextCustom(
                  title: _formatPrice(ad),
                  fontSize: 14,
                  fontFamily: FontFamily.bold,
                  color: AppThemeData.primary4,
                  maxLine: 1,
                ),
                spaceH(height: 2),

                // Title (using v1.5 localized title logic)
                TextCustom(
                  title: ad.titleFor(Get.locale?.languageCode),
                  fontSize: 12,
                  fontFamily: FontFamily.medium,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                  maxLine: 1,
                ),
                spaceH(height: 4),

                // Condition + Verified ID (Tireda custom logic)
                Row(
                  children: [
                    if (condition.isNotEmpty) ...[
                      Flexible(
                        child: TextCustom(
                          title: condition,
                          fontSize: 10,
                          fontFamily: FontFamily.medium,
                          color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
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
                        color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                      ),
                      spaceW(width: 5),
                    ],
                    if (ad.isSellerVerified == true) ...[
                      Icon(Icons.verified_user, size: 11, color: AppThemeData.primary4),
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

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                    ),
                    spaceW(width: 2),
                    Expanded(
                      child: TextCustom(
                        title: _formatShortLocation(ad.address),
                        fontSize: 10,
                        color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
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

  Widget _adImage(AdModel ad, bool isDark, {required double height, double? width}) {
    return (ad.mainImage != null && ad.mainImage!.isNotEmpty)
        ? CachedNetworkImage(
      imageUrl: ad.mainImage!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(height: height, width: width, color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
    )
        : Container(
      height: height,
      width: width,
      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
      child: Center(child: Icon(Icons.image_outlined, size: 32, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
    );
  }

  // ─── Sort Bottom Sheet ─────────────────────────────────────
  void _showSortSheet(BuildContext context, AdsListingController controller, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2)),
            ),
            spaceH(height: 16),
            ...AdsListingController.sortOptions.map((opt) {
              final isSelected = controller.sortBy.value == opt['key'];
              return ListTile(
                onTap: () {
                  controller.setSortBy(opt['key']!);
                  Get.back();
                },
                title: TextCustom(
                  title: opt['label']!.tr,
                  fontSize: 16,
                  fontFamily: isSelected ? FontFamily.bold : FontFamily.regular,
                  color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ),
                trailing: isSelected ? Icon(Icons.check, color: AppThemeData.primary4) : null,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────
  String _formatPrice(AdModel ad) {
    return PriceFormatter.format(ad);
  }

  // v1.5 Time ago formatting with explicit .tr translations
  String _timeAgo(AdModel ad) {
    if (ad.createdAt == null) return '';
    final diff = DateTime.now().difference(ad.createdAt!.toDate());
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} ${(diff.inDays / 365).floor() > 1 ? 'years ago'.tr : 'year ago'.tr}';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} ${(diff.inDays / 30).floor() > 1 ? 'months ago'.tr : 'month ago'.tr}';
    if (diff.inDays > 0) return '${diff.inDays} ${diff.inDays > 1 ? 'days ago'.tr : 'day ago'.tr}';
    if (diff.inHours > 0) return '${diff.inHours} ${diff.inHours > 1 ? 'hours ago'.tr : 'hour ago'.tr}';
    if (diff.inMinutes > 0) return '${diff.inMinutes} ${'min ago'.tr}';
    return 'Just now'.tr;
  }
}

// ─── Quick Chip Widget ────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppThemeData.primary4 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isActive ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey7),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: isActive ? FontFamily.semiBold : FontFamily.medium,
                color: isActive ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Like Button ──────────────────────────────────────────────────────────────
class _LikeButton extends StatelessWidget {
  final AdModel ad;
  final double size;

  const _LikeButton({required this.ad, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final uid = FireStoreUtils.getCurrentUid();
    final isLiked = (uid != null && (ad.likedUser?.contains(uid) ?? false)).obs;

    return Obx(
          () => GestureDetector(
        onTap: () async {
          if (uid == null || ad.id == null) return;
          final result = await FireStoreUtils.toggleLike(ad.id!, uid);
          if (result) {
            ad.likedUser ??= [];
            if (!ad.likedUser!.contains(uid)) ad.likedUser!.add(uid);
          } else {
            ad.likedUser?.remove(uid);
          }
          isLiked.value = result;
        },
        child: Icon(isLiked.value ? Icons.favorite : Icons.favorite_border, size: size, color: isLiked.value ? Colors.red : AppThemeData.primary4),
      ),
    );
  }
}

// ─── FILTER VIEW (Full Screen) ────────────────────────────────────────────────
class _FilterView extends StatelessWidget {
  final AdsListingController controller;

  const _FilterView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(
        context,
        themeChange,
        "Filter".tr,
        isBack: true,
        actions: [
          TextButton(
            onPressed: () {
              controller.resetFilter();
              Get.back();
            },
            child: TextCustom(title: "Reset".tr, fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
          ),
        ],
      ),
      body: Obx(
            () => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Category (Tireda 2-Level Picker) ──────────────────
                    _label("Category".tr, isDark),
                    spaceH(height: 8),
                    GestureDetector(
                      onTap: () => Get.to(() => _CategoryPickerView(controller: controller)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.dashboard_outlined, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            spaceW(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextCustom(
                                    title: controller.filterCategoryId.value.isEmpty
                                        ? "All Categories".tr
                                        : controller.filterCategoryName.value,
                                    fontSize: 14,
                                    fontFamily: FontFamily.medium,
                                    color: controller.filterCategoryId.value.isEmpty
                                        ? (isDark ? AppThemeData.grey5 : AppThemeData.grey6)
                                        : (isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                  ),
                                  if (controller.filterSubCategoryId.value.isNotEmpty) ...[
                                    spaceH(height: 2),
                                    TextCustom(
                                      title: controller.filterSubCategoryName.value,
                                      fontSize: 12,
                                      fontFamily: FontFamily.medium,
                                      color: AppThemeData.primary4,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          ],
                        ),
                      ),
                    ),
                    spaceH(height: 20),

                    // ── Budget (Price) ────────────────────────────────
                    _label("Budget (Price)".tr, isDark),
                    spaceH(height: 8),
                    Row(
                      children: [
                        Expanded(child: _priceField(controller.minPriceController, "Min".tr, isDark)),
                        spaceW(width: 12),
                        Expanded(child: _priceField(controller.maxPriceController, "Max".tr, isDark)),
                      ],
                    ),
                    spaceH(height: 20),

                    // ── Posted Since ──────────────────────────────────
                    _label("Posted Since".tr, isDark),
                    spaceH(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.filterPostedSince.value,
                          isExpanded: true,
                          dropdownColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
                          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          items: AdsListingController.postedSinceOptions
                              .map(
                                (opt) => DropdownMenuItem(
                              value: opt['key'],
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 18, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                  spaceW(width: 10),
                                  TextCustom(title: opt['label']!.tr, fontSize: 15, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                ],
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: (v) => controller.filterPostedSince.value = v ?? 'all',
                        ),
                      ),
                    ),
                    spaceH(height: 20),

                    // ── Seller & Listing ──────────────────────────────
                    _label("Seller & Listing".tr, isDark),
                    spaceH(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                      ),
                      child: Column(
                        children: [
                          // Verified seller toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_outlined, size: 20, color: AppThemeData.primary4),
                                spaceW(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextCustom(title: "Verified Seller".tr, fontSize: 14, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                      TextCustom(title: "Show only ID-verified sellers".tr, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: controller.filterVerifiedOnly.value,
                                  onChanged: (v) => controller.filterVerifiedOnly.value = v,
                                  activeColor: AppThemeData.primary4,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                          // Promoted ads toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.star_outline_rounded, size: 20, color: const Color(0xffFF9500)),
                                spaceW(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextCustom(title: "Promoted Ads Only".tr, fontSize: 14, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                      TextCustom(title: "Show only featured listings".tr, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: controller.filterFeaturedOnly.value,
                                  onChanged: (v) => controller.filterFeaturedOnly.value = v,
                                  activeColor: AppThemeData.primary4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Dynamic Custom Fields (v1.5 Multi-Select) ─────
                    Obx(() {
                      final fields = controller.filterableCustomFields;
                      if (fields.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          spaceH(height: 20),
                          _label("More Filters".tr, isDark),
                          spaceH(height: 8),
                          ...fields.map(
                                (f) => _CustomFieldFilter(
                              field: f,
                              controller: controller,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Apply Button ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: ElevatedButton(
                onPressed: () {
                  controller.applyFilter();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary4,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  "Apply Filter".tr,
                  style: const TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return TextCustom(title: text, fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10);
  }

  Widget _priceField(TextEditingController ctrl, String hint, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 15, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

// ─── TIREDA 2-LEVEL CATEGORY PICKER VIEWS ────────────────────────────────────
class _CategoryPickerView extends StatelessWidget {
  final AdsListingController controller;

  const _CategoryPickerView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, "Select Category".tr, isBack: true),
      body: Obx(
            () => ListView(
          children: [
            // All Categories option
            _CategoryTile(
              title: "All Categories".tr,
              subtitle: null,
              isSelected: controller.filterCategoryId.value.isEmpty,
              hasChildren: false,
              isDark: isDark,
              onTap: () {
                controller.filterCategoryId.value = '';
                controller.filterCategoryName.value = '';
                controller.filterSubCategoryId.value = '';
                controller.filterSubCategoryName.value = '';
                controller.filterSubCategories.clear();
                controller.categoryCustomFields.clear();
                controller.activeCustomFilters.clear();
                Get.back();
              },
            ),
            Divider(height: 1, thickness: 0.5, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),

            // Parent categories
            ...controller.allCategories.map((cat) {
              final isSelected = controller.filterCategoryId.value == cat.id;
              return Column(
                children: [
                  _CategoryTile(
                    title: cat.categoryNameFor(Get.locale?.languageCode),
                    subtitle: '${controller.countAdsForCategory(cat.id ?? '')} ads',
                    isSelected: isSelected,
                    hasChildren: true,
                    isDark: isDark,
                    onTap: () async {
                      controller.filterCategoryId.value = cat.id ?? '';
                      controller.filterCategoryName.value = cat.categoryNameFor(Get.locale?.languageCode);
                      // Clear subcategory and custom fields when parent changes
                      controller.filterSubCategoryId.value = '';
                      controller.filterSubCategoryName.value = '';
                      controller.categoryCustomFields.clear();
                      controller.activeCustomFilters.clear();
                      // Load subcategories then navigate to sub picker
                      await controller.loadSubCategories(cat.id ?? '');
                      Get.to(() => _SubCategoryPickerView(controller: controller));
                    },
                  ),
                  Divider(height: 1, thickness: 0.5, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SubCategoryPickerView extends StatelessWidget {
  final AdsListingController controller;

  const _SubCategoryPickerView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(
        context,
        themeChange,
        controller.filterCategoryName.value,
        isBack: true,
      ),
      body: Obx(
            () => controller.isLoadingSubCategories.value
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4))
            : ListView(
          children: [
            // All option — selects the parent category only. Tireda
            // Custom: rather than clearing custom fields, this now loads
            // them AGGREGATED across every subcategory of this parent
            // (via loadAggregatedCustomFieldsForParent), so a filter like
            // "Condition" is still available without drilling into one
            // exact subcategory (e.g. "All in Cars" still surfaces
            // Condition across every car brand).
            _CategoryTile(
              title: "All in ".tr + controller.filterCategoryName.value,
              subtitle: null,
              isSelected: controller.filterSubCategoryId.value.isEmpty,
              hasChildren: false,
              isDark: isDark,
              onTap: () async {
                controller.filterSubCategoryId.value = '';
                controller.filterSubCategoryName.value = '';
                await controller.loadAggregatedCustomFieldsForParent(controller.filterCategoryId.value);
                // Pop back to filter view
                Get.back();
                Get.back();
              },
            ),
            Divider(height: 1, thickness: 0.5, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),

            // Subcategories
            ...controller.filterSubCategories.map((sub) {
              final isSelected = controller.filterSubCategoryId.value == sub.id;
              return Column(
                children: [
                  _CategoryTile(
                    title: sub.categoryNameFor(Get.locale?.languageCode),
                    subtitle: '${controller.countAdsForCategory(sub.id ?? '')} ads',
                    isSelected: isSelected,
                    hasChildren: false,
                    isDark: isDark,
                    onTap: () async {
                      controller.filterSubCategoryId.value = sub.id ?? '';
                      controller.filterSubCategoryName.value = sub.categoryNameFor(Get.locale?.languageCode);
                      // Load custom fields for this subcategory
                      await controller.loadCategoryCustomFields(
                        subCategoryId: sub.id ?? '',
                        parentCategoryId: controller.filterCategoryId.value,
                      );
                      // Pop back to filter view
                      Get.back();
                      Get.back();
                    },
                  ),
                  Divider(height: 1, thickness: 0.5, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool hasChildren;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.hasChildren,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    title: title,
                    fontSize: 15,
                    fontFamily: isSelected ? FontFamily.semiBold : FontFamily.medium,
                    color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  ),
                  if (subtitle != null) ...[
                    spaceH(height: 2),
                    TextCustom(
                      title: subtitle!,
                      fontSize: 12,
                      color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected && !hasChildren)
              Icon(Icons.check, size: 20, color: AppThemeData.primary4)
            else if (hasChildren)
              Icon(Icons.chevron_right, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          ],
        ),
      ),
    );
  }
}

// ─── V1.5 CUSTOM FIELD FILTER (MULTI-SELECT) ─────────────────────────────────
class _CustomFieldFilter extends StatelessWidget {
  final CustomFieldModel field;
  final AdsListingController controller;
  final bool isDark;

  const _CustomFieldFilter({
    required this.field,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final options = field.options ?? const <String>[];
    if (options.isEmpty || (field.name ?? '').isEmpty) {
      return const SizedBox.shrink();
    }
    final fieldKey = field.name!;
    final label = field.nameFor(Get.locale?.languageCode);
    final displayLabel = label.isNotEmpty ? label : fieldKey;
    final isMulti = field.type == 'Checkboxes';

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            title: displayLabel,
            fontSize: 14,
            fontFamily: FontFamily.semiBold,
            color: isDark ? AppThemeData.grey2 : AppThemeData.grey9,
          ),
          spaceH(height: 8),
          Obx(() {
            final selected =
                controller.activeCustomFilters[fieldKey] ?? <String>{};
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSelected = selected.contains(opt);
                return FilterChip(
                  label: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: isSelected
                          ? FontFamily.semiBold
                          : FontFamily.regular,
                      color: isSelected
                          ? AppThemeData.primary4
                          : (isDark
                          ? AppThemeData.grey1
                          : AppThemeData.grey10),
                    ),
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor:
                  isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                  selectedColor: AppThemeData.primary4.withOpacity(0.12),
                  side: BorderSide(
                    color: isSelected
                        ? AppThemeData.primary4
                        : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (_) {
                    final current = controller.activeCustomFilters[fieldKey] ??
                        <String>{};
                    final next = <String>{...current};
                    if (isMulti) {
                      if (isSelected) {
                        next.remove(opt);
                      } else {
                        next.add(opt);
                      }
                    } else {
                      if (isSelected) {
                        next.clear();
                      } else {
                        next
                          ..clear()
                          ..add(opt);
                      }
                    }
                    if (next.isEmpty) {
                      controller.activeCustomFilters.remove(fieldKey);
                    } else {
                      controller.activeCustomFilters[fieldKey] = next;
                    }
                    // Refresh map so UI reactively updates the chips
                    controller.activeCustomFilters.refresh();
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}