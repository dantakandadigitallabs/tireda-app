// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/modules/seller_reviews/views/seller_reviews_view.dart';
import 'package:eSellify/app/models/report_reason_model.dart';
import 'package:eSellify/app/routes/app_pages.dart'; // Tireda Custom: for LOGIN_SCREEN / DASHBOARD_SCREEN routes
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/price_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eSellify/app/modules/dashboard_screen/controllers/dashboard_screen_controller.dart'; // Tireda Custom
import 'package:uuid/uuid.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/widgets/expandable_text.dart';
import 'package:eSellify/widgets/follow_button.dart';
import 'package:eSellify/widgets/watermarked_image.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/safety_tips_bottom_sheet.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/ad_listing_detail_controller.dart';
import 'package:eSellify/utils/navigation_helper.dart';

// ─── AdListingDetailView ──────────────────────────────────────────────────────
// Converted from GetView to StatefulWidget so each page in the similar-ads
// navigation chain owns its own controller instance as a plain Dart object.
// This eliminates the GetX singleton-registry conflict that caused stale data
// and broken back-navigation when stacking multiple detail pages.
class AdListingDetailView extends StatefulWidget {
  final AdModel ad;

  const AdListingDetailView({super.key, required this.ad});

  @override
  State<AdListingDetailView> createState() => _AdListingDetailViewState();
}

class _AdListingDetailViewState extends State<AdListingDetailView> {
  late final AdListingDetailController _controller;

