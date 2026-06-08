import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/models/chat_message_model.dart';
import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/app/modules/chats/views/chat_detail_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eSellify/app/constant/show_toast.dart';

class AdListingDetailController extends ChangeNotifier {
  late AdModel ad;
  RxBool isLiked = false.obs;
  RxInt likeCount = 0.obs;
  RxInt viewCount = 0.obs;

  // Report state
  RxBool hasReported = false.obs;
  Rx<AdReportModel?> existingReport = Rx<AdReportModel?>(null);

  // Seller verification + rating
  RxBool isSellerVerified = false.obs;
  RxDouble sellerRating = 0.0.obs;
  RxInt sellerReviewCount = 0.obs;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  /// Called by the StatefulWidget's initState to load the ad.
  /// Replaces the old onInit/Get.arguments pattern so each page instance
  /// owns its own controller with no GetX registry dependency.
  void initWithAd(AdModel adModel) {
    ad = adModel;
    likeCount.value = ad.likes ?? 0;
    viewCount.value = ad.views ?? 0;
    _checkLiked();
    _incrementViews();
    _checkReportStatus();
    _checkSellerVerification();
  }

  /// Called by the StatefulWidget's dispose to clean up any resources.
  void disposeController() {
    // RxBool/RxInt/etc. manage their own cleanup via GetX.
    // Nothing additional to dispose here for now.
  }

  Future<void> _checkSellerVerification() async {
    if (ad.sellerId == null) return;
    final seller = await FireStoreUtils.getUserProfile(ad.sellerId!);
    if (seller != null && seller.isVerified == true && seller.verificationStatus == "approved") {
      isSellerVerified.value = true;
    }
    // Fetch seller rating
    final ratingData = await FireStoreUtils.getSellerRating(ad.sellerId!);
    sellerRating.value = ratingData['average'] as double;
    sellerReviewCount.value = ratingData['count'] as int;
  }

