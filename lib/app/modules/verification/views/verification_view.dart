import 'dart:io';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/verification_document_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/verification_controller.dart';

class VerificationView extends GetView<VerificationController> {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, isBack: true, "Verification".tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Constant.loader(context: context);
        }

        final status = controller.verificationStatus.value;

        if (status == 'approved') {
          return _buildApprovedView(isDark);
        } else if (status == 'pending' || status == 'resubmitted') {
          return _buildPendingView(isDark, status);
        } else if (status == 'rejected') {
          return _buildRejectedView(isDark);
        } else {
          return _buildNewSubmissionView(isDark);
        }
      }),
    );
  }

  // ─── Approved ─────────────────────────────────────────────────────
  Widget _buildApprovedView(bool isDark) {
    final reviewedAt = controller.verificationData.value?.reviewedAt;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          spaceH(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppThemeData.success300.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: SvgPicture.asset("assets/icons/ic_crown.svg", height: 36, colorFilter: ColorFilter.mode(AppThemeData.success300, BlendMode.srcIn))),
          ),
          spaceH(height: 20),
          TextCustom(title: "Account Verified".tr, fontSize: 22, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(
            title: "Your identity has been verified successfully. You now have a verified badge on your profile.".tr,
            fontSize: 14,
            color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
            textAlign: TextAlign.center,
            maxLine: 3,
          ),
          if (reviewedAt != null) ...[
            spaceH(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppThemeData.success300.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: TextCustom(title: '${"Verified on".tr} ${_formatTimestamp(reviewedAt)}', fontSize: 12, fontFamily: FontFamily.medium, color: AppThemeData.success300),
            ),
          ],
          spaceH(height: 32),
          // Show submitted documents
          if (controller.verificationData.value?.submittedDocuments != null && controller.verificationData.value!.submittedDocuments!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextCustom(title: "Your Documents".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
            ),
            spaceH(height: 12),
            ..._buildReadonlyDocuments(isDark),
          ],
        ],
      ),
    );
  }

  // ─── Pending / Resubmitted ────────────────────────────────────────
  Widget _buildPendingView(bool isDark, String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          spaceH(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: SvgPicture.asset("assets/icons/ic_bell_2.svg", height: 36, colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn))),
          ),
          spaceH(height: 20),
          TextCustom(title: "Under Review".tr, fontSize: 22, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(
            title: "Your documents have been submitted and are currently being reviewed by our team.".tr,
            fontSize: 14,
            color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
            textAlign: TextAlign.center,
            maxLine: 3,
          ),
          if (status == 'resubmitted') ...[
            spaceH(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: TextCustom(title: "Resubmitted".tr, fontSize: 12, fontFamily: FontFamily.medium, color: Colors.orange),
            ),
          ],
          spaceH(height: 32),
          // Submitted documents
          if (controller.verificationData.value?.submittedDocuments != null && controller.verificationData.value!.submittedDocuments!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextCustom(title: "Submitted Documents".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
            ),
            spaceH(height: 12),
            ..._buildReadonlyDocuments(isDark),
          ],
        ],
      ),
    );
  }

  // ─── Rejected ─────────────────────────────────────────────────────
  Widget _buildRejectedView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppThemeData.danger300.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppThemeData.danger300.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Center(child: SvgPicture.asset("assets/icons/ic_info.svg", height: 28, colorFilter: const ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn))),
                ),
                spaceH(height: 12),
                TextCustom(title: "Verification Rejected".tr, fontSize: 18, fontFamily: FontFamily.bold, color: AppThemeData.danger300, textAlign: TextAlign.center),
                if (controller.verificationData.value?.adminNotes != null && controller.verificationData.value!.adminNotes!.isNotEmpty) ...[
                  spaceH(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset("assets/icons/ic_info.svg", height: 16, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn)),
                        spaceW(width: 8),
                        Expanded(
                          child: TextCustom(title: controller.verificationData.value!.adminNotes!, fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
                        ),
                      ],
                    ),
                  ),
                ],
                spaceH(height: 8),
                TextCustom(title: "Please re-upload your documents below".tr, fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, textAlign: TextAlign.center),
              ],
            ),
          ),
          spaceH(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextCustom(title: "Upload Documents".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
          ),
          spaceH(height: 12),
          ..._buildDocumentForm(isDark),
          spaceH(height: 8),
          _buildSubmitButton(isDark, isRejected: true),
          spaceH(height: 16),
        ],
      ),
    );
  }

  // ─── New Submission ───────────────────────────────────────────────
  Widget _buildNewSubmissionView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppThemeData.primary4, AppThemeData.primary4.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppThemeData.primaryWhite.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Center(child: SvgPicture.asset("assets/icons/ic_crown.svg", height: 30, colorFilter: ColorFilter.mode(AppThemeData.primaryWhite, BlendMode.srcIn))),
                ),
                spaceH(height: 16),
                TextCustom(title: "Get Verified".tr, fontSize: 22, fontFamily: FontFamily.bold, color: AppThemeData.primaryWhite, textAlign: TextAlign.center),
                spaceH(height: 8),
                TextCustom(
                  title: "Verify your identity to build trust with other users and unlock the verified badge.".tr,
                  fontSize: 14,
                  color: AppThemeData.primaryWhite.withValues(alpha: 0.85),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          spaceH(height: 8),
          // Steps
          _buildStepRow(isDark, "1", "Upload Documents".tr, "Submit the required documents below".tr, "assets/icons/ic_order.svg"),
          _buildStepRow(isDark, "2", "Review Process".tr, "Our team will review your documents".tr, "assets/icons/ic_bell_2.svg"),
          _buildStepRow(isDark, "3", "Get Verified".tr, "Receive your verified badge".tr, "assets/icons/ic_crown.svg"),
          spaceH(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextCustom(title: "Required Documents".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
          ),
          spaceH(height: 12),
          ..._buildDocumentForm(isDark),
          spaceH(height: 8),
          _buildSubmitButton(isDark, isRejected: false),
          spaceH(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepRow(bool isDark, String number, String title, String subtitle, String svgPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: SvgPicture.asset(svgPath, height: 20, colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn))),
          ),
          spaceW(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(title: title, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                TextCustom(title: subtitle, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Readonly Documents ───────────────────────────────────────────
  List<Widget> _buildReadonlyDocuments(bool isDark) {
    final submitted = controller.verificationData.value?.submittedDocuments;
    if (submitted == null || submitted.isEmpty) return [];

    return submitted.map((doc) {
      IconData typeIcon;
      Color typeColor;
      switch (doc.type) {
        case 'image':
          typeIcon = Icons.image_outlined;
          typeColor = AppThemeData.primary4;
          break;
        case 'file':
          typeIcon = Icons.insert_drive_file_outlined;
          typeColor = Colors.orange;
          break;
        default:
          typeIcon = Icons.text_fields;
          typeColor = AppThemeData.success300;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 18, color: typeColor),
                spaceW(width: 8),
                Expanded(
                  child: TextCustom(title: doc.documentName ?? '', fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ),
              ],
            ),
            spaceH(height: 10),
            if (doc.type == 'textfield' && doc.value != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
                child: TextCustom(title: doc.value!, fontSize: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
              ),
            ],
            if (doc.type == 'image') ...[
              if (doc.frontImageUrl != null && doc.frontImageUrl!.isNotEmpty) ...[
                if (doc.backImageUrl != null && doc.backImageUrl!.isNotEmpty) TextCustom(title: 'Front'.tr, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                spaceH(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetworkImageWidget(imageUrl: doc.frontImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover, borderRadius: 10),
                ),
              ],
              if (doc.backImageUrl != null && doc.backImageUrl!.isNotEmpty) ...[
                spaceH(height: 8),
                TextCustom(title: "Back".tr, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                spaceH(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetworkImageWidget(imageUrl: doc.backImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover, borderRadius: 10),
                ),
              ],
            ],
            if (doc.type == 'file' && doc.fileUrl != null && doc.fileUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 24, color: Colors.red),
                    spaceW(width: 10),
                    Expanded(
                      child: TextCustom(title: "Document Uploaded".tr, fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
                    ),
                    Icon(Icons.check_circle, size: 18, color: AppThemeData.success300),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  // ─── Document Form ────────────────────────────────────────────────
  List<Widget> _buildDocumentForm(bool isDark) {
    return controller.verificationDocs.map((doc) {
      return _buildDocumentField(doc, controller, isDark);
    }).toList();
  }

  Widget _buildDocumentField(VerificationDocumentModel doc, VerificationController controller, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Icon(
                    doc.type == 'image'
                        ? Icons.image_outlined
                        : doc.type == 'file'
                        ? Icons.insert_drive_file_outlined
                        : Icons.text_fields,
                    size: 18,
                    color: AppThemeData.primary4,
                  ),
                ),
              ),
              spaceW(width: 10),
              Expanded(
                child: TextCustom(title: doc.nameFor(Get.locale?.languageCode), fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              ),
              if (doc.isRequired == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppThemeData.danger300.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: TextCustom(title: "Required".tr, fontSize: 10, fontFamily: FontFamily.medium, color: AppThemeData.danger300),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppThemeData.success300.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: TextCustom(title: "Optional".tr, fontSize: 10, fontFamily: FontFamily.medium, color: AppThemeData.success300),
                ),
            ],
          ),
          if (doc.descriptionFor(Get.locale?.languageCode).isNotEmpty) ...[
            spaceH(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: TextCustom(title: doc.descriptionFor(Get.locale?.languageCode), fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            ),
          ],
          spaceH(height: 14),
          if (doc.type == 'textfield') _buildTextFieldInput(doc, controller, isDark),
          if (doc.type == 'image') _buildImageInput(doc, controller, isDark),
          if (doc.type == 'file') _buildFileInput(doc, controller, isDark),
        ],
      ),
    );
  }

  Widget _buildTextFieldInput(VerificationDocumentModel doc, VerificationController controller, bool isDark) {
    return TextField(
      controller: controller.textControllers[doc.id],
      decoration: InputDecoration(
        hintText: '${'Enter'.tr} ${doc.nameFor(Get.locale?.languageCode).isNotEmpty ? doc.nameFor(Get.locale?.languageCode) : 'value'.tr}',
        hintStyle: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        filled: true,
        fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppThemeData.primary4, width: 1.5),
        ),
      ),
      style: TextStyle(color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, fontFamily: FontFamily.regular, fontSize: 14),
    );
  }

  Widget _buildImageInput(VerificationDocumentModel doc, VerificationController controller, bool isDark) {
    return Obx(
          () => Column(
        children: [
          _buildImagePicker(
            label: doc.imageSides == 'two' ? "Front Side".tr : "Upload Image".tr,
            hint: "PNG, JPG".tr,
            localPath: controller.frontImages[doc.id],
            existingUrl: _getExistingUrl(controller, doc.id!, 'frontImageUrl'),
            onTap: () => controller.pickFrontImage(doc.id!),
            isDark: isDark,
          ),
          if (doc.imageSides == 'two') ...[
            spaceH(height: 10),
            _buildImagePicker(
              label: "Back Side".tr,
              hint: "PNG, JPG".tr,
              localPath: controller.backImages[doc.id],
              existingUrl: _getExistingUrl(controller, doc.id!, 'backImageUrl'),
              onTap: () => controller.pickBackImage(doc.id!),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePicker({required String label, required String hint, String? localPath, String? existingUrl, required VoidCallback onTap, required bool isDark}) {
    final hasImage = (localPath != null && localPath.isNotEmpty) || (existingUrl != null && existingUrl.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: hasImage ? 140 : 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasImage ? AppThemeData.primary4.withValues(alpha: 0.3) : (isDark ? AppThemeData.grey8 : AppThemeData.grey3), width: hasImage ? 1.5 : 1),
        ),
        child: localPath != null && localPath.isNotEmpty
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(File(localPath), fit: BoxFit.cover, width: double.infinity, height: 140),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppThemeData.primaryBlack.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Icon(Icons.edit, size: 14, color: AppThemeData.primaryWhite),
              ),
            ),
          ],
        )
            : existingUrl != null && existingUrl.isNotEmpty
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: NetworkImageWidget(imageUrl: existingUrl, fit: BoxFit.cover, height: 140, width: double.infinity, borderRadius: 11),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppThemeData.primaryBlack.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Icon(Icons.edit, size: 14, color: AppThemeData.primaryWhite),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/icons/ic_camera.svg", height: 28, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn)),
            spaceH(height: 6),
            TextCustom(title: label, fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
            spaceH(height: 2),
            TextCustom(title: hint, fontSize: 11, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInput(VerificationDocumentModel doc, VerificationController controller, bool isDark) {
    return Obx(() {
      final fileName = controller.selectedFileNames[doc.id];
      final hasFile = controller.selectedFiles[doc.id] != null;
      final existingUrl = _getExistingUrl(controller, doc.id!, 'fileUrl');
      final hasExisting = existingUrl != null && existingUrl.isNotEmpty;

      return GestureDetector(
        onTap: () => controller.pickFile(doc.id!),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (hasFile || hasExisting) ? AppThemeData.primary4.withValues(alpha: 0.3) : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
              width: (hasFile || hasExisting) ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (hasFile || hasExisting) ? AppThemeData.primary4.withValues(alpha: 0.1) : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    hasFile
                        ? Icons.insert_drive_file
                        : hasExisting
                        ? Icons.check_circle
                        : Icons.upload_file_outlined,
                    size: 22,
                    color: (hasFile || hasExisting) ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  ),
                ),
              ),
              spaceW(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      title: hasFile
                          ? (fileName ?? "File selected".tr)
                          : hasExisting
                          ? "File uploaded".tr
                          : "Tap to upload".tr,
                      fontSize: 14,
                      fontFamily: FontFamily.medium,
                      color: (hasFile || hasExisting) ? (isDark ? AppThemeData.grey1 : AppThemeData.grey10) : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ),
                    TextCustom(title: "PDF, DOC, DOCX".tr, fontSize: 11, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                  ],
                ),
              ),
              if (hasFile || hasExisting)
                Icon(Icons.check_circle, size: 20, color: AppThemeData.success300)
              else
                SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 16, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubmitButton(bool isDark, {required bool isRejected}) {
    return Obx(
          () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: controller.isSubmitting.value ? null : () => controller.submitVerification(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeData.primary4,
            disabledBackgroundColor: AppThemeData.primary4.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : TextCustom(title: isRejected ? "Resubmit Documents".tr : "Submit for Verification".tr, fontSize: 16, fontFamily: FontFamily.bold, color: AppThemeData.primaryWhite),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  String? _getExistingUrl(VerificationController controller, String documentId, String field) {
    if (controller.verificationData.value?.submittedDocuments == null) return null;
    final doc = controller.verificationData.value!.submittedDocuments!.where((d) => d.documentId == documentId).firstOrNull;
    if (doc == null) return null;
    switch (field) {
      case 'frontImageUrl':
        return doc.frontImageUrl;
      case 'backImageUrl':
        return doc.backImageUrl;
      case 'fileUrl':
        return doc.fileUrl;
      default:
        return null;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute $period';
  }
}
