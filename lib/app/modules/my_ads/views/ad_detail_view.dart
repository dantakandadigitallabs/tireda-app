import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/my_ads/controllers/ad_detail_controller.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/map_view_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:eSellify/app/modules/add_products/views/add_products_view.dart';
import 'package:url_launcher/url_launcher.dart';

class AdDetailView extends StatelessWidget {
  final AdModel ad;

  const AdDetailView({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdDetailController()..ad = ad);
    controller.loadReportCount();
    controller.initFeaturedStatus();
    return _AdDetailBody(controller: controller, ad: ad);
  }
}

class _AdDetailBody extends StatelessWidget {
  final AdDetailController controller;
  final AdModel ad;

  const _AdDetailBody({required this.controller, required this.ad});

  List<String> get _images => controller.images;

  Future<void> _deleteAd(BuildContext context) async {
    final isDark = Provider.of<DarkThemeProvider>(context, listen: false).isDarkTheme();
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppThemeData.danger50, shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: AppThemeData.danger300, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Delete Ad?",
                    style: TextStyle(fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "This will permanently delete your ad\n\"${ad.title ?? 'Untitled'}\"\nThis action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                            ),
                            child: Center(
                              child: Text(
                                "Cancel",
                                style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppThemeData.danger300),
                            child: const Center(
                              child: Text(
                                "Delete",
                                style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirm != true) return;

    final success = await controller.deleteAd();
    if (success) Get.back(result: true);
  }

  Future<void> _editAd() async {
    final result = await Get.to(() => const AddProductsView(), arguments: {"isEdit": true, "ad": ad});
    if (result == true) Get.back(result: true);
  }

  Future<void> _markAsSold() async {
    final result = await Get.to(() => WhoBoughtScreen(ad: ad));
    if (result == true) Get.back(result: true);
  }

  Widget _buildFeaturedBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xffE0F7FA), const Color(0xffE0F2F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff00BCD4).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Ad icon
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Center(
              child: Text(
                "AD",
                style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: Color(0xffFF6B35)),
              ),
            ),
          ),
          spaceW(width: 16),
          // Text + button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Feature your ad, attract\nmore clients and sell faster",
                  style: TextStyle(fontSize: 13, fontFamily: FontFamily.medium, color: Color(0xff37474F), height: 1.4),
                ),
                spaceH(height: 10),
                GestureDetector(
                  onTap: () => controller.featureAd(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xff26C6DA), Color(0xff00ACC1)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: const Color(0xff00BCD4).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: const Text(
                      "Create Featured Ad",
                      style: TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final status = (ad.status ?? '').toLowerCase();

    // 5. Sold Out / Expired / Inactive / Permanent Rejected → only status shown
    if (['sold', 'expired', 'inactive', 'permanent_rejected'].contains(status)) {
      return Container(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _getStatusColor(status).withOpacity(0.1),
            border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              _getStatusLabel(status),
              style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: _getStatusColor(status)),
            ),
          ),
        ),
      );
    }

    // Determine buttons
    final bool showEdit = ['pending', 'active', 'soft_rejected', 'resubmitted'].contains(status);
    final bool showRemove = ['pending', 'soft_rejected'].contains(status);
    final bool showSoldOut = ['active', 'resubmitted'].contains(status);

    if (!showEdit && !showRemove && !showSoldOut) return const SizedBox.shrink();

    return Container(
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          if (showEdit)
            Expanded(
              child: GestureDetector(
                onTap: _editAd,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.primary4, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "Edit",
                      style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4),
                    ),
                  ),
                ),
              ),
            ),
          if (showEdit && (showRemove || showSoldOut)) spaceW(width: 12),
          if (showRemove)
            Expanded(
              child: GestureDetector(
                onTap: () => _deleteAd(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppThemeData.danger300),
                  child: const Center(
                    child: Text(
                      "Remove",
                      style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (showSoldOut)
            Expanded(
              child: GestureDetector(
                onTap: _markAsSold,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xff4CAF50)),
                  child: const Center(
                    child: Text(
                      "Sold Out",
                      style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xff00C750);
      case 'pending':
      case 'resubmitted':
        return const Color(0xffFF9500);
      case 'sold':
        return const Color(0xff007AFF);
      case 'expired':
        return const Color(0xff8E8E93);
      case 'inactive':
      case 'soft_rejected':
      case 'permanent_rejected':
        return const Color(0xffE7000B);
      default:
        return const Color(0xff8E8E93);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Approved';
      case 'pending':
        return 'Under Review';
      case 'sold':
        return 'Sold Out';
      case 'expired':
        return 'Expired';
      case 'inactive':
        return 'Inactive';
      case 'soft_rejected':
        return 'Soft Rejected';
      case 'permanent_rejected':
        return 'Permanent Rejected';
      case 'resubmitted':
        return 'Resubmitted';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();
    final images = _images;
    final hasLocation = (ad.location?.latitude != null) && (ad.location?.longitude != null);
    final hasCustomFields = (ad.customFields?.isNotEmpty ?? false) && ad.customFields!.any((f) => (f['value']?.toString().trim() ?? '').isNotEmpty);
    final hasDescription = (ad.description?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, "", isBack: true),
      body: Column(
        children: [
          // ── Scrollable body ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Featured Ad Banner ──────────────────────────────────────
                  if ((ad.status ?? '').toLowerCase() == 'active') Obx(() => controller.isFeatured.value ? const SizedBox.shrink() : _buildFeaturedBanner(isDark)),
                  // ── Main Content Card ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Image gallery ────────────────────────
                          Obx(
                            () => _ImageGallery(
                              images: _images,
                              currentIndex: controller.currentIndex.value,
                              pageController: controller.pageController,
                              isDark: isDark,
                              onPageChanged: (i) => controller.currentIndex.value = i,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Views + Likes pills ───────────
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatPill(icon: Icons.remove_red_eye_outlined, label: "Views : ${ad.views ?? 0}", isDark: isDark),
                                    ),
                                    spaceW(width: 12),
                                    Expanded(
                                      child: _StatPill(icon: Icons.favorite_border_rounded, label: "Likes : ${ad.likes ?? 0}", isDark: isDark),
                                    ),
                                  ],
                                ),
                                spaceH(height: 8),
                                Obx(
                                  () => controller.reportCount.value > 0
                                      ? Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.danger300.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppThemeData.danger300.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.flag_outlined, size: 16, color: AppThemeData.danger300),
                                              spaceW(width: 8),
                                              TextCustom(
                                                title: "${controller.reportCount.value} ${controller.reportCount.value == 1 ? 'report' : 'reports'} on this ad",
                                                fontSize: 12,
                                                fontFamily: FontFamily.medium,
                                                color: AppThemeData.danger300,
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                spaceH(height: 16),

                                // ── Title ─────────────────────────
                                TextCustom(title: ad.title ?? 'Untitled', fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                                spaceH(height: 8),

                                // ── Price + Status ────────────────
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextCustom(
                                        title: controller.formatPrice(),
                                        fontSize: 22,
                                        fontFamily: FontFamily.bold,
                                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                      ),
                                    ),
                                    _StatusChip(ad: ad),
                                  ],
                                ),
                                spaceH(height: 10),

                                // ── Rejection Reason ──────────────
                                if ((ad.status == 'soft_rejected' || ad.status == 'permanent_rejected') && ad.rejectionReason != null && ad.rejectionReason!.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.danger300.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppThemeData.danger300.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline, size: 18, color: AppThemeData.danger300),
                                        spaceW(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TextCustom(title: "Rejection Reason", fontSize: 12, fontFamily: FontFamily.bold, color: AppThemeData.danger300),
                                              spaceH(height: 2),
                                              TextCustom(title: ad.rejectionReason!, fontSize: 13, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7, maxLine: 5),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // ── Location + Date ───────────────
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: AppThemeData.primary4),
                                    spaceW(width: 4),
                                    Expanded(
                                      child: TextCustom(title: ad.address.toString(), fontSize: 14, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7, maxLine: 3),
                                    ),
                                    TextCustom(title: controller.formatDate(), fontSize: 12, color: AppThemeData.grey5),
                                  ],
                                ),

                                // ── Custom Fields ─────────────────
                                if (hasCustomFields) ...[_Divider(isDark: isDark), _CustomFieldsSection(customFields: ad.customFields!, isDark: isDark)],

                                // ── Description ───────────────────
                                if (hasDescription) ...[
                                  _Divider(isDark: isDark),
                                  TextCustom(
                                    title: "About this Advertisement",
                                    fontSize: 15,
                                    fontFamily: FontFamily.bold,
                                    color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                  ),
                                  spaceH(height: 6),
                                  TextCustom(title: ad.description!, fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, maxLine: 100),
                                ],

                                // ── Location ──────────────────────
                                if (hasLocation) ...[
                                  _Divider(isDark: isDark),
                                  GestureDetector(
                                    onTap: () async {
                                      final lat = ad.location!.latitude!;
                                      final lng = ad.location!.longitude!;
                                      // Try Google Maps first, fallback to OSM
                                      final googleUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                      final osmUri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=15');
                                      if (await canLaunchUrl(googleUri)) {
                                        await launchUrl(googleUri, mode: LaunchMode.externalApplication);
                                      } else if (await canLaunchUrl(osmUri)) {
                                        await launchUrl(osmUri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextCustom(
                                                title: "Location",
                                                fontSize: 15,
                                                fontFamily: FontFamily.bold,
                                                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                              ),
                                            ),
                                            Icon(Icons.open_in_new, size: 16, color: AppThemeData.primary4),
                                          ],
                                        ),
                                        if (ad.address != null && ad.address!.isNotEmpty) ...[
                                          spaceH(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.location_on, size: 16, color: AppThemeData.primary4),
                                              spaceW(width: 6),
                                              Expanded(
                                                child: TextCustom(title: ad.address!, fontSize: 13, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7, maxLine: 3),
                                              ),
                                            ],
                                          ),
                                        ],
                                        spaceH(height: 10),
                                        MapViewWidget(
                                          latitude: ad.location!.latitude!,
                                          longitude: ad.location!.longitude!,
                                          height: 120,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                spaceH(height: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  spaceH(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──────────────────────────────────────
          _buildBottomBar(context, isDark),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE GALLERY
// ─────────────────────────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({required this.images, required this.currentIndex, required this.pageController, required this.isDark, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          SizedBox(
            height: 270,
            width: double.infinity,
            child: images.isEmpty
                ? Container(
                    color: isDark ? AppThemeData.grey9 : AppThemeData.grey3,
                    child: Center(child: Icon(Icons.image_outlined, size: 64, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                  )
                : PageView.builder(
                    controller: pageController,
                    itemCount: images.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey3),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? AppThemeData.grey9 : AppThemeData.grey3,
                        child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
          ),

          // Dot indicators
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(color: i == currentIndex ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT PILL (Views / Likes)
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatPill({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppThemeData.grey5),
          spaceW(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final AdModel ad;

  const _StatusChip({required this.ad});

  Color _color(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return const Color(0xff00C750);
      case 'pending':
      case 'resubmitted':
        return const Color(0xffFF9500);
      case 'sold':
        return const Color(0xff007AFF);
      case 'expired':
        return const Color(0xff8E8E93);
      case 'inactive':
      case 'soft_rejected':
      case 'permanent_rejected':
        return const Color(0xffE7000B);
      default:
        return const Color(0xff8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(ad.status);
    final label = _label(ad.status, ad.isActive);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: c.withOpacity(0.1),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontFamily: FontFamily.semiBold, color: c),
      ),
    );
  }

  String _label(String? status, bool? isActive) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'approved':
        return 'Approved';
      case 'pending':
      case 'under_review':
        return 'Under Review';
      case 'sold':
      case 'sold_out':
        return 'Sold Out';
      case 'expired':
        return 'Expired';
      case 'inactive':
        return 'Inactive';
      case 'soft_rejected':
        return 'Soft Rejected';
      case 'permanent_rejected':
        return 'Permanent Rejected';
      case 'resubmitted':
        return 'Resubmitted';
      default:
        return isActive == true ? 'Approved' : 'Inactive';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, thickness: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM FIELDS SECTION — 2-column grid
// Each item in customFields: { 'name': String, 'icon': String, 'value': String }
// ─────────────────────────────────────────────────────────────────────────────
class _CustomFieldsSection extends StatelessWidget {
  final List<Map<String, dynamic>> customFields;
  final bool isDark;

  const _CustomFieldsSection({required this.customFields, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Keep only items that have a non-empty value
    final items = customFields.where((f) => (f['value']?.toString().trim() ?? '').isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    // Build rows of 2
    final List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldCell(item: items[i], isDark: isDark),
              ),
              if (i + 1 < items.length) ...[
                spaceW(width: 16),
                Expanded(
                  child: _FieldCell(item: items[i + 1], isDark: isDark),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _FieldCell extends StatelessWidget {
  /// item = { 'name': String, 'icon': String, 'value': String }
  final Map<String, dynamic> item;
  final bool isDark;

  const _FieldCell({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final iconUrl = item['icon']?.toString() ?? '';
    final value = item['value']?.toString() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Icon box — network image if URL present, else fallback Material icon
        Container(
          width: 32,
          height: 32,
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
          child: iconUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: iconUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => Icon(_fallbackIcon(name), size: 16, color: AppThemeData.grey5),
                )
              : Center(child: Icon(_fallbackIcon(name), size: 16, color: AppThemeData.grey5)),
        ),
        spaceW(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 11, fontFamily: FontFamily.regular, color: AppThemeData.grey5),
              ),
              spaceH(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _fallbackIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('brand')) return Icons.label_outline_rounded;
    if (n.contains('model')) return Icons.device_hub_outlined;
    if (n.contains('color') || n.contains('colour')) return Icons.palette_outlined;
    if (n.contains('warrant')) return Icons.verified_outlined;
    if (n.contains('condition')) return Icons.star_outline_rounded;
    if (n.contains('year') || n.contains('age')) return Icons.calendar_today_outlined;
    if (n.contains('size')) return Icons.straighten_outlined;
    if (n.contains('weight')) return Icons.fitness_center_outlined;
    if (n.contains('fuel')) return Icons.local_gas_station_outlined;
    if (n.contains('km') || n.contains('mileage')) return Icons.speed_outlined;
    if (n.contains('type')) return Icons.category_outlined;
    return Icons.info_outline_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE MAP (small, right-aligned next to "Location" label)
// ─────────────────────────────────────────────────────────────────────────────
class _InlineMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _InlineMap({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude&zoom=15');
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: MapViewWidget(
        latitude: latitude,
        longitude: longitude,
        height: 80,
        width: 130,
        borderRadius: 10,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WHO BOUGHT? — Full screen buyer selection
// ─────────────────────────────────────────────────────────────────────────────
class WhoBoughtScreen extends StatelessWidget {
  final AdModel ad;

  const WhoBoughtScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final wbController = Get.put(WhoBoughtController()..initWithAd(ad));
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        ),
        title: TextCustom(title: "Who bought?", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
      ),
      body: Column(
        children: [
          // Ad info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              border: Border(bottom: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                      ? CachedNetworkImage(imageUrl: ad.mainImage!, height: 56, width: 56, fit: BoxFit.cover)
                      : Container(
                          height: 56,
                          width: 56,
                          color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                          child: const Icon(Icons.image, color: AppThemeData.grey5),
                        ),
                ),
                spaceW(width: 14),
                Expanded(
                  child: TextCustom(title: ad.title ?? '', fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 2),
                ),
                TextCustom(title: wbController.formatPrice(), fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              ],
            ),
          ),

          // Buyer list
          Expanded(
            child: Obx(() {
              if (wbController.isLoading.value) return _buildBuyerShimmer(isDark);
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: wbController.chatRooms.length + 1,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, indent: 80),
                itemBuilder: (context, index) {
                  if (index == wbController.chatRooms.length) {
                    return Obx(() {
                      final isSelected = wbController.selectedBuyerId.value == 'none';
                      return InkWell(
                        onTap: () => wbController.selectNone(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4)),
                            color: isSelected ? AppThemeData.primary4.withValues(alpha: 0.08) : Colors.transparent,
                          ),
                          child: Center(
                            child: TextCustom(
                              title: "None of above",
                              fontSize: 15,
                              fontFamily: FontFamily.semiBold,
                              color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                            ),
                          ),
                        ),
                      );
                    });
                  }

                  final room = wbController.chatRooms[index];
                  final buyerName = room.otherUserName(wbController.currentUserId);
                  final buyerProfile = room.otherUserProfile(wbController.currentUserId);
                  final buyerId = room.otherUserId(wbController.currentUserId);

                  return Obx(() {
                    final isSelected = wbController.selectedBuyerId.value == buyerId;
                    return InkWell(
                      onTap: () => wbController.selectBuyer(buyerId, buyerName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.primary4.withValues(alpha: 0.15),
                              backgroundImage: buyerProfile.isNotEmpty ? CachedNetworkImageProvider(buyerProfile) : null,
                              child: buyerProfile.isEmpty ? Icon(Icons.person, size: 24, color: isDark ? AppThemeData.grey5 : AppThemeData.primary4) : null,
                            ),
                            spaceW(width: 14),
                            Expanded(
                              child: TextCustom(title: buyerName, fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                            ),
                            Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey6 : AppThemeData.grey5), width: 2),
                                color: isSelected ? AppThemeData.primary4 : Colors.transparent,
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // Mark as Sold button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Obx(() {
                final hasSelection = wbController.selectedBuyerId.value != null;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: hasSelection
                        ? () async {
                            final ok = await wbController.markSold();
                            if (ok) Get.back(result: true);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSelection ? const Color(0xff4CAF50) : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Mark As Sold Out",
                      style: TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, indent: 80),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: color),
              spaceW(width: 14),
              Expanded(
                child: Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR — Edit + Remove
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BottomBar({required this.isDark, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          // Edit button (outlined)
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemeData.primary4, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    "Edit",
                    style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4),
                  ),
                ),
              ),
            ),
          ),
          spaceW(width: 12),
          // Remove button (filled)
          Expanded(
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                height: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppThemeData.primary4),
                child: const Center(
                  child: Text(
                    "Remove",
                    style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