  Future<void> _checkReportStatus() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null || ad.id == null) return;
    final reports = await FireStoreUtils.getMyReports(uid);
    final match = reports.where((r) => r.adId == ad.id).toList();
    if (match.isNotEmpty) {
      hasReported.value = true;
      existingReport.value = match.first;
    }
  }

  void onReportSubmitted(AdReportModel report) {
    hasReported.value = true;
    existingReport.value = report;
  }

  void _checkLiked() {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid != null) {
      isLiked.value = FireStoreUtils.isAdLikedByUser(ad, uid);
    }
  }

  Future<void> _incrementViews() async {
    if (ad.id != null) {
      await FireStoreUtils.incrementAdViews(ad.id!);
      // Fetch accurate count from subcollection
      final count = await FireStoreUtils.getAdViewerCount(ad.id!);
      viewCount.value = count;
    }
  }

  Future<void> toggleLike() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return;

    final liked = await FireStoreUtils.toggleLike(ad.id!, uid);
    isLiked.value = liked;
    likeCount.value += liked ? 1 : -1;

    if (liked) {
      ad.likedUser ??= [];
      ad.likedUser!.add(uid);
    } else {
      ad.likedUser?.remove(uid);
    }
    ad.likes = likeCount.value;
  }

  void shareAd() {
    if (ad.id == null || ad.id!.isEmpty) {
      ShowToastDialog.showError("Unable to share this ad".tr);
      return;
    }
    final appName = Constant.appName.value;
    final android = Constant.androidAppUrl.value.trim();
    final ios = Constant.iosAppUrl.value.trim();
    final lines = <String>[
      if ((ad.title ?? '').isNotEmpty) ad.title!,
      _formatPrice(),
      '',
      'Check it out on $appName:',
      if (android.isNotEmpty) 'Android: $android',
      if (ios.isNotEmpty) 'iOS: $ios',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ShowToastDialog.showSuccess("Ad link copied to clipboard!".tr);
  }

  String _formatPrice() {
    // Keeps the crucial v1.3 job application integration line
    if (ad.isJobAd) return ad.formattedSalary();

    // Standard product pricing fallback logic
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final c = ad.currency;
    final s = c?.symbol ?? '';
    final d = c?.decimalDigits ?? 0;
    final p = ad.price!.toStringAsFixed(d);
    return c?.symbolAtRight == true ? "$p $s".trim() : "$s$p".trim();
  }

  // ─── Chat Methods ─────────────────────────────────────────

  Future<void> openChat() async {
    if (FireStoreUtils.getCurrentUid() == null) {
      ShowToastDialog.showError("Please login to chat with the seller".tr);
      return;
    }
    if (ad.sellerId == FireStoreUtils.getCurrentUid()) {
      ShowToastDialog.showWarning("This is your own ad".tr);
      return;
    }

    // Check if ad is sold out
    if (ad.status == 'sold') {
      ShowToastDialog.showError("This ad has been sold out".tr);
      return;
    }

    // Check if ad is still active
    if (ad.status != 'active' || ad.isActive != true) {
      ShowToastDialog.showError("This ad is no longer active".tr);
      return;
    }

    // Check if seller is blocked
    final blockedUsers = await FireStoreUtils.getBlockedUsers(FireStoreUtils.getCurrentUid()!);
    if (blockedUsers.contains(ad.sellerId)) {
      ShowToastDialog.showError("You have blocked this user. Unblock them to start a chat.".tr);
      return;
    }

    ShowToastDialog.showLoader("Opening chat...".tr);
    final chatRoom = await FireStoreUtils.getOrCreateChatRoom(ad: ad, currentUser: Constant.userModel!);
    ShowToastDialog.closeLoader();

    Get.to(() => ChatDetailView(chatRoom: chatRoom));
  }

  Future<void> sendOffer(double amount) async {
    if (FireStoreUtils.getCurrentUid() == null) {
      ShowToastDialog.showError("Please login to make an offer".tr);
      return;
    }
    if (ad.sellerId == FireStoreUtils.getCurrentUid()) {
      ShowToastDialog.showWarning("This is your own ad".tr);
      return;
    }

    // Check if ad is sold out
    if (ad.status == 'sold') {
      ShowToastDialog.showError("This ad has been sold out".tr);
      return;
    }

    // Check if ad is still active
    if (ad.status != 'active' || ad.isActive != true) {
      ShowToastDialog.showError("This ad is no longer active".tr);
      return;
    }

    // Check if seller is blocked
    final blockedUsers = await FireStoreUtils.getBlockedUsers(FireStoreUtils.getCurrentUid()!);
    if (blockedUsers.contains(ad.sellerId)) {
      ShowToastDialog.showError("You have blocked this user. Unblock them to send an offer.".tr);
      return;
    }

    ShowToastDialog.showLoader("Sending offer...".tr);
    final chatRoom = await FireStoreUtils.getOrCreateChatRoom(ad: ad, currentUser: Constant.userModel!);

    final msgId = Constant.getUuid();
    final message = ChatMessageModel(
      id: msgId,
      chatRoomId: chatRoom.id,
      senderId: FireStoreUtils.getCurrentUid(),
      senderName: Constant.userModel?.fullNameString() ?? '',
      senderProfile: Constant.userModel?.profilePic ?? '',
      messageType: 'offer',
      text: 'Made an offer',
      offerAmount: amount,
      offerStatus: 'pending',
      createdAt: Timestamp.now(),
      isRead: false,
    );

    final success = await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: chatRoom.otherUserId(FireStoreUtils.getCurrentUid()!));
    ShowToastDialog.closeLoader();

    if (success) {
      ShowToastDialog.showSuccess("Offer sent successfully!".tr);
      Get.to(() => ChatDetailView(chatRoom: chatRoom));
    } else {
      ShowToastDialog.showError("Failed to send offer".tr);
    }
  }

  // ─── Job Portal Feature Sets (v1.3) ───────────────────────────────────

  /// Lightweight precheck used before showing the apply form, so we can warn
  /// the user about login / own-ad / inactive / already-applied up front.
  /// Returns true when it's OK to open the application form.
  Future<bool> canApplyForJob() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      ShowToastDialog.showError("Please login to apply for this job".tr);
      return false;
    }
    if (ad.sellerId == uid) {
      ShowToastDialog.showWarning("This is your own job posting".tr);
      return false;
    }
    if (ad.status != 'active' || ad.isActive != true) {
      ShowToastDialog.showError("This job is no longer active".tr);
      return false;
    }
    final alreadyApplied = await FireStoreUtils.hasAppliedToJob(adId: ad.id!, applicantId: uid);
    if (alreadyApplied) {
      ShowToastDialog.showWarning("You have already applied to this job".tr);
      return false;
    }
    return true;
  }

  /// Job Category application: uploads the applicant's CV and stores a job
  /// application record (separate from chat). Used by the "Apply Now" flow.
  Future<void> submitJobApplication({
    required File cvFile,
    required String cvFileName,
    required String fullName,
    required String email,
    required String coverNote,
    required String phone,
    required String countryCode,
  }) async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      ShowToastDialog.showError("Please login to apply for this job".tr);
      return;
    }

    // Re-validate at submit time (state may have changed while the form was open).
    if (ad.status != 'active' || ad.isActive != true) {
      ShowToastDialog.showError("This job is no longer active".tr);
      return;
    }
    if (await FireStoreUtils.hasAppliedToJob(adId: ad.id!, applicantId: uid)) {
      ShowToastDialog.showWarning("You have already applied to this job".tr);
      return;
    }

    ShowToastDialog.showLoader("Submitting application...".tr);
    try {
      final applicationId = Constant.getUuid();

      // Upload CV to storage (putFile works for PDF/doc/images alike).
      final cvUrl = await Constant.uploadImageToFireStorage(cvFile, 'job_applications/${ad.id}', '${uid}_$cvFileName');

      final application = JobApplicationModel(
        id: applicationId,
        adId: ad.id,
        adTitle: ad.title,
        employerId: ad.sellerId,
        applicantId: uid,
        applicantName: fullName.trim(),
        applicantEmail: email.trim(),
        applicantPhone: phone.trim(),
        countryCode: countryCode,
        coverNote: coverNote.trim(),
        cvUrl: cvUrl,
        cvFileName: cvFileName,
        status: 'pending',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      final success = await FireStoreUtils.saveJobApplication(application);
      ShowToastDialog.closeLoader();

      if (success) {
        Get.back(); // close the apply sheet
        ShowToastDialog.showSuccess("Application submitted successfully!".tr);
      } else {
        ShowToastDialog.showError("Failed to submit application. Please try again.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Something went wrong. Please try again.".tr);
    }
  }

  // ─── Ported Helpers (v1.2) ────────────────────────────────────────────

  /// Refresh controller with new ad data when navigating from seller profile,
  /// favourites, search, or any screen where the goToAdDetail helper is used.
  void refreshWithAd(AdModel newAd) {
    ad = newAd;

    // Reset all observable state
    likeCount.value = newAd.likes ?? 0;
    viewCount.value = newAd.views ?? 0;
    isLiked.value = false;
    hasReported.value = false;
    existingReport.value = null;
    isSellerVerified.value = false;
    sellerRating.value = 0.0;
    sellerReviewCount.value = 0;

    // Reset similar ads state so they are re-fetched for the new ad
    similarAds.clear();
    isSimilarAdsLoading.value = false;
    _similarAdsFetched = false;

    // Re-initialize all data fetching
    _checkLiked();
    _incrementViews();
    _checkReportStatus();
    _checkSellerVerification();

    // Notify AnimatedBuilder in the view to rebuild
    notifyListeners();
  }

  // ─── Similar Ads ───────────────────────────────────────────────────────────

  RxList<AdModel> similarAds = <AdModel>[].obs;
  RxBool isSimilarAdsLoading = false.obs;
  bool _similarAdsFetched = false;

  /// Called lazily from the view when the Similar Ads section first becomes
  /// visible. Tries subcategory (leaf) first; falls back to parent category
  /// if fewer than 4 results are returned. Excludes the current ad. Limit: 12.
  Future<void> fetchSimilarAds() async {
    if (_similarAdsFetched) return;
    _similarAdsFetched = true;

    final leafId = ad.leafCategoryId;
    final parentId = ad.parentCategoryId;

    if (leafId == null && parentId == null) return;

    isSimilarAdsLoading.value = true;
    try {
      List<AdModel> results = [];

      // Step 1: try subcategory (leaf) first
      if (leafId != null) {
        results = await FireStoreUtils.getSimilarAds(
          categoryId: leafId,
          excludeAdId: ad.id!,
          limit: 16,
        );
      }

      // Step 2: fall back to parent category if too few results
      if (results.length < 4 && parentId != null && parentId != leafId) {
        results = await FireStoreUtils.getSimilarAds(
          categoryId: parentId,
          excludeAdId: ad.id!,
          limit: 16,
        );
      }

      similarAds.assignAll(results);
    } catch (_) {
      // Silently fail — similar ads are non-critical
    } finally {
      isSimilarAdsLoading.value = false;
    }
  }
}