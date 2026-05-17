import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/app/modules/ads_listing/views/ads_listing_view.dart';
import 'package:eSellify/app/modules/categories/views/categories_view.dart';
import 'package:eSellify/app/modules/my_address/views/my_address_view.dart';
import 'package:eSellify/app/modules/signup_screen/views/enter_location_view.dart';
import 'package:eSellify/app/modules/sub_category/views/sub_category_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:eSellify/widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            automaticallyImplyLeading: false,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                backgroundImage: (Constant.userModel?.profilePic != null && Constant.userModel!.profilePic!.startsWith('http'))
                    ? NetworkImage(Constant.userModel!.profilePic!)
                    : null,
                child: (Constant.userModel?.profilePic == null || !Constant.userModel!.profilePic!.startsWith('http'))
                    ? HugeIcon(icon: HugeIcons.strokeRoundedUser03, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)

                    : null,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Navigator.of(context).canPop() ? const SizedBox.shrink() : const SizedBox.shrink(),
                GestureDetector(
                  onTap: () async {
                    dynamic result;
                    if (FireStoreUtils.getCurrentUid() != null) {
                      result = await Get.to(() => MyAddressView());
                    } else {
                      result = await Get.to(EnterLocationView(isRedirectDashboard: false));
                    }
                    if (result == true) {
                      controller.getData();
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextCustom(title: "Location", fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset("assets/icons/ic_map_pin.svg"),
                          spaceW(width: 4),
                          Obx(
                                () => Expanded(
                              child: TextCustom(
                                title: Constant.currentLocation.value?.getFullAddress() ?? "Select Location".tr,
                                fontSize: 14,
                                fontFamily: FontFamily.regular,
                                maxLine: 1,
                                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                              ),
                            ),
                          ),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: isDark ? AppThemeData.grey5 : AppThemeData.grey7, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ).paddingOnly(right: 12, left: 12),
            actions: [
              GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.NOTIFICATIONS);
                },
                child: SvgPicture.asset(
                  "assets/icons/ic_bell.svg",
                  colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn),
                ).paddingOnly(right: 16),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              controller.getData();
            },
            child: controller.isSectionsLoading.value && controller.categoryList.isEmpty
                ? ShimmerWidgets.homeShimmer(isDark)
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(themeChange, controller),
                    spaceH(height: 16),

                    // Ad Banner
                    const Center(child: AdBannerWidget()),
                    spaceH(height: 8),

                    // Banner Carousel
                    if (controller.bannerList.isNotEmpty) ...[
                      _buildBannerCarousel(controller, isDark),
                      spaceH(height: 16),
                    ],

                    // Categories (Compact Grid View)
                    if (controller.categoryList.isNotEmpty) ...[
                      _buildSectionHeader("Categories", isDark: isDark),
                      spaceH(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: controller.categoryList.length,
                        itemBuilder: (context, index) {
                          CategoryModel category = controller.categoryList[index];
                          return _buildCategoryChip(category, themeChange);
                        },
                      ),
                      spaceH(height: 20),
                    ],

                    // Feature Sections
                    ...controller.featureSections.map((section) {
                      final ads = controller.sectionAds[section.id] ?? [];
                      if (ads.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            section.title ?? '',
                            isDark: isDark,
                            onViewAll: () => Get.to(() => const AdsListingView(), arguments: {"section": section}),
                          ),
                          if (section.description != null && section.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextCustom(title: section.description!, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            ),
                          spaceH(height: 8),
                          _buildAdSection(ads, section.styleIndex ?? 0, isDark, context),
                          spaceH(height: 20),
                        ],
                      );
                    }),

                    // ─── All Ads section ───
                    _buildAllAdsSection(controller, isDark, context),
                  ],
                ),
              ),
            ),
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
          spaceH(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => Get.to(() => const AdsListingView()),
              icon: HugeIcon(icon: HugeIcons.strokeRoundedGridView, size: 18, color: AppThemeData.primary4),
              label: TextCustom(
                title: 'Browse all ads'.tr,
                fontSize: 14,
                fontFamily: FontFamily.semiBold,
                color: AppThemeData.primary4,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: AppThemeData.primary4, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
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
            child: TextCustom(title: "View All", fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
          ),
      ],
    );
  }

  // ─── Ad Section (3 styles) ─────────────────────────────────
  Widget _buildAdSection(List<AdModel> ads, int styleIndex, bool isDark, BuildContext context) {
    switch (styleIndex) {
      case 0:
        return _buildHorizontalList(ads, isDark);
      case 1:
        return _buildVerticalList(ads, isDark);
      case 2:
        return _buildGridStyle(ads, isDark, context);
      case 3:
        return _buildCarouselStyle(ads, isDark, context);
      default:
        return _buildHorizontalList(ads, isDark);
    }
  }

  // ─── Style 0: Horizontal List (Near You style) ─────────────
  Widget _buildHorizontalList(List<AdModel> ads, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ads.length,
        itemBuilder: (_, index) {
          final ad = ads[index];
          return GestureDetector(
            onTap: () => AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ad})),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
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
                        child: _adImage(ad, isDark, width: 100, height: 120),
                      ),
                      if (ad.isFeatured == true) Positioned(top: 6, left: 6, child: _featuredBadge()),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextCustom(title: ad.title ?? '', fontSize: 14, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                          if (ad.customFields != null && ad.customFields!.isNotEmpty) ...[
                            spaceH(height: 2),
                            TextCustom(
                              title: ad.customFields!.where((f) => (f['value']?.toString().trim() ?? '').isNotEmpty).take(2).map((f) => f['value'].toString()).join(' | '),
                              fontSize: 11,
                              color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                              maxLine: 1,
                            ),
                          ],
                          spaceH(height: 4),
                          TextCustom(title: _formatPrice(ad), fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          spaceH(height: 4),
                          Row(
                            children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
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
        },
      ),
    );
  }

  // ─── Style 1: Vertical List ────────────────────────────────
  Widget _buildVerticalList(List<AdModel> ads, bool isDark) {
    return Column(
      children: ads.map((ad) {
        return GestureDetector(
          onTap: () => AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ad})),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                      child: _adImage(ad, isDark, width: 120, height: 120),
                    ),
                    if (ad.isFeatured == true) Positioned(top: 6, left: 6, child: _featuredBadge()),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(title: ad.title ?? '', fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
                        spaceH(height: 4),
                        TextCustom(title: _formatPrice(ad), fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                        spaceH(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
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
      // Fixed: Extended dimension buffer limit to 235 so layout frames never pinch text boundaries
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 235
      ),
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ads[index]})),
        child: _buildAdCard(ads[index], isDark),
      ),
    );
  }

  // ─── Style 3: Carousel ─────────────────────────────────────
  Widget _buildCarouselStyle(List<AdModel> ads, bool isDark, BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        padEnds: false,
        controller: PageController(viewportFraction: 0.88),
        itemCount: ads.length,
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ads[index]})),
          child: Padding(padding: const EdgeInsets.only(right: 10), child: _buildCarouselCard(ads[index], isDark)),
        ),
      ),
    );
  }

  // ─── Ad Card (used in Grid + List) ─────────────────────────
  Widget _buildAdCard(AdModel ad, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded forces image area frame to fill upper layout gracefully
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeData.primary4, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _adImage(ad, isDark, height: double.infinity, width: double.infinity),
                  ),
                ),
                if (ad.isFeatured == true) Positioned(top: 6, left: 6, child: _featuredBadge(fontSize: 8, iconSize: 10)),
              ],
            ),
          ),
          // Details Area sits natively with proper padding values underneath
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. PRICE
                TextCustom(
                  title: _formatPrice(ad),
                  fontSize: 14,
                  fontFamily: FontFamily.bold,
                  color: AppThemeData.primary4,
                  maxLine: 1,
                ),
                spaceH(height: 2),

                // 2. TITLE
                TextCustom(
                  title: ad.title ?? '',
                  fontSize: 12,
                  fontFamily: FontFamily.medium,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                  maxLine: 1,
                ),
                spaceH(height: 2),

                // 3. LOCATION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    spaceW(width: 4),
                    Expanded(
                      child: TextCustom(
                        title: ad.address.toString(),
                        fontSize: 11,
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

  // ─── Reusable: Featured Badge ───────────────────────────────
  Widget _featuredBadge({double fontSize = 9, double iconSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: iconSize, color: Colors.white),
          const SizedBox(width: 2),
          Text("Featured", style: TextStyle(fontSize: fontSize, fontFamily: FontFamily.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // ─── Reusable: Ad Image ────────────────────────────────────
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
        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage03, size: 32, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
      ),
    )
        : Container(
      height: height,
      width: width,
      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage03, size: 32, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
    );
  }

  // ─── Carousel Card (large, overlay text) ───────────────────
  Widget _buildCarouselCard(AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () => AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ad})),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: ad.mainImage!,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
            )
                : Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
              ),
            ),
            if (ad.isFeatured == true) Positioned(top: 10, left: 10, child: _featuredBadge(fontSize: 10, iconSize: 12)),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(title: _formatPrice(ad), fontSize: 16, fontFamily: FontFamily.bold, color: Colors.white),
                  const SizedBox(height: 2),
                  TextCustom(title: ad.title ?? '', fontSize: 13, fontFamily: FontFamily.regular, color: Colors.white70, maxLine: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Chip ─────────────────────────────────────────
  Widget _buildCategoryChip(CategoryModel category, DarkThemeProvider themeChange) {
    final isDark = themeChange.isDarkTheme();
    return GestureDetector(
      onTap: () => Get.to(() => const SubCategoryView(), arguments: {"category": category}),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 36,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: NetworkImageWidget(imageUrl: category.image.toString(), fit: BoxFit.contain),
            ),
            spaceH(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TextCustom(
                title: category.categoryName.toString(),
                fontSize: 10,
                fontFamily: FontFamily.medium,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                textAlign: TextAlign.center,
                maxLine: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────
  String _formatPrice(AdModel ad) {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final currency = ad.currency;
    final symbol = currency?.symbol ?? '';
    final decimals = currency?.decimalDigits ?? 0;
    final price = ad.price!.toStringAsFixed(decimals);
    return currency?.symbolAtRight == true ? "$price $symbol".trim() : "$symbol$price".trim();
  }

  // ─── Banner Carousel ────────────────────────────────────────
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
                      child: Center(child: Icon(Icons.image_outlined, size: 40, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Icon(Icons.image_outlined, size: 40, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
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
  Widget _buildSearchBar(DarkThemeProvider themeChange, HomeController controller) {
    final isDark = themeChange.isDarkTheme();
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.SEARCH),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 1),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 20,
              color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
            ),
            spaceW(width: 12),
            TextCustom(title: "Search ads, categories...".tr, fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
          ],
        ),
      ),
    );
  }
}