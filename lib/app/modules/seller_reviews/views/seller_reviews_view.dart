import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/seller_reviews_controller.dart';

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
          appBar: UiInterface.customAppBar(context, themeChange, isBack: true, 'Reviews'.tr),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? Constant.loader(context: context)
                    : Column(
                        children: [
                          // Rating summary header
                          _buildRatingSummary(controller, isDark),
                    // Reviews list
                    Expanded(
                      child: controller.reviews.isEmpty
                          ? _buildEmpty(isDark)
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: controller.reviews.length,
                              separatorBuilder: (_, _) => spaceH(height: 12),
                              itemBuilder: (_, index) => _buildReviewCard(controller.reviews[index], isDark),
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

  Widget _buildRatingSummary(SellerReviewsController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              TextCustom(
                title: controller.averageRating.value > 0 ? controller.averageRating.value.toStringAsFixed(1) : '—',
                fontSize: 40,
                fontFamily: FontFamily.bold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
              ),
              spaceH(height: 4),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < controller.averageRating.value.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 20,
                    color: const Color(0xffFF9500),
                  );
                }),
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
          // Rating bars
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
                    valueColor: AlwaysStoppedAnimation(const Color(0xffFF9500)),
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

  Widget _buildReviewCard(dynamic review, bool isDark) {
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
                        ...List.generate(5, (i) => Icon(i < (review.rating ?? 0).round() ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: const Color(0xffFF9500))),
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
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
                borderRadius: BorderRadius.circular(8),
              ),
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

  Widget _buildEmpty(bool isDark) {
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

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
