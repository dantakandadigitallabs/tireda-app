// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/models/ad_model.dart';
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
              // Search + View Toggle
              Container(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: controller.searchController,
                          style: TextStyle(fontSize: 15, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          decoration: InputDecoration(
                            hintText: "Search any advertisement...",
                            hintStyle: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                            prefixIcon: Icon(Icons.search, size: 22, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
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
                    spaceW(width: 10),
                    // List toggle
                    _viewToggle(controller, 0, Icons.view_list_rounded, isDark),
                    spaceW(width: 6),
                    // Grid toggle
                    _viewToggle(controller, 1, Icons.grid_view_rounded, isDark),
                  ],
                ),
              ),

              // Ads List
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
                      TextCustom(title: "No Ads Found", fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
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

              // Bottom Bar: Filter + Sort
              Container(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showFilterSheet(context, controller, isDark),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune_rounded, size: 20, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                            spaceW(width: 8),
                            TextCustom(title: "Filter", fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey2 : AppThemeData.grey9),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showSortSheet(context, controller, isDark),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_vert, size: 22, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                            spaceW(width: 8),
                            TextCustom(title: "Sort by", fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey2 : AppThemeData.grey9),
                          ],
                        ),
                      ),
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
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
          color: isActive ? AppThemeData.primary4.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(icon, size: 22, color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: _adImage(ad, isDark, width: 130, height: 130),
              ),
              if (ad.isFeatured == true)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.star_rounded, size: 12, color: Colors.white), SizedBox(width: 2), Text("Featured", style: TextStyle(fontSize: 9, fontFamily: FontFamily.bold, color: Colors.white))],
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
                  TextCustom(title: ad.title ?? '', fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
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

          // Image
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
                          Text("Featured", style: TextStyle(fontSize: 8, fontFamily: FontFamily.bold, color: Colors.white)),
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

                // Title
                TextCustom(
                  title: ad.title ?? '',
                  fontSize: 12,
                  fontFamily: FontFamily.medium,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                  maxLine: 1,
                ),

                spaceH(height: 4),

                // Condition + Verified ID
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
                        title: "Verified ID",
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
                  title: opt['label']!,
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

  // ─── Filter Screen ─────────────────────────────────────────
  void _showFilterSheet(BuildContext context, AdsListingController controller, bool isDark) {
    Get.to(() => _FilterView(controller: controller));
  }

  // ─── Helpers ───────────────────────────────────────────────
  String _formatPrice(AdModel ad) {
    return PriceFormatter.format(ad);
  }

  String _timeAgo(AdModel ad) {
    if (ad.createdAt == null) return '';
    final diff = DateTime.now().difference(ad.createdAt!.toDate());
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() > 1 ? 's' : ''} ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}

// ─── FILTER VIEW (full screen) ───────────────────────────────────────────────
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
        "Filter",
        isBack: true,
        actions: [
          TextButton(
            onPressed: () {
              controller.resetFilter();
              Get.back();
            },
            child: TextCustom(title: "Reset", fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
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
                    // Category
                    _label("Category", isDark),
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
                          value: controller.filterCategoryId.value.isEmpty ? null : controller.filterCategoryId.value,
                          hint: Row(
                            children: [
                              Icon(Icons.dashboard_outlined, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                              spaceW(width: 10),
                              TextCustom(title: "All", fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            ],
                          ),
                          isExpanded: true,
                          dropdownColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
                          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: TextCustom(title: "All", fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                            ),
                            ...controller.allCategories.map(
                                  (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: TextCustom(title: cat.categoryName ?? '-', fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            controller.filterCategoryId.value = v ?? '';
                            final cat = controller.allCategories.firstWhereOrNull((c) => c.id == v);
                            controller.filterCategoryName.value = cat?.categoryName ?? '';
                          },
                        ),
                      ),
                    ),
                    spaceH(height: 20),

                    // Budget (Price)
                    _label("Budget (Price)", isDark),
                    spaceH(height: 8),
                    Row(
                      children: [
                        Expanded(child: _priceField(controller.minPriceController, "Min", isDark)),
                        spaceW(width: 12),
                        Expanded(child: _priceField(controller.maxPriceController, "Max", isDark)),
                      ],
                    ),
                    spaceH(height: 20),

                    // Posted Since
                    _label("Posted Since", isDark),
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
                                  TextCustom(title: opt['label']!, fontSize: 15, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                ],
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: (v) => controller.filterPostedSince.value = v ?? 'all',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Apply Button
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
                child: const Text(
                  "Apply Filter",
                  style: TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
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