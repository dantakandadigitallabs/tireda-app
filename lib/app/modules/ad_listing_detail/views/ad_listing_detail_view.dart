// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/modules/seller_reviews/views/seller_reviews_view.dart';
import 'package:eSellify/app/models/report_reason_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/price_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/safety_tips_bottom_sheet.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/ad_listing_detail_controller.dart';

class AdListingDetailView extends GetView<AdListingDetailController> {
  const AdListingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<AdListingDetailController>(
      init: AdListingDetailController(),
      builder: (controller) {
        final ad = controller.ad;
        final images = _getImages(ad);
        final hasLocation = ad.location?.latitude != null && ad.location?.longitude != null;
        final hasCustomFields = (ad.customFields?.isNotEmpty ?? false) && ad.customFields!.any((f) => (f['value']?.toString().trim() ?? '').isNotEmpty);

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            elevation: 0,
            leadingWidth: 120,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_back, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, size: 22),
                  const SizedBox(width: 6),
                  TextCustom(title: "Homepage", fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ],
              ),
            ),
            actions: [
              Obx(
                    () => GestureDetector(
                  onTap: controller.toggleLike,
                  child: Icon(
                    controller.isLiked.value ? Icons.favorite : Icons.favorite_border,
                    color: controller.isLiked.value ? Colors.red : (isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: controller.shareAd,
                child: Icon(Icons.share_outlined, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, size: 22),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image Gallery (Edge-to-Edge) ──
                      _ImageGallery(images: images, isDark: isDark),

                      // ── Hero Section (Title -> Location -> Price) ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Featured Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextCustom(title: ad.title ?? '', fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                ),
                                if (ad.isFeatured == true)
                                  Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text("Promoted", style: TextStyle(fontSize: 10, fontFamily: FontFamily.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            spaceH(height: 6),

                            // Location (Clickable, but no visual hint)
                            if (ad.address != null && ad.address!.isNotEmpty)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  String query;
                                  if (hasLocation) {
                                    query = '${ad.location!.latitude},${ad.location!.longitude}';
                                  } else {
                                    query = Uri.encodeComponent(ad.address!);
                                  }
                                  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                    spaceW(width: 4),
                                    Expanded(
                                      child: TextCustom(title: ad.address!, fontSize: 12, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, maxLine: 2),
                                    ),
                                  ],
                                ),
                              ),
                            spaceH(height: 8),

                            // Price
                            TextCustom(title: PriceFormatter.format(ad), fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                          ],
                        ),
                      ),

                      // ── Detailed Sections Below ──
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Custom Fields (Limited to 6)
                            if (hasCustomFields) ...[
                              Divider(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                              spaceH(height: 6),
                              _buildCustomFields(ad.customFields!, isDark),
                            ],

                            // Description
                            if (ad.description != null && ad.description!.isNotEmpty) ...[
                              spaceH(height: 6),
                              Divider(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                              spaceH(height: 12),
                              Text(
                                "Description",
                                style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                              ),
                              spaceH(height: 6),
                              TextCustom(title: ad.description!, fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, maxLine: 50),
                            ],

                            // Seller Info Trust Card
                            spaceH(height: 8),
                            Divider(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                            spaceH(height: 12),
                            _buildSellerInfo(ad, isDark),

                            // Action Row (Mark Unavailable / Report Abuse)
                            spaceH(height: 16),
                            _buildActionRow(ad, isDark),
                            spaceH(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 3-Button Sticky Bottom Bar ─────────────────────────────
              Container(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                child: Row(
                  children: [
                    // 1. Call Button (Only if phone number exists)
                    if (ad.phoneNumber != null && ad.phoneNumber!.isNotEmpty) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final phone = '${ad.countryCode ?? ''}${ad.phoneNumber}';
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppThemeData.primary4, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_outlined, size: 16, color: AppThemeData.primary4),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text("Call", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      spaceW(width: 8),
                    ],

                    // 2. Chat Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => SafetyTipsBottomSheet.show(
                          context,
                          continueLabel: "Continue to chat",
                          onContinue: controller.openChat,
                        ),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppThemeData.primary4, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppThemeData.primary4),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text("Chat", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    spaceW(width: 8),

                    // 3. Offer Button (Primary Solid)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => SafetyTipsBottomSheet.show(
                          context,
                          continueLabel: "Continue to offer",
                          onContinue: () => _showMakeOfferSheet(context, controller, isDark),
                        ),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppThemeData.primary4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_offer_outlined, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text("Offer", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Colors.white), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
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

  // ─── Make an Offer Bottom Sheet ────────────────────────────

  void _showMakeOfferSheet(BuildContext context, AdListingDetailController controller, bool isDark) {
    final offerController = TextEditingController();
    final ad = controller.ad;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                spaceH(height: 20),
                // Ad info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ad.mainImage != null && ad.mainImage!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: ad.mainImage!, width: 50, height: 50, fit: BoxFit.cover)
                          : Container(
                        width: 50,
                        height: 50,
                        color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                        child: const Icon(Icons.image, color: AppThemeData.grey5),
                      ),
                    ),
                    spaceW(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(title: ad.title ?? '', fontSize: 14, fontFamily: FontFamily.medium, maxLine: 1),
                          spaceH(height: 2),
                          TextCustom(title: "Listed: ${PriceFormatter.format(ad)}", fontSize: 13, color: AppThemeData.grey5),
                        ],
                      ),
                    ),
                  ],
                ),
                spaceH(height: 20),
                TextCustom(title: "Make an Offer", fontSize: 18, fontFamily: FontFamily.bold),
                spaceH(height: 4),
                TextCustom(title: "Enter your offer price below", fontSize: 13, color: AppThemeData.grey5),
                spaceH(height: 16),
                // Price input
                TextField(
                  controller: offerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(fontSize: 22, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  decoration: InputDecoration(
                    prefixText: ad.currency?.symbol ?? '\$ ',
                    prefixStyle: TextStyle(fontSize: 22, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    hintText: "0.00",
                    hintStyle: TextStyle(fontSize: 22, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                    filled: true,
                    fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                spaceH(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(offerController.text.trim());
                      if (amount == null || amount <= 0) {
                        return;
                      }
                      Navigator.pop(ctx);
                      controller.sendOffer(amount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Send Offer",
                      style: TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                ),
                spaceH(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  List<String> _getImages(AdModel ad) => [if (ad.mainImage != null && ad.mainImage!.isNotEmpty) ad.mainImage!, ...?ad.otherImages?.where((u) => u.isNotEmpty)];

  Widget _buildCustomFields(List<Map<String, dynamic>> fields, bool isDark) {
    // Limited to maximum 6 items
    final items = fields.where((f) => (f['value']?.toString().trim() ?? '').isNotEmpty).take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _fieldCell(items[i], isDark)),
              if (i + 1 < items.length) ...[spaceW(width: 16), Expanded(child: _fieldCell(items[i + 1], isDark))] else const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _fieldCell(Map<String, dynamic> item, bool isDark) {
    final name = item['name']?.toString() ?? '';
    final iconUrl = item['icon']?.toString() ?? '';
    final value = item['value']?.toString() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
          child: iconUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: iconUrl,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => Icon(_fallbackIcon(name), size: 16, color: AppThemeData.grey5),
          )
              : Icon(_fallbackIcon(name), size: 16, color: AppThemeData.grey5),
        ),
        spaceW(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextCustom(title: name, fontSize: 11, color: AppThemeData.grey5),
              spaceH(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 13, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _fallbackIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('brand')) return Icons.label_outline;
    if (n.contains('model')) return Icons.device_hub_outlined;
    if (n.contains('color')) return Icons.palette_outlined;
    if (n.contains('condition')) return Icons.star_outline;
    if (n.contains('year')) return Icons.calendar_today_outlined;
    if (n.contains('size')) return Icons.straighten_outlined;
    return Icons.info_outline;
  }

  Widget _buildSellerInfo(AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (ad.sellerId != null) {
          Get.to(() => const SellerReviewsView(), arguments: {'sellerId': ad.sellerId, 'sellerName': ad.sellerName ?? 'Seller'});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
              backgroundImage: (ad.sellerProfile != null && ad.sellerProfile!.isNotEmpty) ? CachedNetworkImageProvider(ad.sellerProfile!) : null,
              child: (ad.sellerProfile == null || ad.sellerProfile!.isEmpty) ? Icon(Icons.person, color: AppThemeData.grey5) : null,
            ),
            spaceW(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ad.sellerName ?? 'Seller',
                          style: TextStyle(fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ad.sellerId != null)
                        Obx(
                              () => Get.find<AdListingDetailController>().isSellerVerified.value == true
                              ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset("assets/icons/ic_crown.svg", height: 12, colorFilter: ColorFilter.mode(AppThemeData.primaryWhite, BlendMode.srcIn)),
                                spaceW(width: 4),
                                TextCustom(title: "Verified", fontSize: 10, color: AppThemeData.primaryWhite),
                              ],
                            ),
                          )
                              : const SizedBox(),
                        ),
                    ],
                  ),
                  spaceH(height: 4),
                  Obx(() {
                    final controller = Get.find<AdListingDetailController>();
                    final rating = controller.sellerRating.value;
                    final count = controller.sellerReviewCount.value;
                    return Row(
                      children: [
                        if (count > 0) ...[
                          Icon(Icons.star_rounded, size: 14, color: const Color(0xffFF9500)),
                          spaceW(width: 4),
                          TextCustom(title: rating.toStringAsFixed(1), fontSize: 12, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey2 : AppThemeData.grey9),
                          spaceW(width: 4),
                          TextCustom(title: '($count)', fontSize: 11, color: AppThemeData.primary4),
                        ] else
                          TextCustom(title: 'No reviews', fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                        spaceW(width: 6),
                        TextCustom(title: '·', fontSize: 12, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                        spaceW(width: 6),
                        TextCustom(title: "${controller.viewCount.value} views", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                      ],
                    );
                  }),
                ],
              ),
            ),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(AdModel ad, bool isDark) {
    return Obx(() {
      final controller = Get.find<AdListingDetailController>();
      final report = controller.existingReport.value;

      if (controller.hasReported.value && report != null) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppThemeData.danger300.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: AppThemeData.danger300),
                  spaceW(width: 8),
                  Expanded(
                    child: TextCustom(title: "You flagged this ad", fontSize: 14, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300),
                  ),
                  _reportStatusBadge(report.status),
                ],
              ),
              spaceH(height: 8),
              Row(
                children: [
                  TextCustom(title: "Reason: ", fontSize: 12, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                  Expanded(
                    child: TextCustom(title: report.reasonTitle ?? '', fontSize: 12, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey2 : AppThemeData.grey8),
                  ),
                ],
              ),
              if (report.description != null && report.description!.isNotEmpty) ...[
                spaceH(height: 4),
                TextCustom(title: report.description!, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 2),
              ],
            ],
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _markAsUnavailable(Get.context!, ad, isDark),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF2196F3), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Mark unavailable", style: TextStyle(fontSize: 14, fontFamily: FontFamily.semiBold, color: Color(0xFF2196F3))),
            ),
          ),
          spaceW(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showReportDialog(Get.context!, ad, isDark),
              icon: Icon(Icons.flag_outlined, size: 18, color: AppThemeData.danger300),
              label: Text("Report abuse", style: TextStyle(fontSize: 14, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppThemeData.danger300, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _markAsUnavailable(BuildContext context, AdModel ad, bool isDark) async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      ShowToastDialog.showError("Please login to perform this action");
      return;
    }

    final alreadyReported = await FireStoreUtils.hasUserReportedAd(ad.id!, uid);
    if (alreadyReported) {
      ShowToastDialog.showWarning("You have already reported this ad");
      return;
    }

    Get.dialog(
        Dialog(
          backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 48, color: Color(0xFF2196F3)),
                spaceH(height: 16),
                Text(
                    "Mark as Unavailable?",
                    style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack)
                ),
                spaceH(height: 8),
                Text(
                    "Did the seller mention this item is already sold? Let us know so we can update the community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6)
                ),
                spaceH(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text("Cancel", style: TextStyle(color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, fontFamily: FontFamily.semiBold)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          ShowToastDialog.showLoader("Submitting...");

                          final user = Constant.userModel;
                          final controller = Get.find<AdListingDetailController>();

                          final report = AdReportModel(
                            id: const Uuid().v4(),
                            adId: ad.id,
                            adTitle: ad.title,
                            adImage: ad.mainImage,
                            reporterId: uid,
                            reporterName: user?.fullNameString(),
                            reporterEmail: user?.email,
                            sellerId: ad.sellerId,
                            sellerName: ad.sellerName,
                            reasonId: "system_unavailable_flag",
                            reasonTitle: "Item Marked as Unavailable",
                            description: "A buyer flagged this item as sold/unavailable.",
                            status: 'pending',
                            createdAt: Timestamp.now(),
                          );

                          final success = await FireStoreUtils.submitAdReport(report);
                          ShowToastDialog.closeLoader();

                          if (success) {
                            controller.onReportSubmitted(report);
                            ShowToastDialog.showSuccess("Thank you for letting us know!");
                          } else {
                            ShowToastDialog.showError("Failed to submit. Please try again.");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Yes, Mark it", style: TextStyle(color: Colors.white, fontFamily: FontFamily.semiBold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        )
    );
  }

  Widget _reportStatusBadge(String? status) {
    Color color;
    String label;
    switch ((status ?? 'pending').toLowerCase()) {
      case 'reviewed':
        color = const Color(0xff4CAF50);
        label = 'Reviewed';
        break;
      case 'dismissed':
        color = const Color(0xff8E8E93);
        label = 'Dismissed';
        break;
      default:
        color = const Color(0xffFF9500);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontFamily: FontFamily.bold, color: color),
      ),
    );
  }

  void _showReportDialog(BuildContext context, AdModel ad, bool isDark) async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      ShowToastDialog.showError("Please login to report an ad");
      return;
    }

    final alreadyReported = await FireStoreUtils.hasUserReportedAd(ad.id!, uid);
    if (alreadyReported) {
      ShowToastDialog.showWarning("You have already reported this ad");
      return;
    }

    ShowToastDialog.showLoader("Loading...");
    final reasons = await FireStoreUtils.getActiveReportReasons();
    ShowToastDialog.closeLoader();
    if (reasons.isEmpty) {
      ShowToastDialog.showWarning("Report reasons not configured yet");
      return;
    }

    final selectedReason = Rxn<ReportReasonModel>();
    final descriptionController = TextEditingController();
    final isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppThemeData.danger50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 22, color: AppThemeData.danger300),
                    spaceW(width: 10),
                    Expanded(
                      child: Text(
                        "Report this Ad",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: FontFamily.bold, color: AppThemeData.danger300),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(Icons.close, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select a reason",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
                      ),
                      spaceH(height: 12),
                      Obx(
                            () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: reasons.map((reason) {
                            final isSelected = selectedReason.value?.id == reason.id;
                            return GestureDetector(
                              onTap: () => selectedReason.value = reason,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppThemeData.danger300 : (isDark ? AppThemeData.grey9 : AppThemeData.grey1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppThemeData.danger300 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4)),
                                ),
                                child: Text(
                                  reason.title ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? Colors.white : (isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      spaceH(height: 20),
                      Text(
                        "Additional details (optional)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
                      ),
                      spaceH(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
                        decoration: InputDecoration(
                          hintText: "Describe the issue...",
                          hintStyle: TextStyle(color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          filled: true,
                          fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppThemeData.primary4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                      () => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                        if (selectedReason.value == null) {
                          ShowToastDialog.showWarning("Please select a report reason");
                          return;
                        }

                        isSubmitting.value = true;
                        final user = Constant.userModel;
                        final controller = Get.find<AdListingDetailController>();
                        final report = AdReportModel(
                          id: const Uuid().v4(),
                          adId: ad.id,
                          adTitle: ad.title,
                          adImage: ad.mainImage,
                          reporterId: uid,
                          reporterName: user?.fullNameString(),
                          reporterEmail: user?.email,
                          sellerId: ad.sellerId,
                          sellerName: ad.sellerName,
                          reasonId: selectedReason.value!.id,
                          reasonTitle: selectedReason.value!.title,
                          description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                          status: 'pending',
                          createdAt: Timestamp.now(),
                        );

                        final success = await FireStoreUtils.submitAdReport(report);
                        isSubmitting.value = false;

                        if (success) {
                          Get.back();
                          controller.onReportSubmitted(report);
                          ShowToastDialog.showSuccess("Report submitted. Thank you!");
                        } else {
                          ShowToastDialog.showError("Failed to submit report. Please try again.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitting.value ? AppThemeData.grey5 : AppThemeData.danger300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isSubmitting.value ? "Submitting..." : "Submit Report",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── IMAGE GALLERY WITH TAP TO FULLSCREEN ────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  final bool isDark;

  const _ImageGallery({required this.images, required this.isDark});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          images: widget.images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: widget.images.isEmpty
              ? Container(
            color: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey3,
            child: Center(child: Icon(Icons.image_outlined, size: 64, color: widget.isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
          )
              : PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullScreen(context, i),
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey3),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _current ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ),
          ),
        if (widget.images.isNotEmpty)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.zoom_out_map_rounded, size: 18, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ─── FULL SCREEN GALLERY WITH ZOOM ───────────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              errorWidget: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}