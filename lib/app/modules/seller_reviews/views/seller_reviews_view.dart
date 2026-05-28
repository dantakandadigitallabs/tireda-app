import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/review_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:eSellify/widgets/verified_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/seller_reviews_controller.dart';
import 'package:eSellify/utils/navigation_helper.dart';

class SellerReviewsView extends GetView<SellerReviewsController> {
  const SellerReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<SellerReviewsController>(
      init: SellerReviewsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(
            context,
            themeChange,
            isBack: true,
            controller.sellerName.value.isNotEmpty
                ? '${controller.sellerName.value}\'s shelf'
                : 'Seller Profile'.tr,
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value && controller.isAdsLoading.value
                    ? Center(child: Constant.loader(context: context))
                    : Column(
                  children: [
                    // ── Seller Profile Header ──
                    _buildProfileHeader(controller, isDark),

                    // ── Tab Bar ──
                    _buildTabBar(controller, isDark),

                    // ── Tab Content ──
                    Expanded(
                      child: Obx(() => controller.selectedTab.value == 0
                          ? _buildListingsTab(controller, isDark)
                          : _buildReviewsTab(controller, isDark)),
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

  // ─── Profile Header ────────────────────────────────────────
  Widget _buildProfileHeader(SellerReviewsController controller, bool isDark) {
    final user = controller.sellerModel.value;
    final isVerified = user?.isVerified == true;

    return Container(
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          // Avatar + verified badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              NetworkImageWidget(
                imageUrl: user?.profilePic ?? '',
                height: 64,
                width: 64,
                borderRadius: 200,
                fit: BoxFit.cover,
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const VerifiedBadge(size: 18),
                ),
            ],
          ),
          spaceW(width: 14),
          // Name + verified text + joined date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.sellerName.value,
                  style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ),
                spaceH(height: 4),
                Row(
                  children: [
                    if (isVerified) ...[
                      Text(
                        'Verified',
                        style: TextStyle(fontSize: 12, fontFamily: FontFamily.medium, color: AppThemeData.success300),
                      ),
                      Text(' • ', style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                    ],
                    Text(
                      controller.memberSince,
                      style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ),
                  ],
                ),
                spaceH(height: 4),
                // Rating row
                Obx(() {
                  final rating = controller.averageRating.value;
                  final count = controller.reviewCount.value;
                  if (count == 0) return const SizedBox.shrink();
                  return Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 14,
                        color: const Color(0xffFF9500),
                      )),
                      spaceW(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)} ($count)',
                        style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          // Listings count badge
          Obx(() => Column(
            children: [
              Text(
                '${controller.sellerAds.length}',
                style: TextStyle(fontSize: 20, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
              ),
              Text(
                'Listings',
                style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────
  Widget _buildTabBar(SellerReviewsController controller, bool isDark) {
    return Container(
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Obx(() => Row(
        children: [
          _TabButton(
            label: 'Listings',
            isSelected: controller.selectedTab.value == 0,
            isDark: isDark,
            onTap: () => controller.selectedTab.value = 0,
          ),
          spaceW(width: 10),
          _TabButton(
            label: 'Reviews',
            isSelected: controller.selectedTab.value == 1,
            isDark: isDark,
            onTap: () => controller.selectedTab.value = 1,
          ),
        ],
      )),
    );
  }

  // ─── Listings Tab ──────────────────────────────────────────
  Widget _buildListingsTab(SellerReviewsController controller, bool isDark) {
    if (controller.isAdsLoading.value) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4));
    }

    if (controller.sellerAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 56, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
            spaceH(height: 16),
            TextCustom(title: 'No active listings'.tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 235,
      ),
      itemCount: controller.sellerAds.length,
      itemBuilder: (_, i) => _AdCard(ad: controller.sellerAds[i], controller: controller, isDark: isDark),
    );
  }

  // ─── Reviews Tab ───────────────────────────────────────────
  Widget _buildReviewsTab(SellerReviewsController controller, bool isDark) {
    if (controller.isLoading.value) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeData.primary4));
    }

    return Column(
      children: [
        // Rating summary
        _buildRatingSummary(controller, isDark),
        // Reviews list
        Expanded(
          child: controller.reviews.isEmpty
              ? _buildEmptyReviews(isDark)
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reviews.length,
            separatorBuilder: (_, _) => spaceH(height: 12),
            itemBuilder: (_, index) => _buildReviewCard(controller.reviews[index], isDark),
          ),
        ),
      ],
    );
  }

  // ─── Rating Summary ────────────────────────────────────────
  Widget _buildRatingSummary(SellerReviewsController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      child: Row(
        children: [
          Column(
            children: [
              TextCustom(
                title: controller.averageRating.value > 0 ? controller.averageRating.value.toStringAsFixed(1) : '—',
                fontSize: 40,
                fontFamily: FontFamily.bold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
              ),
              spaceH(height: 4),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < controller.averageRating.value.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                  color: const Color(0xffFF9500),
                )),
              ),
              spaceH(height: 4),
              TextCustom(
                title: '${controller.reviewCount.value} ${controller.reviewCount.value == 1 ? 'review' : 'reviews'}',
                fontSize: 13,
                color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
              ),
            ],
          ),
          spaceW(width: 24),
          Expanded(child: _buildRatingBars(controller, isDark)),
        ],
      ),
    );
  }

  Widget _buildRatingBars(SellerReviewsController controller, bool isDark) {
    final total = controller.reviews.length;
    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = controller.reviews.where((r) => (r.rating ?? 0).round() == star).length;
        final ratio = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              TextCustom(title: '$star', fontSize: 12, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
              spaceW(width: 4),
              Icon(Icons.star_rounded, size: 12, color: const Color(0xffFF9500)),
              spaceW(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
                    valueColor: const AlwaysStoppedAnimation(Color(0xffFF9500)),
                  ),
                ),
              ),
              spaceW(width: 8),
              SizedBox(width: 24, child: TextCustom(title: '$count', fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
            ],
          ),
        );
      }),
    );
  }

  // ── FIX A: dynamic → ReviewModel ──────────────────────────
  Widget _buildReviewCard(ReviewModel review, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetworkImageWidget(imageUrl: review.buyerProfile ?? '', height: 40, width: 40, borderRadius: 200, fit: BoxFit.cover),
              spaceW(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(title: review.buyerName ?? 'Buyer', fontSize: 14, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    spaceH(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < (review.rating ?? 0).round() ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14,
                          color: const Color(0xffFF9500),
                        )),
                        spaceW(width: 8),
                        TextCustom(title: _timeAgo(review.createdAt), fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            spaceH(height: 12),
            TextCustom(title: review.comment!, fontSize: 14, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8, maxLine: 10),
          ],
          if (review.adTitle != null) ...[
            spaceH(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey1, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined, size: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  spaceW(width: 6),
                  Flexible(child: TextCustom(title: review.adTitle!, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyReviews(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 56, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
          spaceH(height: 16),
          TextCustom(title: 'No reviews yet'.tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          spaceH(height: 6),
          TextCustom(title: 'Reviews will appear here after sales'.tr, fontSize: 13, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        ],
      ),
    );
  }

  // ── FIX C: Enhanced _timeAgo with week/month granularity ──
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final date = ts.toDate();
    final diff = now.difference(date);

    if (date.isAfter(now)) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inHours >= 24 && diff.inHours < 48) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';

    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey9 : AppThemeData.grey2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: FontFamily.semiBold,
            color: isSelected ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey6),
          ),
        ),
      ),
    );
  }
}

// ─── Ad Card for Listings Grid ────────────────────────────────────────────────
class _AdCard extends StatelessWidget {
  final AdModel ad;
  final SellerReviewsController controller;
  final bool isDark;

  const _AdCard({required this.ad, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => goToAdDetail(ad),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
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
                    child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: ad.mainImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                      errorWidget: (_, _, _) => Container(
                        color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                        child: Icon(Icons.image_outlined, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                      ),
                    )
                        : Container(
                      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                      child: Icon(Icons.image_outlined, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                    ),
                  ),
                  if (ad.isFeatured == true)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
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
                  TextCustom(
                    title: controller.formatPrice(ad),
                    fontSize: 14,
                    fontFamily: FontFamily.bold,
                    color: AppThemeData.primary4,
                    maxLine: 1,
                  ),
                  spaceH(height: 2),
                  TextCustom(
                    title: ad.title ?? '',
                    fontSize: 12,
                    fontFamily: FontFamily.medium,
                    color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                    maxLine: 1,
                  ),
                  spaceH(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      spaceW(width: 2),
                      Expanded(
                        child: TextCustom(
                          title: ad.address ?? '',
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
      ),
    );
  }
}