import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:eSellify/app/widgets/file_viewer_dialog.dart';

import '../controllers/job_applications_controller.dart';

/// Applicant-facing list of jobs the logged-in user has applied to.
class JobApplicationsView extends GetView<JobApplicationsController> {
  const JobApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey2,
      appBar: UiInterface.customAppBar(context, themeChange, "Job Applications".tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.applications.isEmpty) {
          return _EmptyState(isDark: isDark);
        }
        return RefreshIndicator(
          onRefresh: controller.loadApplications,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.applications.length,
            itemBuilder: (context, index) => _ApplicationCard(application: controller.applications[index], isDark: isDark),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline_rounded, size: 64, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
          spaceH(height: 16),
          TextCustom(title: "No applications yet".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(title: "Jobs you apply to will appear here.".tr, fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final JobApplicationModel application;
  final bool isDark;

  const _ApplicationCard({required this.application, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextCustom(
                  title: application.adTitle ?? 'Job'.tr,
                  fontSize: 15,
                  fontFamily: FontFamily.semiBold,
                  maxLine: 2,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                ),
              ),
              spaceW(width: 8),
              JobApplicationStatusChip(status: application.status),
            ],
          ),
          spaceH(height: 8),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: AppThemeData.grey5),
              spaceW(width: 6),
              TextCustom(title: "${'Applied on'.tr} ${formatApplicationDate(application.createdAt)}", fontSize: 12, color: AppThemeData.grey5),
            ],
          ),
          if ((application.cvFileName ?? '').isNotEmpty) ...[
            spaceH(height: 12),
            GestureDetector(
              onTap: () => openCvUrl(application.cvUrl, fileName: application.cvFileName),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 16, color: AppThemeData.primary4),
                  spaceW(width: 6),
                  Flexible(
                    child: TextCustom(title: application.cvFileName!, fontSize: 13, fontFamily: FontFamily.medium, maxLine: 1, color: AppThemeData.primary4),
                  ),
                  spaceW(width: 4),
                  Icon(Icons.open_in_new_rounded, size: 14, color: AppThemeData.primary4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers (reused by the employer applicants screen) ───────────────

String formatApplicationDate(dynamic ts) {
  if (ts == null) return '';
  final dt = ts.toDate();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
}

Future<void> openCvUrl(String? url, {String? fileName}) async {
  if (url == null || url.isEmpty) {
    ShowToastDialog.showError("CV not available".tr);
    return;
  }
  // Open inside the app's file viewer instead of handing off to the external
  // browser, so the CV opens in-app like the other attachment views.
  await FileViewerDialog.open(url, title: (fileName ?? '').isNotEmpty ? fileName! : 'CV'.tr);
}

class JobApplicationStatusChip extends StatelessWidget {
  final String? status;

  const JobApplicationStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status ?? 'pending').toLowerCase();
    late Color color;
    late String label;
    switch (s) {
      case 'hired':
        color = const Color(0xff0F9D58);
        label = 'Hired'.tr;
        break;
      case 'shortlisted':
        color = AppThemeData.success300;
        label = 'Shortlisted'.tr;
        break;
      case 'rejected':
        color = AppThemeData.danger300;
        label = 'Rejected'.tr;
        break;
      case 'reviewed':
        color = AppThemeData.primary4;
        label = 'Reviewed'.tr;
        break;
      default:
        color = const Color(0xffF59E0B);
        label = 'Pending'.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: TextCustom(title: label, fontSize: 11, fontFamily: FontFamily.semiBold, color: color),
    );
  }
}
