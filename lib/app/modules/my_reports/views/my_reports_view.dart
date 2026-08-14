import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controllers/my_reports_controller.dart';

class MyReportsView extends GetView<MyReportsController> {
  const MyReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: MyReportsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "My Reports".tr, isBack: true),
          body: controller.isLoading.value
              ? _buildShimmer(isDark)
              : controller.reports.isEmpty
              ? _buildEmpty(isDark)
              : Column(
                  children: [
                    // Filter chips
                    _buildFilterChips(controller, isDark),
                    // Report list
                    Expanded(child: _buildList(controller, isDark)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterChips(MyReportsController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _filterChip("All", 'all', controller.reports.length, controller, isDark),
              const SizedBox(width: 8),
              _filterChip("Pending", 'pending', controller.countByStatus('pending'), controller, isDark),
              const SizedBox(width: 8),
              _filterChip("Reviewed", 'reviewed', controller.countByStatus('reviewed'), controller, isDark),
              const SizedBox(width: 8),
              _filterChip("Dismissed", 'dismissed', controller.countByStatus('dismissed'), controller, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, MyReportsController controller, bool isDark) {
    final isSelected = controller.selectedFilter.value == value;
    return GestureDetector(
      onTap: () => controller.setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey9 : AppThemeData.grey2), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: isSelected ? FontFamily.semiBold : FontFamily.regular,
                color: isSelected ? Colors.white : (isDark ? AppThemeData.grey3 : AppThemeData.grey7),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 11, fontFamily: FontFamily.bold, color: isSelected ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(MyReportsController controller, bool isDark) {
    return Obx(() {
      final list = controller.filteredReports;
      if (list.isEmpty) {
        return Center(
          child: TextCustom(title: "No reports found".tr, fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final report = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => controller.openReportedAd(report.adId),
              borderRadius: BorderRadius.circular(14),
              child: _ReportCard(report: report, isDark: isDark),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, shape: BoxShape.circle),
            child: Icon(Icons.flag_outlined, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
          ),
          spaceH(height: 20),
          TextCustom(title: "No reports yet".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          spaceH(height: 6),
          TextCustom(title: "Ads you report will appear here".tr, fontSize: 13, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
                ),
                spaceW(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 6),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 6),
                      Container(
                        height: 10,
                        width: 70,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final AdReportModel report;
  final bool isDark;

  const _ReportCard({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (report.adImage != null && report.adImage!.isNotEmpty)
                ? CachedNetworkImage(imageUrl: report.adImage!, height: 56, width: 56, fit: BoxFit.cover)
                : Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.image_outlined, size: 22, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                  ),
          ),
          spaceW(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad title + status
                Row(
                  children: [
                    Expanded(
                      child: TextCustom(
                        title: report.adTitle ?? 'Untitled Ad'.tr,
                        fontSize: 14,
                        fontFamily: FontFamily.semiBold,
                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                        maxLine: 1,
                      ),
                    ),
                    _statusBadge(report.status),
                  ],
                ),
                spaceH(height: 4),
                // Reason
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 13, color: AppThemeData.danger300),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextCustom(title: report.reasonTitleFor(Get.locale?.languageCode), fontSize: 12, fontFamily: FontFamily.medium, color: AppThemeData.danger300, maxLine: 1),
                    ),
                  ],
                ),
                if (report.description != null && report.description!.isNotEmpty) ...[
                  spaceH(height: 3),
                  TextCustom(title: report.description!, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 2),
                ],
                spaceH(height: 6),
                // Time + seller
                Row(
                  children: [
                    TextCustom(title: _timeAgo(report.createdAt), fontSize: 10, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                    if (report.sellerName != null) ...[
                      TextCustom(title: "  \u2022  ", fontSize: 10, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                      Expanded(
                        child: TextCustom(title: "${'Seller:'.tr} ${report.sellerName}", fontSize: 10, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5, maxLine: 1),
                      ),
                    ],
                  ],
                ),
                // Admin notes (if reviewed)
                if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                  spaceH(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextCustom(title: report.adminNotes!, fontSize: 11, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, maxLine: 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    Color color;
    String label;
    switch ((status ?? 'pending').toLowerCase()) {
      case 'reviewed':
        color = const Color(0xff4CAF50);
        label = 'Reviewed'.tr;
        break;
      case 'dismissed':
        color = const Color(0xff8E8E93);
        label = 'Dismissed'.tr;
        break;
      default:
        color = const Color(0xffFF9500);
        label = 'Pending'.tr;
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

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${'m ago'.tr}';
    if (diff.inHours < 24) return '${diff.inHours}${'h ago'.tr}';
    if (diff.inDays == 1) return 'Yesterday'.tr;
    if (diff.inDays < 7) return '${diff.inDays}${'d ago'.tr}';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
