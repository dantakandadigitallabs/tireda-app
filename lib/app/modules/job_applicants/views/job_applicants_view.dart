import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/app/modules/job_applications/views/job_applications_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/job_applicants_controller.dart';

/// Employer-facing list of applicants for one of their own job ads.
class JobApplicantsView extends GetView<JobApplicantsController> {
  const JobApplicantsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey2,
      appBar: UiInterface.customAppBar(context, themeChange, "Applicants".tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.applicants.isEmpty) {
          return _EmptyState(isDark: isDark);
        }
        final filtered = controller.filtered;
        return RefreshIndicator(
          onRefresh: controller.loadApplicants,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      title: "${controller.applicants.length} ${controller.applicants.length == 1 ? 'applicant'.tr : 'applicants'.tr} ${'for'.tr} \"${controller.adTitle ?? 'this job'.tr}\"",
                      fontSize: 13,
                      color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
                    ),
                    spaceH(height: 12),
                    // Filter chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(label: "All".tr, count: controller.applicants.length, selected: controller.filter.value == 'all', isDark: isDark, onTap: () => controller.setFilter('all')),
                        _FilterChip(label: "Shortlisted".tr, count: controller.countFor('shortlisted'), selected: controller.filter.value == 'shortlisted', isDark: isDark, onTap: () => controller.setFilter('shortlisted')),
                        _FilterChip(label: "Hired".tr, count: controller.countFor('hired'), selected: controller.filter.value == 'hired', isDark: isDark, onTap: () => controller.setFilter('hired')),
                        _FilterChip(label: "Pending".tr, count: controller.countFor('pending'), selected: controller.filter.value == 'pending', isDark: isDark, onTap: () => controller.setFilter('pending')),
                        _FilterChip(label: "Rejected".tr, count: controller.countFor('rejected'), selected: controller.filter.value == 'rejected', isDark: isDark, onTap: () => controller.setFilter('rejected')),
                      ],
                    ),
                    spaceH(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: TextCustom(title: "${'No'.tr} ${controller.filter.value} ${'applicants'.tr}", fontSize: 14, color: AppThemeData.grey5),
                        ),
                      ),
                  ],
                );
              }
              return _ApplicantCard(
                application: filtered[index - 1],
                isDark: isDark,
                onStatusChange: controller.updateStatus,
                onMessage: controller.messageApplicant,
              );
            },
          ),
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.count, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey3)),
        ),
        child: TextCustom(
          title: "$label ($count)",
          fontSize: 12.5,
          fontFamily: selected ? FontFamily.semiBold : FontFamily.regular,
          color: selected ? Colors.white : (isDark ? AppThemeData.grey3 : AppThemeData.grey7),
        ),
      ),
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
          Icon(Icons.people_outline_rounded, size: 64, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
          spaceH(height: 16),
          TextCustom(title: "No applicants yet".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(title: "Applications for this job will appear here.".tr, fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final JobApplicationModel application;
  final bool isDark;
  final Future<void> Function(JobApplicationModel, String) onStatusChange;
  final Future<void> Function(JobApplicationModel) onMessage;

  const _ApplicantCard({required this.application, required this.isDark, required this.onStatusChange, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextCustom(
                  title: application.applicantName ?? 'Applicant'.tr,
                  fontSize: 15,
                  fontFamily: FontFamily.semiBold,
                  maxLine: 1,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                ),
              ),
              spaceW(width: 8),
              JobApplicationStatusChip(status: application.status),
            ],
          ),
          spaceH(height: 4),
          TextCustom(title: "${'Applied on'.tr} ${formatApplicationDate(application.createdAt)}", fontSize: 12, color: AppThemeData.grey5),
          spaceH(height: 12),

          // Contact rows
          if ((application.applicantEmail ?? '').isNotEmpty)
            _ContactRow(icon: Icons.email_outlined, text: application.applicantEmail!, isDark: isDark, onTap: () => _launch("mailto:${application.applicantEmail}")),
          if ((application.applicantPhone ?? '').isNotEmpty)
            _ContactRow(
              icon: Icons.phone_outlined,
              text: "${application.countryCode ?? ''} ${application.applicantPhone}".trim(),
              isDark: isDark,
              onTap: () => _launch("tel:${application.countryCode ?? ''}${application.applicantPhone}"),
            ),

          // Cover note
          if ((application.coverNote ?? '').isNotEmpty) ...[
            spaceH(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
              child: TextCustom(title: application.coverNote!, fontSize: 13, maxLine: 10, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
            ),
          ],

          spaceH(height: 12),
          // View CV + Message
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => openCvUrl(application.cvUrl, fileName: application.cvFileName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppThemeData.primary4, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 16, color: AppThemeData.primary4),
                        spaceW(width: 6),
                        TextCustom(title: "View CV".tr, fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.primary4),
                      ],
                    ),
                  ),
                ),
              ),
              spaceW(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onMessage(application),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.primary4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Message".tr,
                          style: const TextStyle(fontSize: 13, fontFamily: FontFamily.semiBold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          spaceH(height: 10),
          // Shortlist / Reject actions
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: "Shortlist".tr,
                  color: AppThemeData.success300,
                  filled: application.status == 'shortlisted',
                  onTap: () => onStatusChange(application, 'shortlisted'),
                ),
              ),
              spaceW(width: 10),
              Expanded(
                child: _ActionButton(
                  label: "Reject".tr,
                  color: AppThemeData.danger300,
                  filled: application.status == 'rejected',
                  onTap: () => onStatusChange(application, 'rejected'),
                ),
              ),
            ],
          ),
          spaceH(height: 10),
          // Hire — final selection
          GestureDetector(
            onTap: () => onStatusChange(application, 'hired'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: application.status == 'hired' ? const Color(0xff0F9D58) : const Color(0xff0F9D58).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xff0F9D58), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    application.status == 'hired' ? Icons.check_circle_rounded : Icons.how_to_reg_outlined,
                    size: 16,
                    color: application.status == 'hired' ? Colors.white : const Color(0xff0F9D58),
                  ),
                  spaceW(width: 6),
                  TextCustom(
                    title: application.status == 'hired' ? "Hired".tr : "Mark as Hired".tr,
                    fontSize: 13,
                    fontFamily: FontFamily.semiBold,
                    color: application.status == 'hired' ? Colors.white : const Color(0xff0F9D58),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ShowToastDialog.showError("Could not open".tr);
    }
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactRow({required this.icon, required this.text, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppThemeData.primary4),
            spaceW(width: 8),
            Expanded(
              child: TextCustom(title: text, fontSize: 13, maxLine: 1, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Center(
          child: TextCustom(title: label, fontSize: 13, fontFamily: FontFamily.semiBold, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}
