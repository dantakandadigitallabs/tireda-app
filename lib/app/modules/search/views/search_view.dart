import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/app/modules/ads_listing/views/ads_listing_view.dart';
import 'package:eSellify/app/modules/sub_category/views/sub_category_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/native_ad_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/search_controller.dart';

class SearchView extends GetView<AdSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      body: SafeArea(
        child: Column(
          children: [
            const Center(child: AdBannerWidget()),
            // Search bar
            _buildSearchHeader(isDark),
            // Content
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return Center(child: CircularProgressIndicator(color: AppThemeData.primary4));
                }

                if (controller.query.value.isNotEmpty && controller.searchResults.isNotEmpty) {
                  return _buildSearchResults(isDark);
                }

                if (controller.query.value.isNotEmpty && controller.searchResults.isEmpty && !controller.isSearching.value) {
                  return _buildNoResults(isDark);
                }

                // Default: show recent searches + categories
                return _buildDefaultContent(isDark);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: SvgPicture.asset("assets/icons/ic_arrow_left.svg", height: 22, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn)),
          ),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              focusNode: controller.searchFocusNode,
              onChanged: controller.onSearchChanged,
              onSubmitted: controller.submitSearch,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 15, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              decoration: InputDecoration(
                hintText: 'Search ads, categories...'.tr,
                hintStyle: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                filled: true,
                fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset("assets/icons/ic_search.svg", height: 18, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn)),
                ),
                suffixIcon: Obx(() => controller.query.value.isNotEmpty
                    ? IconButton(
                        onPressed: controller.clearSearch,
                        icon: Icon(Icons.close, size: 18, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Default Content (Recent + Categories) ────────────────────

  Widget _buildDefaultContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          Obx(() {
            if (controller.recentSearches.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextCustom(title: 'Recent Searches'.tr, fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                    const Spacer(),
                    GestureDetector(
                      onTap: controller.clearAllRecentSearches,
                      child: TextCustom(title: 'Clear All'.tr, fontSize: 12, color: AppThemeData.primary4),
                    ),
                  ],
                ),
                spaceH(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.recentSearches.map((search) {
                    return GestureDetector(
                      onTap: () => controller.onRecentSearchTap(search),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            spaceW(width: 6),
                            TextCustom(title: search, fontSize: 13, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                            spaceW(width: 6),
                            GestureDetector(
                              onTap: () => controller.removeRecentSearch(search),
                              child: Icon(Icons.close, size: 14, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                spaceH(height: 24),
              ],
            );
          }),

          // Browse by category
          Obx(() {
            if (controller.categories.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(title: 'Browse Categories'.tr, fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                spaceH(height: 12),
                ...controller.categories.map((cat) {
                  return InkWell(
                    onTap: () => Get.to(() => const SubCategoryView(), arguments: {"category": cat}),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppThemeData.primary4.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: cat.image != null && cat.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(imageUrl: cat.image!, fit: BoxFit.cover, width: 36, height: 36,
                                      errorWidget: (_, __, ___) => Icon(Icons.category_outlined, size: 18, color: AppThemeData.primary4),
                                    ),
                                  )
                                : Icon(Icons.category_outlined, size: 18, color: AppThemeData.primary4),
                          ),
                          spaceW(width: 14),
                          Expanded(
                            child: TextCustom(title: cat.categoryName ?? '', fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          ),
                          SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 14, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey6 : AppThemeData.grey5, BlendMode.srcIn)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Search Results ───────────────────────────────────────────

  Widget _buildSearchResults(bool isDark) {
    final data = controller.searchResults;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: data.length + (data.length ~/ 5),
            separatorBuilder: (_, __) => spaceH(height: 10),
            itemBuilder: (_, index) {
              if (index % 6 == 5) return NativeAdWidget(key: ValueKey('native_search_$index'));
              final realIndex = index - (index ~/ 6);
              if (realIndex >= data.length) return const SizedBox.shrink();
              return _buildResultCard(data[realIndex], isDark);
            },
          ),
        ),
        Obx(() => controller.isLoadingMore.value
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4)),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildResultCard(AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () {
        controller.submitSearch(controller.query.value);
        AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ad}));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: NetworkImageWidget(
                imageUrl: ad.mainImage ?? '',
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                borderRadius: 10,
              ),
            ),
            spaceW(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    title: ad.title ?? '',
                    fontSize: 14,
                    fontFamily: FontFamily.medium,
                    color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                    maxLine: 1,
                  ),
                  spaceH(height: 2),
                  if (ad.categoryNamePath != null && ad.categoryNamePath!.isNotEmpty)
                    TextCustom(
                      title: ad.categoryNamePath!.join(' > '),
                      fontSize: 11,
                      color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                      maxLine: 1,
                    ),
                  spaceH(height: 4),
                  TextCustom(
                    title: ad.isJobAd ? ad.formattedSalary() : Constant.amountShow(amount: ad.price?.toString()),
                    fontSize: 14,
                    fontFamily: FontFamily.bold,
                    color: AppThemeData.primary4,
                  ),
                ],
              ),
            ),
            SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 14, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey6 : AppThemeData.grey5, BlendMode.srcIn)),
          ],
        ),
      ),
    );
  }

  // ─── No Results ───────────────────────────────────────────────

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/icons/ic_search.svg", height: 48, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey6 : AppThemeData.grey5, BlendMode.srcIn)),
          spaceH(height: 16),
          TextCustom(title: 'No results found'.tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
          spaceH(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextCustom(
              title: 'Try a different keyword or browse categories'.tr,
              fontSize: 13,
              color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