  @override
  void initState() {
    super.initState();
    // Each page instance creates its own controller — no GetX registry.
    _controller = AdListingDetailController();
    _controller.initWithAd(widget.ad);
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final ad = _controller.ad;
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
                  TextCustom(title: "Back", fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ],
              ),
            ),
            actions: [
              // Tireda Custom: like icon swapped from favorite heart to bookmark, filled/outline
              ObxValue<RxBool>(
                    (isLiked) => GestureDetector(
                  onTap: _controller.toggleLike,
                  child: Icon(
                    isLiked.value ? Icons.bookmark : Icons.bookmark_border,
                    color: isLiked.value ? AppThemeData.primary4 : (isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    size: 22,
                  ),
                ),
                _controller.isLiked,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _controller.shareAd,
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

                      // ── Hero Section (Title -> Location -> Price -> Chat Card) ──
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

                            // Location (Clickable)
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

                            spaceH(height: 12),
                            // Tireda Custom: compact "Chat with the seller" skeleton card.
                            // All taps route straight to real chat — no in-card chat logic.
                            _buildChatSkeletonCard(isDark),
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
                            // Custom Fields (Limited to 6) — Tireda Custom: bordered "Summary" card
                            if (hasCustomFields) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tireda Custom: icon badge for visual anchor
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), shape: BoxShape.circle),
                                          child: Icon(Icons.list_alt_rounded, size: 14, color: AppThemeData.primary4),
                                        ),
                                        spaceW(width: 8),
                                        TextCustom(title: "Summary", fontSize: 13, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                      ],
                                    ),
                                    spaceH(height: 8),
                                    Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                                    spaceH(height: 10),
                                    _buildCustomFields(ad.customFields!, isDark),
                                  ],
                                ),
                              ),
                              spaceH(height: 12),
                            ],

                            // Description — Tireda Custom: bordered "Description" card
                            if (ad.description != null && ad.description!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.primary4, width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tireda Custom: icon badge for visual anchor
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), shape: BoxShape.circle),
                                          child: Icon(Icons.description_outlined, size: 14, color: AppThemeData.primary4),
                                        ),
                                        spaceW(width: 8),
                                        TextCustom(title: "Description", fontSize: 13, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                      ],
                                    ),
                                    spaceH(height: 8),
                                    Divider(height: 1, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                                    spaceH(height: 10),
                                    ExpandableText(text: ad.description!, fontSize: 13, color: isDark ? AppThemeData.grey2 : AppThemeData.grey8, maxLines: 3),
                                  ],
                                ),
                              ),
                              spaceH(height: 6),
                            ],

                            // Seller Info Trust Card
                            spaceH(height: 8),
                            Divider(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                            spaceH(height: 12),
                            _buildSellerInfo(ad, isDark),

                            // Action Row (Mark Unavailable / Report Abuse / Post Ad Like This)
                            spaceH(height: 16),
                            _buildActionRow(ad, isDark),
                            spaceH(height: 16),
                          ],
                        ),
                      ),

                      // ── Similar Ads ────────────────────────────────────────
                      _SimilarAdsSection(controller: _controller, isDark: isDark),
                    ],
                  ),
                ),
              ),

              // ── 3-Button Sticky Bottom Bar (moderated sizing) ─────────────────────────────
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
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
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

                    // 2. WhatsApp Button — Tireda Custom: replaces Chat button.
                    // Mirrors Call's phone-extraction logic, then opens WhatsApp chat.
                    if (ad.phoneNumber != null && ad.phoneNumber!.isNotEmpty) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final rawPhone = '${ad.countryCode ?? ''}${ad.phoneNumber}';
                            final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
                            final uri = Uri.parse('https://wa.me/$digitsOnly');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF25D366), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedWhatsapp, color: const Color(0xFF25D366), size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text("WhatsApp", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: const Color(0xFF25D366)), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      spaceW(width: 8),
                    ],

                    // 3. Offer Button (Standard ads) / Apply Now Button (Job ads)
                    Expanded(
                      child: ad.isJobAd
                          ? GestureDetector(
                        onTap: () => SafetyTipsBottomSheet.show(
                          context,
                          continueLabel: "Continue to apply",
                          onContinue: () async {
                            if (await _controller.canApplyForJob()) {
                              _showApplyJobSheet(context, _controller, isDark);
                            }
                          },
                        ),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.primary4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.work_outline_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text("Apply Now", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Colors.white), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      )
                          : GestureDetector(
                        onTap: () => SafetyTipsBottomSheet.show(
                          context,
                          continueLabel: "Continue to offer",
                          onContinue: () => _showMakeOfferSheet(context, _controller, isDark),
                        ),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.primary4),
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

  // ─── Chat Skeleton Card (Tireda Custom) ─────────────────────

  Widget _buildChatSkeletonCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(title: "Chat with the seller", fontSize: 13, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chatQuickChip("Make an offer", isDark),
              _chatQuickChip("Is this available?", isDark),
              _chatQuickChip("Last price", isDark),
            ],
          ),
          spaceH(height: 8),
          GestureDetector(
            onTap: _controller.openChat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(child: TextCustom(title: "Write your message here", fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                  Icon(Icons.send_rounded, size: 16, color: AppThemeData.primary4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatQuickChip(String label, bool isDark) {
    return GestureDetector(
      onTap: _controller.openChat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppThemeData.primary4.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontFamily: FontFamily.medium, color: AppThemeData.primary4)),
      ),
    );
  }

  // Tireda Custom: navigate to Dashboard root, then explicitly trigger the
  // Sell flow via Get.find — awaiting offAllNamed ensures the Dashboard is
  // fully mounted first. This avoids relying on onInit()/arguments, which
  // don't re-fire if DashboardScreenController is already alive in memory.
  Future<void> _goToPostAd() async {
    if (FireStoreUtils.getCurrentUid() == null) {
      Get.toNamed(Routes.LOGIN_SCREEN);
      return;
    }
    await Get.offAllNamed(Routes.DASHBOARD_SCREEN);
    if (Get.isRegistered<DashboardScreenController>()) {
      await Get.find<DashboardScreenController>().onSellTap();
    }
  }

  // ─── Make an Offer Bottom Sheet (moderated sizing) ────────────────────────────

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                spaceH(height: 16),
                // Ad info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ad.mainImage != null && ad.mainImage!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: ad.mainImage!, width: 46, height: 46, fit: BoxFit.cover)
                          : Container(
                        width: 46,
                        height: 46,
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
                spaceH(height: 16),
                TextCustom(title: "Make an Offer", fontSize: 16, fontFamily: FontFamily.bold),
                spaceH(height: 4),
                TextCustom(title: "Enter your offer price below", fontSize: 13, color: AppThemeData.grey5),
                spaceH(height: 14),
                // Price input
                TextField(
                  controller: offerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  decoration: InputDecoration(
                    prefixText: ad.currency?.symbol ?? '\$ ',
                    prefixStyle: TextStyle(fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    hintText: "0.00",
                    hintStyle: TextStyle(fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                    filled: true,
                    fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                spaceH(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Send Offer",
                      style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
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

  // ─── Apply for Job Bottom Sheet (v1.3 — Job Category) (moderated sizing) ─────

  void _showApplyJobSheet(BuildContext context, AdListingDetailController controller, bool isDark) {
    final initialName = Constant.userModel?.fullNameString() ?? '';
    final nameController = TextEditingController(text: initialName == 'N/A' ? '' : initialName);
    final emailController = TextEditingController(text: Constant.userModel?.email ?? '');
    final coverNoteController = TextEditingController();
    final phoneController = TextEditingController(text: Constant.userModel?.phoneNumber ?? '');
    String countryCode = Constant.userModel?.countryCode ?? Constant.countryCode ?? '+91';
    final ad = controller.ad;

    File? cvFile;
    String? cvFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
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
                      spaceH(height: 16),
                      // Job info header
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ad.mainImage != null && ad.mainImage!.isNotEmpty
                                ? CachedNetworkImage(imageUrl: ad.mainImage!, width: 46, height: 46, fit: BoxFit.cover)
                                : Container(
                              width: 46,
                              height: 46,
                              color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                              child: const Icon(Icons.work_outline_rounded, color: AppThemeData.grey5),
                            ),
                          ),
                          spaceW(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextCustom(title: ad.title ?? '', fontSize: 14, fontFamily: FontFamily.medium, maxLine: 1),
                                spaceH(height: 2),
                                TextCustom(title: PriceFormatter.format(ad), fontSize: 13, color: AppThemeData.grey5),
                              ],
                            ),
                          ),
                        ],
                      ),
                      spaceH(height: 16),
                      TextCustom(title: "Apply for this job", fontSize: 16, fontFamily: FontFamily.bold),
                      spaceH(height: 4),
                      TextCustom(title: "Upload your CV and add a short note", fontSize: 13, color: AppThemeData.grey5),
                      spaceH(height: 16),

                      // Full Name
                      TextFieldWidget(
                        title: "Full Name *",
                        hintText: "Enter your full name",
                        controller: nameController,
                        onPress: () {},
                        fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                      ),
                      spaceH(height: 14),

                      // Email
                      TextFieldWidget(
                        title: "Email *",
                        hintText: "Enter your email",
                        controller: emailController,
                        onPress: () {},
                        textInputType: TextInputType.emailAddress,
                        fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                      ),
                      spaceH(height: 14),

                      // Phone with country code
                      MobileNumberTextField(
                        title: "Phone Number *",
                        controller: phoneController,
                        countryCode: countryCode,
                        onCountryCodeChanged: (code) => setState(() => countryCode = code),
                        onPress: () {},
                      ),
                      spaceH(height: 14),

                      // CV Upload
                      TextCustom(title: "CV / Resume *", fontSize: 14, fontFamily: FontFamily.medium),
                      spaceH(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              cvFile = File(result.files.single.path!);
                              cvFileName = result.files.single.name;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cvFile != null ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                              width: cvFile != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cvFile != null ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                                size: 20,
                                color: cvFile != null ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                              ),
                              spaceW(width: 12),
                              Expanded(
                                child: TextCustom(
                                  title: cvFileName ?? "Tap to upload (PDF, DOC, DOCX)",
                                  fontSize: 14,
                                  maxLine: 1,
                                  color: cvFile != null ? (isDark ? AppThemeData.grey1 : AppThemeData.grey10) : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                ),
                              ),
                              if (cvFile != null)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    cvFile = null;
                                    cvFileName = null;
                                  }),
                                  child: Icon(Icons.close, size: 18, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                ),
                            ],
                          ),
                        ),
                      ),
                      spaceH(height: 14),

                      // Cover Note
                      TextCustom(title: "Cover Note (optional)", fontSize: 14, fontFamily: FontFamily.medium),
                      spaceH(height: 8),
                      TextField(
                        controller: coverNoteController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                        decoration: InputDecoration(
                          hintText: "Tell the employer why you're a good fit...",
                          hintStyle: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                          filled: true,
                          fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      spaceH(height: 18),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) {
                              ShowToastDialog.showError("Please enter your full name".tr);
                              return;
                            }
                            final email = emailController.text.trim();
                            if (email.isEmpty || !GetUtils.isEmail(email)) {
                              ShowToastDialog.showError("Please enter a valid email".tr);
                              return;
                            }
                            if (phoneController.text.trim().isEmpty) {
                              ShowToastDialog.showError("Please enter your phone number".tr);
                              return;
                            }
                            if (cvFile == null || cvFileName == null) {
                              ShowToastDialog.showError("Please upload your CV".tr);
                              return;
                            }
                            controller.submitJobApplication(
                              cvFile: cvFile!,
                              cvFileName: cvFileName!,
                              fullName: nameController.text,
                              email: email,
                              coverNote: coverNoteController.text,
                              phone: phoneController.text,
                              countryCode: countryCode,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeData.primary4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            "Submit Application".tr,
                            style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                          ),
                        ),
                      ),
                      spaceH(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
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

  // ─── Seller Info Card (Tireda Custom: subtle brand-tinted background) ─────
  Widget _buildSellerInfo(AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (ad.sellerId != null) {
          Get.to(() => const SellerReviewsView(), arguments: {'sellerId': ad.sellerId, 'sellerName': ad.sellerName ?? 'Seller'});
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          // Tireda Custom: soft brand tint instead of flat grey/white, for a subtle uplift
          color: isDark ? AppThemeData.primary4.withValues(alpha: 0.06) : AppThemeData.primary4.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 1.2),
        ),
        child: Row(
          children: [
            // Avatar with verified badge as a corner overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                    backgroundImage: (ad.sellerProfile != null && ad.sellerProfile!.isNotEmpty) ? CachedNetworkImageProvider(ad.sellerProfile!) : null,
                    child: (ad.sellerProfile == null || ad.sellerProfile!.isEmpty) ? Icon(Icons.person, color: AppThemeData.grey5) : null,
                  ),
                ),
                if (ad.sellerId != null)
                  ObxValue<RxBool>(
                        (isVerified) => isVerified.value
                        ? Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppThemeData.primary4,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, width: 2),
                        ),
                        child: const Icon(Icons.verified_rounded, size: 11, color: Colors.white),
                      ),
                    )
                        : const SizedBox(),
                    _controller.isSellerVerified,
                  ),
              ],
            ),
            spaceW(width: 12),

            // Name + rating/views
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.sellerName ?? 'Seller',
                    style: TextStyle(fontSize: 14.5, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  spaceH(height: 3),
                  ObxValue<RxInt>(
                        (count) {
                      final rating = _controller.sellerRating.value;
                      final c = count.value;
                      return Row(
                        children: [
                          if (c > 0) ...[
                            Icon(Icons.star_rounded, size: 13, color: const Color(0xffFF9500)),
                            spaceW(width: 3),
                            TextCustom(title: rating.toStringAsFixed(1), fontSize: 11.5, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey2 : AppThemeData.grey9),
                            spaceW(width: 3),
                            TextCustom(title: '($c)', fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          ] else
                            TextCustom(title: 'No reviews', fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4)),
                          ),
                          ObxValue<RxInt>(
                                (views) => TextCustom(title: "${views.value} views", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            _controller.viewCount,
                          ),
                        ],
                      );
                    },
                    _controller.sellerReviewCount,
                  ),
                ],
              ),
            ),

            if (ad.sellerId != null && ad.sellerId!.isNotEmpty) ...[
              FollowButton(targetUid: ad.sellerId!, dense: true),
              spaceW(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(AdModel ad, bool isDark) {
    return ObxValue<RxBool>(
          (hasReported) {
        final report = _controller.existingReport.value;

        if (hasReported.value && report != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppThemeData.danger300.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 16, color: AppThemeData.danger300),
                        spaceW(width: 8),
                        Expanded(
                          child: TextCustom(title: "You flagged this ad", fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300),
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
              ),
              spaceH(height: 10),
              _buildPostAdButton(),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _markAsUnavailable(context, ad, isDark),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF2196F3), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Mark unavailable", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Color(0xFF2196F3))),
                  ),
                ),
                spaceW(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportDialog(context, ad, isDark),
                    icon: Icon(Icons.flag_outlined, size: 16, color: AppThemeData.danger300),
                    label: Text("Report abuse", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppThemeData.danger300, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            spaceH(height: 10),
            _buildPostAdButton(),
          ],
        );
      },
      _controller.hasReported,
    );
  }

  // Tireda Custom: "Post ad like this" button — filled with primary color for
  // more visual character; navigates to Dashboard root and re-triggers onSellTap().
  Widget _buildPostAdButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _goToPostAd,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
        label: Text("Post ad like this", style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemeData.primary4,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 32, color: Color(0xFF2196F3)),
              spaceH(height: 12),
              Text(
                "Mark as Unavailable?",
                style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
              ),
              spaceH(height: 6),
              Text(
                "Did the seller mention this item is already sold? Let us know so we can update the community.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
              ),
              spaceH(height: 18),
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
                          _controller.onReportSubmitted(report);
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
              ),
            ],
          ),
        ),
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeData.danger50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 18, color: AppThemeData.danger300),
                    spaceW(width: 10),
                    Expanded(
                      child: Text(
                        "Report this Ad",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: FontFamily.bold, color: AppThemeData.danger300),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    height: 44,
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
                          _controller.onReportSubmitted(report);
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

// ─── SIMILAR ADS SECTION ─────────────────────────────────────────────────────
class _SimilarAdsSection extends StatefulWidget {
  final AdListingDetailController controller;
  final bool isDark;

  const _SimilarAdsSection({required this.controller, required this.isDark});

  @override
  State<_SimilarAdsSection> createState() => _SimilarAdsSectionState();
}

class _SimilarAdsSectionState extends State<_SimilarAdsSection> {
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    // Deferred fetch — runs after the first frame so it does not block
    // the initial ad detail render (lazy loading).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_triggered && mounted) {
        _triggered = true;
        widget.controller.fetchSimilarAds();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Obx(() {
      final isLoading = widget.controller.isSimilarAdsLoading.value;
      final ads = widget.controller.similarAds;

      // Hide section entirely when not loading and no results
      if (!isLoading && ads.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "Similar Ads",
              style: TextStyle(
                fontSize: 16,
                fontFamily: FontFamily.bold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
              ),
            ),
          ),

          if (isLoading)
          // ── Shimmer placeholder while fetching ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 265,
                ),
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.grey9 : AppThemeData.grey3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
          // ── Actual ads grid ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ads.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 265,
                ),
                itemBuilder: (_, index) {
                  final ad = ads[index];
                  return GestureDetector(
                    onTap: () => goToSimilarAdDetail(ad),
                    child: _SimilarAdCard(ad: ad, isDark: isDark),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

// ─── SIMILAR AD CARD (mirrors _buildGridCard from AdsListingView) ─────────────
class _SimilarAdCard extends StatelessWidget {
  final AdModel ad;
  final bool isDark;

  const _SimilarAdCard({required this.ad, required this.isDark});

  String _formatShortLocation(String? address) {
    if (address == null || address.isEmpty) return '';
    final parts = address.split(',');
    if (parts.length < 2) return address.replaceAll('State', '').trim();
    final localGovt = parts.first.trim();
    final String state = parts[1]
        .replaceAll('State', '')
        .replaceAll('(FCT)', '')
        .trim();
    return '$state, $localGovt';
  }

  String _getCondition(AdModel ad) {
    try {
      if (ad.customFields == null || ad.customFields!.isEmpty) return '';
      for (final field in ad.customFields!) {
        final name = field['name']?.toString().toLowerCase() ?? '';
        if (name.contains('condition')) return field['value']?.toString() ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // ── Image ────────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: ad.mainImage!,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    ),
                  )
                      : Container(
                    color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
                      ),
                    ),
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
                          Text(
                            "Featured",
                            style: TextStyle(fontSize: 8, fontFamily: FontFamily.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // Price
                TextCustom(
                  title: PriceFormatter.format(ad),
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

                // Condition + Verified badge
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
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
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
              child: WatermarkedImage(
                child: CachedNetworkImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey3),
                ),
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
            child: WatermarkedImage(
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
      ),
    );
  }
}