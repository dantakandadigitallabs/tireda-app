// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/add_products/views/add_products_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/my_ads_controller.dart';
import 'ad_detail_view.dart';

class MyAdsView extends GetView<MyAdsController> {
  const MyAdsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<MyAdsController>(
      init: MyAdsController(),
      builder: (controller) {
        final list = controller.filteredList;

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(
            context,
            themeChange,
            controller.featuredOnly.value ? "My Featured Ads".tr : "My Advertisement".tr,
            isBack: controller.featuredOnly.value ? true : false,
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),

              // ── Search Bar ──────────────────────────────────
              _SearchBar(controller: controller, isDark: isDark),

              // ── Filter Bar ──────────────────────────────────
              _FilterBar(controller: controller, isDark: isDark),

              // ── List ────────────────────────────────────────
              Expanded(
                child: controller.isLoading.value
                    ? _LoadingList(isDark: isDark)
                    : list.isEmpty
                    ? _EmptyState(isDark: isDark, hasFilter: controller.selectedStatus.value != 'all' || controller.searchQuery.value.isNotEmpty, onClear: () {
                  controller.setStatusFilter('all');
                  controller.clearSearch();
                })
                    : RefreshIndicator(
                  color: AppThemeData.primary4,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => spaceH(height: 10),
                    itemBuilder: (context, index) {
                      return _AdCard(ad: list[index], controller: controller, isDark: isDark);
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

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// Tireda Custom: no counterpart in eSellify 1.5 base — pure Tireda addition.
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final MyAdsController controller;
  final bool isDark;

  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.setSearchQuery,
        style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        decoration: InputDecoration(
          hintText: "Search your ads...".tr,
          hintStyle: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          prefixIcon: Icon(Icons.search_rounded, size: 22, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
            onPressed: controller.clearSearch,
          )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final MyAdsController controller;
  final bool isDark;

  const _FilterBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // ── Status Dropdown (left) ─────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => _showStatusSheet(context),
              child: Obx(() => _FilterPill(label: controller.activeStatusLabel, icon: Icons.keyboard_arrow_down_rounded, isDark: isDark)),
            ),
          ),
          spaceW(width: 12),
          // ── Sort (right) ──────────────────────────
          GestureDetector(
            onTap: () => _showSortSheet(context),
            child: _FilterPill(label: "Sort".tr, icon: Icons.sort_rounded, isDark: isDark, iconFirst: false),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StatusFilterSheet(controller: controller, isDark: isDark),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SortSheet(controller: controller, isDark: isDark),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool iconFirst;

  const _FilterPill({required this.label, required this.icon, required this.isDark, this.iconFirst = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: iconFirst
            ? [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey2 : AppThemeData.grey8),
            ),
          ),
          spaceW(width: 4),
          Icon(icon, size: 18, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
        ]
            : [
          Icon(icon, size: 18, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
          spaceW(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey2 : AppThemeData.grey8),
          ),
        ],
      ),
    );
  }
}

// ─── Status Filter Bottom Sheet ───────────────────────────────────────────────
class _StatusFilterSheet extends StatelessWidget {
  final MyAdsController controller;
  final bool isDark;

  const _StatusFilterSheet({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          spaceH(height: 16),
          Text(
            "Filter by Status".tr,
            style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          spaceH(height: 14),
          Obx(
                () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MyAdsController.statusFilters.map((filter) {
                final isSelected = controller.selectedStatus.value == filter['key'];
                return GestureDetector(
                  onTap: () {
                    controller.setStatusFilter(filter['key']!);
                    Get.back();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey6 : AppThemeData.grey4)),
                    ),
                    child: Text(
                      filter['label']!,
                      style: TextStyle(fontSize: 13, fontFamily: FontFamily.medium, color: isSelected ? Colors.white : (isDark ? AppThemeData.grey2 : AppThemeData.grey8)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          spaceH(height: 10),
        ],
      ),
    );
  }
}

// ─── Sort Bottom Sheet ────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final MyAdsController controller;
  final bool isDark;

  const _SortSheet({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          spaceH(height: 16),
          Text(
            "Sort Ads".tr,
            style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          spaceH(height: 12),
          Obx(
                () => Column(
              children: MyAdsController.sortOptions.map((opt) {
                final isSelected = controller.selectedSort.value == opt['key'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: isSelected ? FontFamily.semiBold : FontFamily.regular,
                      color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey2 : AppThemeData.grey8),
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check_rounded, color: AppThemeData.primary4, size: 20) : null,
                  onTap: () {
                    controller.setSortOption(opt['key']!);
                    Get.back();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AD CARD  — matches screenshot layout exactly
// ─────────────────────────────────────────────────────────────────────────────
class _AdCard extends StatelessWidget {
  final AdModel ad;
  final MyAdsController controller;
  final bool isDark;

  const _AdCard({required this.ad, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tireda Custom: Outer Container keeps the custom drop shadow and
        // border; inner Material handles the solid background so the
        // InkWell ripple renders correctly on top, clipped to the rounded
        // corners via clipBehavior: Clip.hardEdge. 1.5 base uses a different
        // ordering (transparent Material > InkWell > decorated Container)
        // aimed at a separate IntrinsicHeight semantics-tree bug that
        // doesn't apply here — not taken, this structure fixes a real,
        // currently-relevant ripple-bleed issue.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, width: 1),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () => Get.to(() => AdDetailView(ad: ad)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product Image — fixed height, flush with card edge ──
                  Stack(
                    children: [
                      _Thumbnail(ad: ad, isDark: isDark),
                      if (ad.isFeatured == true)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(6)),
                            child: Text('Featured'.tr, style: TextStyle(fontSize: 10, fontFamily: FontFamily.semiBold, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  // ── Info ───────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top block — price + title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Price (room reserved on the right for the floating menu button)
                              Padding(
                                padding: const EdgeInsets.only(right: 40),
                                child: TextCustom(
                                  title: controller.formatPrice(ad),
                                  fontSize: 19,
                                  fontFamily: FontFamily.bold,
                                  color: AppThemeData.primary4,
                                ),
                              ),
                              spaceH(height: 6),
                              // Tireda Custom Merge (eSellify 1.5): localized title.
                              TextCustom(
                                title: ad.titleFor(Get.locale?.languageCode).isNotEmpty ? ad.titleFor(Get.locale?.languageCode) : 'Untitled'.tr,
                                fontSize: 14,
                                fontFamily: FontFamily.semiBold,
                                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                maxLine: 2,
                              ),
                              spaceH(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: AppThemeData.grey5),
                                  spaceW(width: 4),
                                  Expanded(
                                    child: TextCustom(
                                      title: controller.formatDate(ad.createdAt),
                                      fontSize: 11,
                                      fontFamily: FontFamily.regular,
                                      color: AppThemeData.grey5,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _StatusBadge(ad: ad, isDark: isDark),
                                    ],
                                  ),
                                ],
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
          ),
        ),
        // Floating actions menu — top-right of the card. Sits above the
        // GestureDetector so taps don't open the detail view.
        Positioned(
          top: 6,
          right: 6,
          child: _AdActionsMenu(ad: ad, controller: controller, isDark: isDark),
        ),
      ],
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────
class _Thumbnail extends StatelessWidget {
  final AdModel ad;
  final bool isDark;

  const _Thumbnail({required this.ad, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 140,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
        child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: ad.mainImage!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => _placeholder(),
          errorWidget: (_, _, _) => _placeholder(),
        )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
    child: Icon(Icons.image_outlined, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5, size: 32),
  );
}

// ─── Status Badge — outlined pill, right-aligned ──────────────────────────────
class _StatusBadge extends StatelessWidget {
  final AdModel ad;
  final bool isDark;

  const _StatusBadge({required this.ad, required this.isDark});

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
    final label = _label(ad.status, ad.isActive);
    final c = _color(ad.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: TextCustom(title: label, fontSize: 12, fontFamily: FontFamily.semiBold, color: c),
    );
  }

  String _label(String? status, bool? isActive) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'approved':
        return 'Live'.tr;
      case 'pending':
      case 'under_review':
        return 'Under Review'.tr;
      case 'sold':
      case 'sold_out':
        return 'Sold Out'.tr;
      case 'expired':
        return 'Expired'.tr;
      case 'inactive':
        return 'Deactivate'.tr;
      case 'soft_rejected':
        return 'Soft Rejected'.tr;
      case 'permanent_rejected':
        return 'Perm. Rejected'.tr;
      case 'resubmitted':
        return 'Resubmitted'.tr;
      case 'featured':
        return 'Featured'.tr;
      default:
        return isActive == true ? 'Live'.tr : 'Inactive'.tr;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.isDark, required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppThemeData.primary1, shape: BoxShape.circle),
              child: Icon(hasFilter ? Icons.filter_list_off_rounded : Icons.storefront_outlined, size: 52, color: AppThemeData.primary4),
            ),
            spaceH(height: 20),
            TextCustom(title: hasFilter ? "No Ads Found".tr : "No Ads Yet".tr, fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            spaceH(height: 10),
            TextCustom(
              title: hasFilter ? "No ads match the selected filter.\nTry a different status.".tr : "You haven't posted any ads.\nTap Sell to post your first ad!".tr,
              fontSize: 14,
              color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              spaceH(height: 20),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    "Clear Filter".tr,
                    style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingList extends StatelessWidget {
  final bool isDark;

  const _LoadingList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 5,
      separatorBuilder: (_, _) => spaceH(height: 10),
      itemBuilder: (_, _) => _SkeletonCard(isDark: isDark),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final soft = isDark ? AppThemeData.grey8 : AppThemeData.grey2;

    bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(4)),
    );

    return Container(
      height: 130,
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 110,
            height: 130,
            decoration: BoxDecoration(
              color: base,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [bar(120, 16), const Spacer(), bar(20, 20)]),
                  spaceH(height: 8),
                  bar(90, 12),
                  spaceH(height: 6),
                  bar(80, 10),
                  spaceH(height: 8),
                  bar(130, 10),
                  const Spacer(),
                  Align(alignment: Alignment.centerRight, child: bar(90, 26)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit / Delete popup menu on each ad card ────────────────────────────────
class _AdActionsMenu extends StatelessWidget {
  final AdModel ad;
  final MyAdsController controller;
  final bool isDark;

  const _AdActionsMenu({required this.ad, required this.controller, required this.isDark});

  /// Only show Edit when the ad is in a state where editing is allowed.
  bool get _canEdit => ['pending', 'active', 'soft_rejected', 'resubmitted'].contains((ad.status ?? '').toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (isDark ? AppThemeData.grey9 : AppThemeData.grey1).withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        tooltip: 'More'.tr,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
        color: isDark ? AppThemeData.grey10 : AppThemeData.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (value) async {
          if (value == 'edit') {
            // List is a Firestore stream, so it auto-refreshes after edits.
            await Get.to(() => const AddProductsView(), arguments: {"isEdit": true, "ad": ad});
          } else if (value == 'delete') {
            // ignore: use_build_context_synchronously
            await controller.deleteAd(ad, context);
          }
        },
        itemBuilder: (_) => [
          if (_canEdit)
            PopupMenuItem<String>(
              value: 'edit',
              height: 40,
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18, color: AppThemeData.primary4),
                const SizedBox(width: 10),
                Text('Edit'.tr, style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
              ]),
            ),
          PopupMenuItem<String>(
            value: 'delete',
            height: 40,
            child: Row(children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppThemeData.danger300),
              const SizedBox(width: 10),
              Text('Delete'.tr, style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.danger300)),
            ]),
          ),
        ],
      ),
    );
  }
}