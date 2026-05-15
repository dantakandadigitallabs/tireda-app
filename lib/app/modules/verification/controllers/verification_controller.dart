import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/verification_document_model.dart';
import 'package:eSellify/app/models/verification_request_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/notifications/send_notification.dart';

class VerificationController extends GetxController {
  var verificationDocs = <VerificationDocumentModel>[].obs;
  var isLoading = true.obs;
  var isSubmitting = false.obs;
  final ImagePicker imagePicker = ImagePicker();

  // Current user's verification data from their customer document
  Rx<VerificationData?> verificationData = Rx<VerificationData?>(null);
  RxString verificationStatus = 'unverified'.obs;

  // Form data keyed by document template ID
  var textControllers = <String, TextEditingController>{}.obs;
  var frontImages = <String, String>{}.obs;
  var backImages = <String, String>{}.obs;
  var selectedFiles = <String, String>{}.obs;
  var selectedFileNames = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  @override
  void onClose() {
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> getData() async {
    try {
      isLoading.value = true;

      // Fetch active verification document templates
      verificationDocs.value = await FireStoreUtils.getActiveVerificationDocuments();

      // Read verification data from current user model
      final currentUid = FireStoreUtils.getCurrentUid();
      if (currentUid != null) {
        final userDoc = await FireStoreUtils.getUserProfile(currentUid);
        if (userDoc != null) {
          verificationStatus.value = userDoc.verificationStatus ?? 'unverified';
          verificationData.value = userDoc.verificationData;
          // Also update global user model
          Constant.userModel?.verificationStatus = userDoc.verificationStatus;
          Constant.userModel?.isVerified = userDoc.isVerified;
          Constant.userModel?.verificationData = userDoc.verificationData;
        }
      }

      // Initialize form controllers
      _initFormControllers();

      // If rejected, pre-populate form values
      if (verificationStatus.value == 'rejected') {
        _prePopulateFormValues();
      }
    } catch (e, stack) {
      developer.log('Error fetching verification data: ', error: e, stackTrace: stack);
    } finally {
      isLoading.value = false;
    }
  }

  void _initFormControllers() {
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    textControllers.clear();
    frontImages.clear();
    backImages.clear();
    selectedFiles.clear();
    selectedFileNames.clear();

    for (var doc in verificationDocs) {
      if (doc.id != null && doc.type == 'textfield') {
        textControllers[doc.id!] = TextEditingController();
      }
    }
  }

  void _prePopulateFormValues() {
    if (verificationData.value?.submittedDocuments == null) return;

    for (var submitted in verificationData.value!.submittedDocuments!) {
      if (submitted.documentId == null) continue;
      final docId = submitted.documentId!;

      if (submitted.type == 'textfield' && submitted.value != null && textControllers.containsKey(docId)) {
        textControllers[docId]!.text = submitted.value!;
      }
    }
  }

  Future<void> pickFrontImage(String documentId) async {
    try {
      final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        frontImages[documentId] = image.path;
      }
    } catch (e) {
      developer.log('Error picking front image: $e');
    }
  }

