// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/native_ad_widget.dart';
import 'package:eSellify/widgets/shimmer_widgets.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/favourites_controller.dart';

class FavouritesView extends GetView<FavouritesController> {
  const FavouritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<FavouritesController>(
      init: FavouritesController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Favourites", isBack: true),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? ShimmerWidgets.adListShimmer(isDark)
                    : controller.favouriteAds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, size: 64, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                      spaceH(height: 16),
                      TextCustom(title: "No Favourites Yet", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                      spaceH(height: 8),
                      TextCustom(title: "Ads you like will appear here", fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.loadFavourites,
                  color: AppThemeData.primary4,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.favouriteAds.length + (controller.favouriteAds.length ~/ 5),
                    separatorBuilder: (_, __) => spaceH(height: 10),
                    itemBuilder: (_, index) {
                      if (index % 6 == 5) return NativeAdWidget(key: ValueKey('native_fav_$index'));
                      final realIndex = index - (index ~/ 6);
                      if (realIndex >= controller.favouriteAds.length) return const SizedBox.shrink();
                      final ad = controller.favouriteAds[realIndex];
                      return _FavAdCard(ad: ad, controller: controller, isDark: isDark);
                    },
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

class _FavAdCard extends StatelessWidget {
  final AdModel ad;
  final FavouritesController controller;
  final bool isDark;

  const _FavAdCard({required this.ad, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AdService.showInterstitial(onDismissed: () => Get.to(() => const AdListingDetailView(), arguments: {"ad": ad}));
        controller.loadFavourites(); // refresh on return
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                  ? CachedNetworkImage(imageUrl: ad.mainImage!, width: 120, height: 120, fit: BoxFit.cover, placeholder: (_, __) => _placeholder())
                  : _placeholder(),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextCustom(title: controller.formatPrice(ad), fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                        ),
                        GestureDetector(
                          onTap: () => controller.toggleLike(ad),
                          child: Icon(Icons.favorite, size: 22, color: Colors.red),
                        ),
                      ],
                    ),
                    spaceH(height: 4),
                    TextCustom(title: ad.title ?? '', fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
                    spaceH(height: 6),
                    if (ad.address != null && ad.address!.isNotEmpty)
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
  }

  Widget _placeholder() => Container(
    width: 120,
    height: 120,
    color: isDark ? AppThemeData.grey9 : AppThemeData.grey3,
    child: Icon(Icons.image_outlined, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5, size: 32),
  );

}