  Future<void> pickBackImage(String documentId) async {
    try {
      final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        backImages[documentId] = image.path;
      }
    } catch (e) {
      developer.log('Error picking back image: $e');
    }
  }

  Future<void> pickFile(String documentId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        selectedFiles[documentId] = result.files.single.path!;
        selectedFileNames[documentId] = result.files.single.name;
      }
    } catch (e) {
      developer.log('Error picking file: $e');
    }
  }

  bool _validateForm() {
    for (var doc in verificationDocs) {
      if (doc.isRequired != true || doc.id == null) continue;

      final docId = doc.id!;

      switch (doc.type) {
        case 'textfield':
          final controller = textControllers[docId];
          if (controller == null || controller.text.trim().isEmpty) {
            ShowToastDialog.showError('${doc.name ?? 'Field'} is required'.tr);
            return false;
          }
          break;

        case 'image':
          final hasFront = (frontImages[docId] != null && frontImages[docId]!.isNotEmpty) ||
              _hasExistingValue(docId, 'frontImageUrl');
          if (!hasFront) {
            ShowToastDialog.showError('Please upload ${doc.name ?? 'image'}'.tr);
            return false;
          }
          if (doc.imageSides == 'two') {
            final hasBack = (backImages[docId] != null && backImages[docId]!.isNotEmpty) ||
                _hasExistingValue(docId, 'backImageUrl');
            if (!hasBack) {
              ShowToastDialog.showError('Please upload back side of ${doc.name ?? 'image'}'.tr);
              return false;
            }
          }
          break;

        case 'file':
          final hasFile = (selectedFiles[docId] != null && selectedFiles[docId]!.isNotEmpty) ||
              _hasExistingValue(docId, 'fileUrl');
          if (!hasFile) {
            ShowToastDialog.showError('Please upload ${doc.name ?? 'file'}'.tr);
            return false;
          }
          break;
      }
    }
    return true;
  }

  bool _hasExistingValue(String documentId, String field) {
    if (verificationData.value?.submittedDocuments == null) return false;
    final doc = verificationData.value!.submittedDocuments!
        .where((d) => d.documentId == documentId)
        .firstOrNull;
    if (doc == null) return false;

    switch (field) {
      case 'frontImageUrl':
        return doc.frontImageUrl != null && doc.frontImageUrl!.isNotEmpty;
      case 'backImageUrl':
        return doc.backImageUrl != null && doc.backImageUrl!.isNotEmpty;
      case 'fileUrl':
        return doc.fileUrl != null && doc.fileUrl!.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> submitVerification() async {
    if (!_validateForm()) return;

    try {
      isSubmitting.value = true;
      ShowToastDialog.showLoader("Submitting...".tr);

      final userId = FireStoreUtils.getCurrentUid();
      if (userId == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showError('User not authenticated'.tr);
        isSubmitting.value = false;
        return;
      }

      final bool isResubmission = verificationStatus.value == 'rejected';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      List<SubmittedDocument> submittedDocuments = [];

      for (var doc in verificationDocs) {
        if (doc.id == null) continue;
        final docId = doc.id!;

        SubmittedDocument submitted = SubmittedDocument(
          documentId: docId,
          documentName: doc.name,
          type: doc.type,
        );

        switch (doc.type) {
          case 'textfield':
            submitted.value = textControllers[docId]?.text.trim() ?? '';
            break;

          case 'image':
            if (frontImages[docId] != null && frontImages[docId]!.isNotEmpty) {
              submitted.frontImageUrl = await Constant.uploadImageToFireStorage(
                File(frontImages[docId]!),
                'verification/$userId/$docId',
                'front_$timestamp.jpg',
              );
            } else if (isResubmission && _hasExistingValue(docId, 'frontImageUrl')) {
              submitted.frontImageUrl = _getExistingUrlValue(docId, 'frontImageUrl');
            }

            if (backImages[docId] != null && backImages[docId]!.isNotEmpty) {
              submitted.backImageUrl = await Constant.uploadImageToFireStorage(
                File(backImages[docId]!),
                'verification/$userId/$docId',
                'back_$timestamp.jpg',
              );
            } else if (isResubmission && _hasExistingValue(docId, 'backImageUrl')) {
              submitted.backImageUrl = _getExistingUrlValue(docId, 'backImageUrl');
            }
            break;

          case 'file':
            if (selectedFiles[docId] != null && selectedFiles[docId]!.isNotEmpty) {
              final fileName = selectedFileNames[docId] ?? 'file_$timestamp';
              submitted.fileUrl = await Constant.uploadImageToFireStorage(
                File(selectedFiles[docId]!),
                'verification/$userId/$docId',
                fileName,
              );
            } else if (isResubmission && _hasExistingValue(docId, 'fileUrl')) {
              submitted.fileUrl = _getExistingUrlValue(docId, 'fileUrl');
            }
            break;
        }

        submittedDocuments.add(submitted);
      }

      final String newStatus = isResubmission ? 'resubmitted' : 'pending';

      final vData = VerificationData(
        submittedAt: isResubmission ? (verificationData.value?.submittedAt ?? Timestamp.now()) : Timestamp.now(),
        submittedDocuments: submittedDocuments,
      );

      // Save to customers collection via FireStoreUtils
      await FireStoreUtils.submitVerificationData(userId, newStatus, vData.toJson());

      // Update local user model
      Constant.userModel?.verificationStatus = newStatus;
      Constant.userModel?.verificationData = vData;

      // Notify admin
      SendNotification.sendToTopic(
        topic: 'esellify-admin',
        title: isResubmission ? 'Verification Resubmitted' : 'Verification Request',
        body: '${Constant.userModel?.fullNameString() ?? "A user"} submitted verification documents',
        payload: {'type': 'verification_request'},
      );

      ShowToastDialog.closeLoader();
      ShowToastDialog.showSuccess(isResubmission
          ? 'Documents resubmitted successfully'.tr
          : 'Verification submitted successfully'.tr);

      isSubmitting.value = false;
      await getData();
    } catch (e, stack) {
      developer.log('Error submitting verification: ', error: e, stackTrace: stack);
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError('Failed to submit verification. Please try again.'.tr);
      isSubmitting.value = false;
    }
  }

  String? _getExistingUrlValue(String documentId, String field) {
    if (verificationData.value?.submittedDocuments == null) return null;
    final doc = verificationData.value!.submittedDocuments!
        .where((d) => d.documentId == documentId)
        .firstOrNull;
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
}
